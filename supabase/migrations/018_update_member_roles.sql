-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 018: SECURE ROLE ASSIGNMENT RPC
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Problem: updateMemberRoles() issued a direct client-side UPDATE on
-- trip_members. The existing RLS policy (auth.uid() = user_id OR
-- user_owns_trip(trip_id)) blocked non-owner organizers and caused silent
-- 0-row updates — the client saw "success" but no DB row was mutated.
--
-- Fix:
--   1. Add user_is_trip_organizer() SECURITY DEFINER helper.
--   2. Promote updateMemberRoles to a SECURITY DEFINER RPC that:
--        · Enforces organizer/owner caller check.
--        · Writes the canonical DB update.
--        · Emits an in-app notification to the affected member.
--        · Appends an activity log entry.
--   3. Extend trip_members_update RLS so non-owner organizers can
--      update roles via direct client calls as well.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Helper: is the current user an approved organizer for this trip? ──────────
-- Checks trip ownership OR approved 'organizer' role in trip_members.
-- SECURITY DEFINER prevents RLS recursion.
create or replace function public.user_is_trip_organizer(p_trip_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.trips
    where id = p_trip_id
      and owner_id = auth.uid()
  )
  or exists (
    select 1 from public.trip_members
    where trip_id = p_trip_id
      and user_id  = auth.uid()
      and status   = 'approved'
      and 'organizer' = any(roles)
  );
$$;

grant execute on function public.user_is_trip_organizer(uuid) to authenticated;

-- ── RPC: update_member_roles ──────────────────────────────────────────────────
-- Replaces the fragile client-side UPDATE that was blocked by RLS for
-- non-owner organizers. Called from TripRepository.updateMemberRoles().
create or replace function public.update_member_roles(
  p_trip_id    uuid,
  p_member_uid uuid,
  p_roles      text[]          -- e.g. ARRAY['organizer','treasurer']
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_id   uuid   := auth.uid();
  v_trip_name   text;
  v_member_name text;
  v_role_labels text;
  v_safe_roles  text[];
begin
  -- Caller must be trip owner or approved organizer
  if not public.user_is_trip_organizer(p_trip_id) then
    raise exception 'Only organizers can assign roles.';
  end if;

  -- Default to ['member'] when the caller passes an empty array
  v_safe_roles := case
    when p_roles is null or array_length(p_roles, 1) is null then array['member']
    else p_roles
  end;

  -- Validate every role string against the known enum values
  if exists (
    select 1
    from unnest(v_safe_roles) as r
    where r not in ('organizer','treasurer','navigator','buyer','documenter','member')
  ) then
    raise exception 'Unknown role value detected. Allowed: organizer, treasurer, navigator, buyer, documenter, member.';
  end if;

  -- Perform the update
  update public.trip_members
     set roles = v_safe_roles
   where trip_id = p_trip_id
     and user_id  = p_member_uid;

  if not found then
    raise exception 'Member record not found for this trip.';
  end if;

  -- Resolve display strings for notification/activity log
  select name into v_trip_name   from public.trips where id = p_trip_id;
  select coalesce(display_name, full_name, email, 'Member')
    into v_member_name
    from public.users where id = p_member_uid;

  v_role_labels := array_to_string(v_safe_roles, ', ');

  -- Notify the affected member (best-effort — never fail the main update)
  begin
    insert into public.notifications (user_id, trip_id, type, title, body, data)
    values (
      p_member_uid,
      p_trip_id,
      'role_updated',
      '🏷️ Your Role Was Updated',
      'Your role in "' || v_trip_name || '" has been changed to: ' || v_role_labels,
      jsonb_build_object('trip_id', p_trip_id, 'roles', v_safe_roles)
    );
  exception when others then
    -- Non-fatal: proceed even if notification insert fails
    null;
  end;

  -- Activity log entry (best-effort)
  begin
    insert into public.activity_log (trip_id, user_id, action_type, description)
    values (
      p_trip_id,
      v_caller_id,
      'member_role_changed',
      v_member_name || '''s roles updated to: ' || v_role_labels
    );
  exception when others then
    null;
  end;

  return jsonb_build_object(
    'success',      true,
    'trip_id',      p_trip_id,
    'member_uid',   p_member_uid,
    'roles',        v_safe_roles
  );
end;
$$;

grant execute on function public.update_member_roles(uuid, uuid, text[]) to authenticated;

-- ── Extend trip_members UPDATE policy ─────────────────────────────────────────
-- Previous policy: auth.uid() = user_id OR user_owns_trip(trip_id)
-- Extended policy: additionally allow approved organizers to update any row.
-- Drops and recreates the policy to avoid duplicate-policy errors.
drop policy if exists "trip_members_update" on public.trip_members;

create policy "trip_members_update"
  on public.trip_members
  for update
  using (
    auth.uid() = user_id
    or public.user_owns_trip(trip_id)
    or public.user_is_trip_organizer(trip_id)
  );
