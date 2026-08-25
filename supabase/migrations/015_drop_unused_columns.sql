-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 015: DROP UNUSED & REDUNDANT COLUMNS
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Cleans up all legacy, redundant, and unused columns across Supabase tables
-- to streamline the database schema and keep it lean.
-- ═══════════════════════════════════════════════════════════════════════════

-- 1. Trips table cleanup
alter table public.trips
  drop column if exists destination_lat,
  drop column if exists destination_lng,
  drop column if exists invite_expires_at,
  drop column if exists cover_image_url,
  drop column if exists discord_channel_id;

-- 2. Itinerary stops policies update & column cleanup
drop policy if exists "stops_update_nav" on public.itinerary_stops;
drop policy if exists "stops_delete_nav" on public.itinerary_stops;

create policy "stops_update_nav"
  on public.itinerary_stops for update
  using (public.is_trip_member(trip_id));

create policy "stops_delete_nav"
  on public.itinerary_stops for delete
  using (public.is_trip_member(trip_id));

alter table public.itinerary_stops
  drop column if exists duration_min,
  drop column if exists google_place_id,
  drop column if exists photo_url,
  drop column if exists created_by;

-- 3. Packing items cleanup
alter table public.packing_items
  drop column if exists quantity,
  drop column if exists notes,
  drop column if exists created_by,
  drop column if exists checked_by,
  drop column if exists checked_at;

-- 4. Expenses cleanup
alter table public.expenses
  drop column if exists split_meta,
  drop column if exists rejected_by;

-- 5. Trip messages cleanup
alter table public.trip_messages
  drop column if exists media_type,
  drop column if exists reply_to_id,
  drop column if exists is_edited,
  drop column if exists edited_at;

-- 6. User settings cleanup
alter table public.user_settings
  drop column if exists email_notifications,
  drop column if exists mpin_hash,
  drop column if exists mpin_salt,
  drop column if exists profile_visibility;

-- 7. Drop unused duplicate friendships table (friends table is used)
drop table if exists public.friendships cascade;
