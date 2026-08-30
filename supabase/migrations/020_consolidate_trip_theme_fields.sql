-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 020: CONSOLIDATE TRIP THEME & DROP UNUSED COVER FIELDS
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Unifies trip type, theme color, and emoji under the canonical trip_type / type.
-- Removes redundant cover_color and cover_emoji columns from public.trips.
-- All styling and emoji representation are resolved dynamically via AppTripTypes.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.trips
  drop column if exists cover_color,
  drop column if exists cover_emoji,
  drop constraint if exists trips_type_check;
