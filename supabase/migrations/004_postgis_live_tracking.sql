-- ─────────────────────────────────────────────────────────────────────────────
-- TARA TRAVEL · Migration 004 — PostGIS Live Tracking
-- Converts `member_locations` from a virtual view into a high-performance
-- dedicated physical table with PostGIS geometry, heading/speed telemetry,
-- non-recursive RLS, and Supabase Realtime logical replication.
-- ─────────────────────────────────────────────────────────────────────────────

-- 1. Enable PostGIS extension (idempotent)
create extension if not exists postgis schema public;

-- 2. Drop existing view if it exists (legacy 000_master_schema definition)
drop view if exists public.member_locations cascade;

-- 3. Create dedicated physical table for live GPS telemetry
create table if not exists public.member_locations (
  id           uuid primary key default gen_random_uuid(),
  member_id    uuid not null references public.users(id) on delete cascade,
  trip_id      uuid not null references public.trips(id) on delete cascade,
  latitude     double precision not null,
  longitude    double precision not null,
  heading      double precision not null default 0,
  speed        double precision not null default 0,
  altitude     double precision not null default 0,
  is_online    boolean not null default true,
  geom         geometry(Point, 4326),
  last_updated timestamptz not null default now(),
  constraint uq_member_locations_trip_member unique (trip_id, member_id)
);

-- 4. Spatial index for fast PostGIS proximity queries
create index if not exists idx_member_locations_geom
  on public.member_locations using gist (geom);

-- 5. Row Level Security (RLS) — Non-recursive policies
alter table public.member_locations enable row level security;

drop policy if exists "member_locations_select" on public.member_locations;
drop policy if exists "member_locations_all_own" on public.member_locations;

create policy "member_locations_select"
  on public.member_locations for select
  using (public.is_trip_member(trip_id));

create policy "member_locations_all_own"
  on public.member_locations for all
  using (auth.uid() = member_id)
  with check (auth.uid() = member_id);

-- 6. Enable Supabase Realtime Logical Replication
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'member_locations'
  ) then
    alter publication supabase_realtime add table public.member_locations;
  end if;
end $$;

-- 7. Upsert RPC: Atomically broadcast a member's live location with PostGIS geometry
create or replace function public.update_member_location(
  p_trip_id  uuid,
  p_lat      double precision,
  p_lng      double precision,
  p_heading  double precision default 0,
  p_speed    double precision default 0,
  p_altitude double precision default 0
)
returns void
language plpgsql
security definer
as $$
begin
  insert into public.member_locations (
    member_id, trip_id, latitude, longitude, heading, speed, altitude,
    is_online, geom, last_updated
  ) values (
    auth.uid(), p_trip_id, p_lat, p_lng, p_heading, p_speed, p_altitude,
    true,
    st_setsrid(st_makepoint(p_lng, p_lat), 4326),
    now()
  )
  on conflict (trip_id, member_id) do update set
    latitude     = excluded.latitude,
    longitude    = excluded.longitude,
    heading      = excluded.heading,
    speed        = excluded.speed,
    altitude     = excluded.altitude,
    is_online    = true,
    geom         = excluded.geom,
    last_updated = now();
end;
$$;

grant execute on function public.update_member_location to authenticated;
