-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 030: ADD destination_details COLUMN TO trips
-- ═══════════════════════════════════════════════════════════════════════════
--
-- The create-trip flow writes a `destination_details` JSONB payload
-- (map-enable flag, journey-mode, hub list) but the column was never
-- created.  This migration adds it so trip inserts stop failing.
-- ═══════════════════════════════════════════════════════════════════════════

alter table public.trips
  add column if not exists destination_details jsonb;
