-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 025: CHAT RICH EMBEDS, REACTIONS & CROWDSOURCING
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Adds:
--   1. trip_messages.metadata   — JSONB payload for rich cards (itinerary, expenses, packing, location, media)
--   2. trip_messages.reactions  — JSONB map of emoji -> list of user IDs
--   3. RLS policies allowing trip members to react to messages and add poll options.
--
-- RLS: All policies use public.is_trip_member(trip_id) to avoid recursion.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. ENHANCE trip_messages ─────────────────────────────────────────────────

-- Add metadata column for rich card payloads
ALTER TABLE public.trip_messages
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- Add reactions column for emoji reactions { "❤️": ["uid1", "uid2"] }
ALTER TABLE public.trip_messages
  ADD COLUMN IF NOT EXISTS reactions jsonb DEFAULT '{}'::jsonb;

-- ── 2. RLS POLICIES FOR REACTIONS & EDITS ────────────────────────────────────

-- Allow trip members to update messages in their trip (for adding/removing reactions)
DROP POLICY IF EXISTS "member_update_reactions" ON public.trip_messages;
CREATE POLICY "member_update_reactions"
  ON public.trip_messages FOR UPDATE
  USING (public.is_trip_member(trip_id))
  WITH CHECK (public.is_trip_member(trip_id));

-- Allow trip members to update trip_polls (for adding crowdsourced options)
DROP POLICY IF EXISTS "member_update_poll_options" ON public.trip_polls;
CREATE POLICY "member_update_poll_options"
  ON public.trip_polls FOR UPDATE
  USING (public.is_trip_member(trip_id))
  WITH CHECK (public.is_trip_member(trip_id));
