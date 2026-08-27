-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 019: FIX JOIN TRIP BY CODE & REMOVE NON-EXISTENT full_name
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Instructions: Run this entire script in Supabase Dashboard -> SQL Editor -> Run.
--
-- Root Cause Fixed:
--   PostgreSQL Error 42703: column "full_name" does not exist.
--   The public.users table uses `display_name` (and `email`), but earlier RPCs
--   attempted to query `full_name`.
--
-- Fixes Included:
--   1. Adds `full_name` column to public.users as an optional alias column.
--   2. Updates `join_trip_by_code` RPC to use `coalesce(display_name, email, 'Traveler')`.
--   3. Updates `approve_member`, `reject_or_remove_member`, and `update_member_roles` RPCs.
--   4. Exception-safe notifications & activity logging.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Column Safeguard on public.users ──────────────────────────────────────
alter table public.users add column if not exists full_name text;

-- ── 2. join_trip_by_code RPC ──────────────────────────────────────────────────
create or replace function public.join_trip_by_code(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id       uuid := auth.uid();
  v_trip_id       uuid;
  v_trip_name     text;
  v_owner_id      uuid;
  v_clean_code    text;
  v_join_name     text;
  v_existing_stat text;
begin
  -- 1. Ensure authenticated
  if v_user_id is null then
    raise exception 'Must be logged in to join a trip.';
  end if;

  -- 2. Clean and validate invite code
  v_clean_code := upper(regexp_replace(coalesce(p_invite_code, ''), '[^a-zA-Z0-9]', '', 'g'));
  if length(v_clean_code) < 4 then
    raise exception 'Invalid invite code. Please check the code and try again.';
  end if;

  -- 3. Look up trip
  select t.id, t.name, t.owner_id
    into v_trip_id, v_trip_name, v_owner_id
    from public.trips t
   where upper(regexp_replace(coalesce(t.invite_code, ''), '[^a-zA-Z0-9]', '', 'g')) = v_clean_code
   limit 1;

  if v_trip_id is null then
    raise exception 'Trip not found. Please verify your invite code.';
  end if;

  -- 4. Prevent owner from joining their own trip
  if v_owner_id = v_user_id then
    raise exception 'You are already the organizer of this trip.';
  end if;

  -- 5. Ensure user exists in public.users to satisfy foreign keys
  select coalesce(display_name, email, 'Traveler')
    into v_join_name
    from public.users
   where id = v_user_id;

  if v_join_name is null then
    begin
      insert into public.users (id, email, display_name, updated_at)
      values (
        v_user_id,
        coalesce(auth.jwt()->>'email', v_user_id::text || '@taratravel.app'),
        coalesce(auth.jwt()->>'user_metadata'->>'full_name', auth.jwt()->>'user_metadata'->>'name', 'Traveler'),
        now()
      )
      on conflict (id) do nothing;
    exception when others then
      null;
    end;
    v_join_name := 'Traveler';
  end if;

  -- 6. Check existing membership state
  select status into v_existing_stat
    from public.trip_members
   where trip_id = v_trip_id
     and user_id = v_user_id
   limit 1;

  if v_existing_stat is not null then
    if v_existing_stat = 'approved' then
      return jsonb_build_object(
        'success',   true,
        'trip_id',   v_trip_id,
        'trip_name', v_trip_name,
        'status',    'approved',
        'already_member', true
      );
    elsif v_existing_stat = 'pending' then
      return jsonb_build_object(
        'success',   true,
        'trip_id',   v_trip_id,
        'trip_name', v_trip_name,
        'status',    'pending',
        'already_pending', true
      );
    elsif v_existing_stat = 'rejected' then
      -- Re-open rejected request as pending
      update public.trip_members
         set status = 'pending',
             updated_at = now()
       where trip_id = v_trip_id
         and user_id = v_user_id;
    end if;
  else
    -- Insert new pending member
    insert into public.trip_members (trip_id, user_id, roles, status)
    values (v_trip_id, v_user_id, array['member'], 'pending')
    on conflict (trip_id, user_id) do update
      set status = excluded.status,
          updated_at = now();
  end if;

  -- 7. Fan-out notification to trip organizers (best-effort)
  begin
    insert into public.notifications (user_id, trip_id, type, title, body, data)
    select distinct tm.user_id,
           v_trip_id,
           'trip_join_request',
           '🙋 New Join Request',
           v_join_name || ' wants to join "' || v_trip_name || '".',
           jsonb_build_object(
             'trip_id',        v_trip_id,
             'requester_id',   v_user_id,
             'requester_name', v_join_name
           )
      from public.trip_members tm
     where tm.trip_id = v_trip_id
       and tm.status = 'approved'
       and (
             'organizer' = any(tm.roles)
             or tm.user_id = v_owner_id
           )
       and tm.user_id <> v_user_id;
  exception when others then
    null;
  end;

  -- 8. Log activity (best-effort)
  begin
    insert into public.activity_log (trip_id, user_id, action_type, description)
    values (
      v_trip_id,
      v_user_id,
      'member_join_request',
      v_join_name || ' requested to join the trip.'
    );
  exception when others then
    null;
  end;

  return jsonb_build_object(
    'success',   true,
    'trip_id',   v_trip_id,
    'trip_name', v_trip_name,
    'status',    'pending'
  );
end;
$$;

grant execute on function public.join_trip_by_code(text) to authenticated;
grant execute on function public.join_trip_by_code(text) to anon;

-- ── 3. approve_member RPC ─────────────────────────────────────────────────────
create or replace function public.approve_member(
  p_trip_id    uuid,
  p_member_uid uuid
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_id   uuid := auth.uid();
  v_trip_name   text;
  v_member_name text;
begin
  if not (
    public.user_owns_trip(p_trip_id)
    or exists (
      select 1 from public.trip_members
       where trip_id = p_trip_id
         and user_id = v_caller_id
         and 'organizer' = any(roles)
         and status = 'approved'
    )
  ) then
    raise exception 'Only organizers can approve members.';
  end if;

  update public.trip_members
     set status = 'approved',
         updated_at = now()
   where trip_id = p_trip_id
     and user_id = p_member_uid;

  if not found then
    raise exception 'Member record not found.';
  end if;

  select name into v_trip_name from public.trips where id = p_trip_id;
  select coalesce(display_name, email, 'Member')
    into v_member_name
    from public.users where id = p_member_uid;

  begin
    insert into public.notifications (user_id, trip_id, type, title, body, data)
    values (
      p_member_uid,
      p_trip_id,
      'trip_approved',
      '🎉 You''re In!',
      'Your request to join "' || v_trip_name || '" has been approved!',
      jsonb_build_object('trip_id', p_trip_id)
    );
  exception when others then
    null;
  end;

  begin
    insert into public.activity_log (trip_id, user_id, action_type, description)
    values (
      p_trip_id,
      v_caller_id,
      'member_approved',
      v_member_name || ' was approved to join the trip.'
    );
  exception when others then
    null;
  end;

  return jsonb_build_object('success', true, 'trip_id', p_trip_id);
end;
$$;

grant execute on function public.approve_member(uuid, uuid) to authenticated;

-- ── 4. reject_or_remove_member RPC ───────────────────────────────────────────
create or replace function public.reject_or_remove_member(
  p_trip_id    uuid,
  p_member_uid uuid,
  p_reason     text default 'removed'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_id   uuid := auth.uid();
  v_trip_name   text;
  v_member_name text;
  v_notif_title text;
  v_notif_body  text;
  v_notif_type  text;
  v_action_type text;
begin
  if not (
    public.user_owns_trip(p_trip_id)
    or exists (
      select 1 from public.trip_members
       where trip_id = p_trip_id
         and user_id = v_caller_id
         and 'organizer' = any(roles)
         and status = 'approved'
    )
  ) then
    raise exception 'Only organizers can remove members.';
  end if;

  if exists (select 1 from public.trips where id = p_trip_id and owner_id = p_member_uid) then
    raise exception 'Cannot remove the trip owner.';
  end if;

  select name into v_trip_name from public.trips where id = p_trip_id;
  select coalesce(display_name, email, 'Member')
    into v_member_name
    from public.users where id = p_member_uid;

  delete from public.trip_members
   where trip_id = p_trip_id
     and user_id = p_member_uid;

  if p_reason = 'rejected' then
    v_notif_title := 'Trip Request Declined';
    v_notif_body  := 'Your request to join "' || v_trip_name || '" was not approved.';
    v_notif_type  := 'trip_rejected';
    v_action_type := 'member_rejected';
  else
    v_notif_title := 'Removed from Trip';
    v_notif_body  := 'You have been removed from "' || v_trip_name || '".';
    v_notif_type  := 'member_removed';
    v_action_type := 'member_removed';
  end if;

  begin
    insert into public.notifications (user_id, trip_id, type, title, body, data)
    values (
      p_member_uid,
      p_trip_id,
      v_notif_type,
      v_notif_title,
      v_notif_body,
      jsonb_build_object('trip_id', p_trip_id)
    );
  exception when others then
    null;
  end;

  begin
    insert into public.activity_log (trip_id, user_id, action_type, description)
    values (
      p_trip_id,
      v_caller_id,
      v_action_type,
      v_member_name || ' was ' || p_reason || ' from the trip.'
    );
  exception when others then
    null;
  end;

  return jsonb_build_object('success', true, 'trip_id', p_trip_id);
end;
$$;

grant execute on function public.reject_or_remove_member(uuid, uuid, text) to authenticated;

-- ── 5. update_member_roles RPC ────────────────────────────────────────────────
create or replace function public.update_member_roles(
  p_trip_id    uuid,
  p_member_uid uuid,
  p_roles      text[]
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

  update public.trip_members
     set roles      = v_safe_roles,
         updated_at = now()
   where trip_id = p_trip_id
     and (user_id = p_member_uid or id = p_member_uid)
   returning user_id into v_target_user_id;

  if not found or v_target_user_id is null then
    raise exception 'Member record not found for this trip.';
  end if;

  select name into v_trip_name from public.trips where id = p_trip_id;
  select coalesce(display_name, email, 'Member')
    into v_member_name
    from public.users
   where id = v_target_user_id;

  v_role_labels := array_to_string(v_safe_roles, ', ');

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
