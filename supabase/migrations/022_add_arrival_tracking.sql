-- =============================================================================
-- Migration 022: Add Arrival Tracking Columns to Itinerary Stops
-- Adds 'visited_at' (timestamptz) for the stop-level arrival timestamp and
-- 'checked_in_data' (jsonb) for per-member arrival timestamps.
-- Format: {"userId1": "2026-09-01T10:42:00Z", "userId2": "2026-09-01T10:45:00Z"}
-- =============================================================================

-- 1. Add stop-level arrival timestamp
alter table public.itinerary_stops
  add column if not exists visited_at timestamptz;

-- 2. Add per-member checked-in data as JSONB map of userId → ISO timestamp
alter table public.itinerary_stops
  add column if not exists checked_in_data jsonb default '{}'::jsonb;
