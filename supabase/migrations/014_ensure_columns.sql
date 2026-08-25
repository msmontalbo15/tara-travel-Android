-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 014: ENSURE MISSING COLUMNS
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.itinerary_stops
  add column if not exists booking_ref text;

alter table public.trips
  add column if not exists departure_point text,
  add column if not exists departure_lat   double precision,
  add column if not exists departure_lng   double precision;

alter table public.trip_members
  add column if not exists status text not null default 'approved';

alter table public.users
  add column if not exists hide_surname boolean not null default false;

alter table public.user_settings
  add column if not exists hide_surname boolean not null default false;
