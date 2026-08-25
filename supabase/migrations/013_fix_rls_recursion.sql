-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 013: FIX 42P17 RLS INFINITE RECURSION
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Problem: infinite recursion (PostgreSQL error 42P17) when querying trips.
--
--   trips.trips_members_select  → queries trip_members
--   trip_members.trip_members_owner_all → queries trips
--   → infinite loop
--
-- Fix: replace all cross-table references in RLS policies with two
-- SECURITY DEFINER helper functions that bypass RLS entirely, breaking
-- the recursion cycle.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Helper 1: can the current user access this trip? ─────────────────────────
-- Used by trips RLS to avoid querying trip_members directly.
create or replace function public.user_can_access_trip(p_trip_id uuid)
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
  );
$$;

grant execute on function public.user_can_access_trip(uuid) to authenticated;

-- ── Helper 2: is the current user the owner of this trip? ────────────────────
-- Used by trip_members RLS to avoid querying trips directly.
create or replace function public.user_owns_trip(p_trip_id uuid)
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
  );
$$;

grant execute on function public.user_owns_trip(uuid) to authenticated;

-- ── Fix trips policies ────────────────────────────────────────────────────────
-- Drop all existing trips SELECT/ALL policies that may query trip_members.
drop policy if exists "trips_members_select" on public.trips;
drop policy if exists "trips_owner_all"      on public.trips;

-- Owner: full CRUD (no cross-table reference needed)
create policy "trips_owner_all"
  on public.trips
  for all
  using (auth.uid() = owner_id);

-- Members: read-only access — uses SECURITY DEFINER to avoid recursion
create policy "trips_members_select"
  on public.trips
  for select
  using (public.user_can_access_trip(id));

-- ── Fix trip_members policies ─────────────────────────────────────────────────
-- Drop the recursive owner policy that queries public.trips directly.
drop policy if exists "trip_members_owner_all" on public.trip_members;
drop policy if exists "trip_members_select"    on public.trip_members;
drop policy if exists "Members can view other members" on public.trip_members;

-- Select: members can see each other — uses SECURITY DEFINER
create policy "trip_members_select"
  on public.trip_members
  for select
  using (public.is_trip_member(trip_id));

-- Owner: full control over trip's members — uses SECURITY DEFINER
create policy "trip_members_owner_all"
  on public.trip_members
  for all
  using (public.user_owns_trip(trip_id));

-- Self: each member can update their own row (e.g. location)
drop policy if exists "trip_members_update_own" on public.trip_members;
create policy "trip_members_update_own"
  on public.trip_members
  for update
  using (user_id = auth.uid());
