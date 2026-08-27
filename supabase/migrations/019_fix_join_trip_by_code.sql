-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 019: HARDEN JOIN TRIP BY CODE RPC & FK SAFEGUARDS
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Instructions: Run this entire script in Supabase Dashboard -> SQL Editor -> Run.
--
-- Fixes:
--   1. Ensures public.users row exists before inserting into trip_members / activity_log.
--   2. Detects already-joined members and returns accurate status ('approved' vs 'pending')
--      without raising confusing errors or duplicate notifications.
--   3. Handles re-application if previous status was 'rejected'.
--   4. Wraps auxiliary notifications and activity logs in exception-safe blocks
--      so notification errors never roll back the primary membership join.
-- ═══════════════════════════════════════════════════════════════════════════

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
  select coalesce(display_name, full_name, email, 'Traveler')
    into v_join_name
    from public.users
   where id = v_user_id;

  if v_join_name is null then
    -- Insert fallback user record
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
    -- Non-critical: continue without failing join
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
