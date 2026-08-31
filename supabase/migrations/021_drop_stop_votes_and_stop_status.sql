-- =============================================================================
-- Migration 021: Drop Stop Votes and Itinerary Stop Status
-- Permanently removes legacy collaborative voting (public.stop_votes) and
-- the redundant 'status' column from public.itinerary_stops.
-- Arrival and completion lifecycle is tracked via 'visited_at' and member check-ins.
-- =============================================================================

-- 1. Drop public.stop_votes table and its cascade dependencies (policies, indexes, triggers)
drop table if exists public.stop_votes cascade;

-- 2. Drop legacy 'status' column from public.itinerary_stops
alter table public.itinerary_stops
  drop column if exists status cascade;
