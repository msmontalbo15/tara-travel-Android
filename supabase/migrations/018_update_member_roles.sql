-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 018: FIX trip_members TRIGGER & ROLE ASSIGNMENT RPC
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Instructions: Run this entire script in your Supabase Dashboard -> SQL Editor -> New Query -> Run.
--
-- Root Cause Fixed:
--   1. PostgreSQL error 42703 (record "new" has no field "updated_at"):
--      A legacy trigger `set_trip_members_updated_at` called `set_updated_at()`
--      on `trip_members`, but `trip_members` lacked the `updated_at` column.
--      This caused all UPDATEs on `trip_members` to fail.
--   2. Added `updated_at` column and safely dropped/recreated the trigger.
--   3. Created `update_member_roles()` SECURITY DEFINER RPC.
--   4. Extended `trip_members_update` RLS policy for organizers.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Fix trip_members updated_at & Broken Trigger ──────────────────────────
-- Drop the trigger that caused error 42703
drop trigger if exists set_trip_members_updated_at on public.trip_members;
drop trigger if exists set_updated_at on public.trip_members;

-- Ensure updated_at column exists on trip_members
alter table public.trip_members
  add column if not exists updated_at timestamptz not null default now();

-- Recreate trigger cleanly
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger set_trip_members_updated_at
  before update on public.trip_members
  for each row execute procedure public.set_updated_at();

-- ── 2. Helper: is the caller an owner or approved organizer? ──────────────────
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

-- ── 3. RPC: update_member_roles ──────────────────────────────────────────────
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
  v_caller_id      uuid   := auth.uid();
  v_target_user_id uuid;
  v_trip_name      text;
  v_member_name    text;
  v_role_labels    text;
  v_safe_roles     text[];
begin
  if v_caller_id is null then
    raise exception 'Not authenticated.';
  end if;

  if not public.user_is_trip_organizer(p_trip_id) then
    raise exception 'Only organizers can assign roles.';
  end if;

  v_safe_roles := case
    when p_roles is null or array_length(p_roles, 1) is null then array['member']
    else p_roles
  end;

  if exists (
    select 1
    from unnest(v_safe_roles) as r
    where r not in ('organizer','treasurer','navigator','buyer','documenter','member')
  ) then
    raise exception 'Unknown role value detected. Allowed: organizer, treasurer, navigator, buyer, documenter, member.';
  end if;

  -- Update trip_members (matches by user_id or row id)
  update public.trip_members
     set roles      = v_safe_roles,
         updated_at = now()
   where trip_id = p_trip_id
     and (user_id = p_member_uid or id = p_member_uid)
   returning user_id into v_target_user_id;

  if not found or v_target_user_id is null then
    raise exception 'Member record not found for this trip.';
  end if;

  -- Resolve display strings
  select name into v_trip_name from public.trips where id = p_trip_id;
  select coalesce(display_name, full_name, email, 'Member')
    into v_member_name
    from public.users
   where id = v_target_user_id;

  v_role_labels := array_to_string(v_safe_roles, ', ');

  -- Notify the affected member if not self-editing (best-effort)
  if v_target_user_id != v_caller_id then
    begin
      insert into public.notifications (user_id, trip_id, type, title, body, data)
      values (
        v_target_user_id,
        p_trip_id,
        'role_updated',
        '🏷️ Your Role Was Updated',
        'Your role in "' || coalesce(v_trip_name, 'the trip') || '" has been changed to: ' || v_role_labels,
        jsonb_build_object('trip_id', p_trip_id, 'roles', v_safe_roles)
      );
    exception when others then
      null;
    end;
  end if;

  -- Log activity (best-effort)
  begin
    insert into public.activity_log (trip_id, user_id, action_type, description)
    values (
      p_trip_id,
      v_caller_id,
      'member_role_changed',
      coalesce(v_member_name, 'Member') || '''s roles updated to: ' || v_role_labels
    );
  exception when others then
    null;
  end;

  return jsonb_build_object(
    'success',    true,
    'trip_id',    p_trip_id,
    'member_uid', v_target_user_id,
    'roles',      v_safe_roles
  );
end;
$$;

grant execute on function public.update_member_roles(uuid, uuid, text[]) to authenticated;

-- ── 4. Extend trip_members UPDATE policy ─────────────────────────────────────
drop policy if exists "trip_members_update" on public.trip_members;

create policy "trip_members_update"
  on public.trip_members
  for update
  using (
    auth.uid() = user_id
    or public.user_owns_trip(trip_id)
    or public.user_is_trip_organizer(trip_id)
  );
