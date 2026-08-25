-- ═══════════════════════════════════════════════════════════════════════════
-- MIGRATION 011 — Sync missing user-input fields & RLS fixes
-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Adds booking_ref to itinerary_stops for booking / confirmation numbers.
-- 2. Adds departure_lat / departure_lng to trips for departure map pins.
-- 3. Adds status column to trip_members ('pending', 'approved', 'rejected').
-- 4. Fixes reciprocal friends RLS policies for insert & delete.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Add booking_ref to itinerary_stops (idempotent)
alter table public.itinerary_stops
  add column if not exists booking_ref text;

-- 2. Add departure point and lat/lng to trips if not present
alter table public.trips
  add column if not exists departure_point text,
  add column if not exists departure_lat   double precision,
  add column if not exists departure_lng   double precision;

-- 3. Add status to trip_members if not present
alter table public.trip_members
  add column if not exists status text not null default 'approved';

-- 4. Fix friends reciprocal insert & delete RLS policies
drop policy if exists "friends_insert_own" on public.friends;
drop policy if exists "friends_delete_own" on public.friends;

create policy "friends_insert_own"
  on public.friends for insert
  with check (auth.uid() = user_id or auth.uid() = friend_id);

create policy "friends_delete_own"
  on public.friends for delete
  using (auth.uid() = user_id or auth.uid() = friend_id);

comment on column public.itinerary_stops.booking_ref is
  'Booking / confirmation reference number for this stop (hotel, flight, tour, etc.)';

comment on column public.trips.departure_lat is
  'Latitude of the trip departure point selected in transport step';

comment on column public.trips.departure_lng is
  'Longitude of the trip departure point selected in transport step';

comment on column public.trip_members.status is
  'Membership status: pending (awaiting organizer approval), approved, or rejected';

