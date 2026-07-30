-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 008: SECURE JOIN TRIP BY CODE RPC
-- ═══════════════════════════════════════════════════════════════════════════

-- SECURITY DEFINER RPC function allows authenticated users to look up and join
-- a trip via invite code without exposing RLS SELECT permissions to non-members.

create or replace function public.join_trip_by_code(p_invite_code text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_trip_id uuid;
  v_trip_name text;
begin
  -- 1. Ensure authenticated user
  if v_user_id is null then
    raise exception 'Must be logged in to join a trip.';
  end if;

  -- 2. Validate input code
  if p_invite_code is null or length(trim(p_invite_code)) = 0 then
    raise exception 'Invite code cannot be empty.';
  end if;

  -- 3. Lookup trip by uppercase invite code
  select id, name into v_trip_id, v_trip_name
  from public.trips
  where upper(invite_code) = upper(trim(p_invite_code))
  limit 1;

  if v_trip_id is null then
    raise exception 'Invalid invite code or trip not found.';
  end if;

  -- 4. Add user to trip_members with 'member' role (ignore if already member)
  insert into public.trip_members (trip_id, user_id, roles)
  values (v_trip_id, v_user_id, array['member'])
  on conflict (trip_id, user_id) do update
    set roles = case
      when not ('member' = any(trip_members.roles)) then array_append(trip_members.roles, 'member')
      else trip_members.roles
    end;

  -- 5. Return success payload
  return jsonb_build_object(
    'success', true,
    'trip_id', v_trip_id,
    'trip_name', v_trip_name
  );
end;
$$;

-- Grant execution to authenticated users
grant execute on function public.join_trip_by_code(text) to authenticated;
