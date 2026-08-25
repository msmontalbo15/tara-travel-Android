-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 016: COMPLETE CRUD RLS POLICIES FOR TRIPS & MEMBERS
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. Trips Policies ────────────────────────────────────────────────────────
drop policy if exists "trips_owner_all"      on public.trips;
drop policy if exists "trips_members_select" on public.trips;

-- Owner has full CRUD on trips
create policy "trips_owner_all"
  on public.trips
  for all
  using (auth.uid() = owner_id)
  with check (auth.uid() = owner_id);

-- Members can select trips they belong to
create policy "trips_members_select"
  on public.trips
  for select
  using (public.user_can_access_trip(id));

-- ── 2. Trip Members Policies ──────────────────────────────────────────────────
drop policy if exists "trip_members_select"       on public.trip_members;
drop policy if exists "trip_members_owner_all"    on public.trip_members;
drop policy if exists "trip_members_update_own"   on public.trip_members;
drop policy if exists "trip_members_update"       on public.trip_members;
drop policy if exists "trip_members_insert"       on public.trip_members;
drop policy if exists "trip_members_delete"       on public.trip_members;
drop policy if exists "Members can view other members" on public.trip_members;

-- Select: members of the trip can view all members in that trip
create policy "trip_members_select"
  on public.trip_members
  for select
  using (public.is_trip_member(trip_id));

-- Insert: trip owner can add members OR any user can insert their own membership
create policy "trip_members_insert"
  on public.trip_members
  for insert
  with check (
    auth.uid() = user_id
    or public.user_owns_trip(trip_id)
  );

-- Update: user can update their own row (location, status) OR trip owner can update member roles/status
create policy "trip_members_update"
  on public.trip_members
  for update
  using (
    auth.uid() = user_id
    or public.user_owns_trip(trip_id)
  );

-- Delete: user can leave the trip OR trip owner can remove members
create policy "trip_members_delete"
  on public.trip_members
  for delete
  using (
    auth.uid() = user_id
    or public.user_owns_trip(trip_id)
  );
