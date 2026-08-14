-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 010: FIX trip_members RLS INFINITE RECURSION
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The "Members can view other members" policy on trip_members referenced
-- trip_members inside its own USING clause, causing PostgreSQL error 42P17
-- whenever any other table's policy queried trip_members (e.g. itinerary_stops).

create or replace function public.is_trip_member(p_trip_id uuid)
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1
    from public.trip_members
    where trip_id = p_trip_id
      and user_id = auth.uid()
  )
  or exists (
    select 1
    from public.trips
    where id = p_trip_id
      and owner_id = auth.uid()
  );
$$;

grant execute on function public.is_trip_member(uuid) to authenticated;

drop policy if exists "Members can view other members" on public.trip_members;
create policy "Members can view other members"
  on public.trip_members
  for select
  using (public.is_trip_member(trip_id));
