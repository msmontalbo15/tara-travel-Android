-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 017: MEMBER APPROVAL WORKFLOW & NOTIFICATIONS
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Changes:
--   1. Rewrites join_trip_by_code() RPC — new joiners land as 'pending';
--      existing members are left unchanged.
--   2. Adds approve_member() RPC — sets status='approved' and notifies
--      the applicant.
--   3. Adds reject_or_remove_member() RPC — deletes the trip_members row
--      and notifies the affected user.
--   4. Adds leave_trip() RPC — allows a non-owner to leave a trip; blocks
--      if the caller is the sole owner.
-- ─────────────────────────────────────────────────────────────────────────────

-- ── 1. join_trip_by_code (PENDING status) ────────────────────────────────────
create or replace function public.join_trip_by_code(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id    uuid := auth.uid();
  v_trip_id    uuid;
  v_trip_name  text;
  v_owner_id   uuid;
  v_status     text := 'pending';
  v_join_name  text;
begin
  -- 1. Ensure authenticated
  if v_user_id is null then
    raise exception 'Must be logged in to join a trip.';
  end if;

  -- 2. Validate invite code
  if p_invite_code is null or length(trim(p_invite_code)) = 0 then
    raise exception 'Invite code cannot be empty.';
  end if;

  -- 3. Look up trip
  select t.id, t.name, t.owner_id
    into v_trip_id, v_trip_name, v_owner_id
    from public.trips t
   where upper(t.invite_code) = upper(trim(p_invite_code))
   limit 1;

  if v_trip_id is null then
    raise exception 'Invalid invite code or trip not found.';
  end if;

  -- 4. Prevent owner from "joining" their own trip as pending
  if v_owner_id = v_user_id then
    raise exception 'You are already the organizer of this trip.';
  end if;

  -- 5. Resolve requester display name
  select coalesce(display_name, full_name, email, 'Someone')
    into v_join_name
    from public.users
   where id = v_user_id;

  -- 6. Insert as 'pending' (on conflict leave existing row intact)
  insert into public.trip_members (trip_id, user_id, roles, status)
  values (v_trip_id, v_user_id, array['member'], 'pending')
  on conflict (trip_id, user_id) do nothing;

  -- 7. Notify all Organizers + trip owner about the new join request
  --    Uses INSERT … SELECT to fan-out to multiple recipients.
  insert into public.notifications (user_id, trip_id, type, title, body, data)
  select distinct tm.user_id,
         v_trip_id,
         'trip_join_request',
         '🙋 New Join Request',
         v_join_name || ' wants to join "' || v_trip_name || '".',
         jsonb_build_object(
           'trip_id',     v_trip_id,
           'requester_id', v_user_id,
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

  -- 8. Log activity
  insert into public.activity_log (trip_id, user_id, action_type, description)
  values (
    v_trip_id,
    v_user_id,
    'member_join_request',
    v_join_name || ' requested to join the trip.'
  );

  return jsonb_build_object(
    'success',  true,
    'trip_id',  v_trip_id,
    'trip_name', v_trip_name,
    'status',   v_status
  );
end;
$$;

grant execute on function public.join_trip_by_code(text) to authenticated;

-- ── 2. approve_member(trip_id, member_user_id) ───────────────────────────────
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
  v_caller_id  uuid := auth.uid();
  v_trip_name  text;
  v_member_name text;
begin
  -- Only trip owner or organizer may approve
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

  -- Approve
  update public.trip_members
     set status = 'approved'
   where trip_id = p_trip_id
     and user_id = p_member_uid;

  if not found then
    raise exception 'Member record not found.';
  end if;

  -- Resolve names for notification
  select name into v_trip_name from public.trips where id = p_trip_id;
  select coalesce(display_name, full_name, email, 'Member')
    into v_member_name
    from public.users where id = p_member_uid;

  -- Notify the approved member
  insert into public.notifications (user_id, trip_id, type, title, body, data)
  values (
    p_member_uid,
    p_trip_id,
    'trip_approved',
    '🎉 You''re In!',
    'Your request to join "' || v_trip_name || '" has been approved!',
    jsonb_build_object('trip_id', p_trip_id)
  );

  -- Activity log
  insert into public.activity_log (trip_id, user_id, action_type, description)
  values (
    p_trip_id,
    v_caller_id,
    'member_approved',
    v_member_name || ' was approved to join the trip.'
  );

  return jsonb_build_object('success', true, 'trip_id', p_trip_id);
end;
$$;

grant execute on function public.approve_member(uuid, uuid) to authenticated;

-- ── 3. reject_or_remove_member(trip_id, member_user_id, reason) ──────────────
--    Works for both pending rejection and approved member removal.
create or replace function public.reject_or_remove_member(
  p_trip_id    uuid,
  p_member_uid uuid,
  p_reason     text default 'removed'   -- 'rejected' | 'removed'
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_caller_id  uuid := auth.uid();
  v_trip_name  text;
  v_member_name text;
  v_notif_title text;
  v_notif_body  text;
  v_notif_type  text;
  v_action_type text;
begin
  -- Only trip owner or organizer may remove/reject
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

  -- Cannot remove the trip owner
  if exists (select 1 from public.trips where id = p_trip_id and owner_id = p_member_uid) then
    raise exception 'Cannot remove the trip owner.';
  end if;

  -- Resolve names
  select name into v_trip_name from public.trips where id = p_trip_id;
  select coalesce(display_name, full_name, email, 'Member')
    into v_member_name
    from public.users where id = p_member_uid;

  -- Remove from trip_members
  delete from public.trip_members
   where trip_id = p_trip_id
     and user_id = p_member_uid;

  -- Build notification content based on reason
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

  -- Notify affected user
  insert into public.notifications (user_id, trip_id, type, title, body, data)
  values (
    p_member_uid,
    p_trip_id,
    v_notif_type,
    v_notif_title,
    v_notif_body,
    jsonb_build_object('trip_id', p_trip_id)
  );

  -- Activity log
  insert into public.activity_log (trip_id, user_id, action_type, description)
  values (
    p_trip_id,
    v_caller_id,
    v_action_type,
    v_member_name || ' was ' || p_reason || ' from the trip.'
  );

  return jsonb_build_object('success', true, 'trip_id', p_trip_id);
end;
$$;

grant execute on function public.reject_or_remove_member(uuid, uuid, text) to authenticated;

-- ── 4. leave_trip(trip_id) ───────────────────────────────────────────────────
create or replace function public.leave_trip(p_trip_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id  uuid := auth.uid();
  v_trip_name text;
begin
  if v_user_id is null then
    raise exception 'Must be logged in.';
  end if;

  -- Block owner from leaving without transferring ownership first
  if exists (select 1 from public.trips where id = p_trip_id and owner_id = v_user_id) then
    raise exception 'Trip owner cannot leave. Transfer ownership first.';
  end if;

  select name into v_trip_name from public.trips where id = p_trip_id;

  delete from public.trip_members
   where trip_id = p_trip_id
     and user_id = v_user_id;

  -- Activity log (best-effort — ignore failures after removal)
  begin
    insert into public.activity_log (trip_id, user_id, action_type, description)
    values (p_trip_id, v_user_id, 'member_left', 'A member left the trip.');
  exception when others then
    null;
  end;

  return jsonb_build_object('success', true, 'trip_id', p_trip_id, 'trip_name', v_trip_name);
end;
$$;

grant execute on function public.leave_trip(uuid) to authenticated;
