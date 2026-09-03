-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 024: TRIP POLLS, CHAT ENHANCEMENTS & FCM SUPPORT
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Adds:
--   1. trip_polls         — Interactive in-chat travel polls
--   2. trip_poll_votes    — Per-user votes on poll options
--   3. trip_messages      — is_pinned, poll_id, message_type columns
--   4. users              — fcm_token for Firebase Cloud Messaging
--
-- RLS: All policies use public.is_trip_member(trip_id) to avoid recursion.
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. TRIP POLLS TABLE ──────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trip_polls (
  id               uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id          uuid        NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  creator_id       uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  creator_name     text        NOT NULL DEFAULT 'Anonymous',
  question         text        NOT NULL CHECK (char_length(question) > 0),
  options          jsonb       NOT NULL DEFAULT '[]'::jsonb,
  category         text        NOT NULL DEFAULT 'custom'
                               CHECK (category IN ('food', 'departure', 'activity', 'budget', 'custom')),
  allow_multiple   boolean     NOT NULL DEFAULT false,
  is_closed        boolean     NOT NULL DEFAULT false,
  winner_option_id text,
  created_at       timestamptz NOT NULL DEFAULT now(),
  closed_at        timestamptz
);

-- Compound index for fast trip-scoped queries ordered by recency
CREATE INDEX IF NOT EXISTS idx_trip_polls_trip_created
  ON public.trip_polls (trip_id, created_at DESC);

-- ── 2. TRIP POLL VOTES TABLE ─────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.trip_poll_votes (
  id          uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id     uuid        NOT NULL REFERENCES public.trip_polls(id) ON DELETE CASCADE,
  trip_id     uuid        NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  user_id     uuid        NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  voter_name  text        NOT NULL DEFAULT 'Anonymous',
  option_id   text        NOT NULL,
  created_at  timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT unique_user_poll_option UNIQUE (poll_id, user_id, option_id)
);

-- Fast lookup: all votes for a given poll
CREATE INDEX IF NOT EXISTS idx_trip_poll_votes_poll
  ON public.trip_poll_votes (poll_id);

-- Fast lookup: all votes in a trip
CREATE INDEX IF NOT EXISTS idx_trip_poll_votes_trip
  ON public.trip_poll_votes (trip_id);

-- ── 3. ENHANCE trip_messages ─────────────────────────────────────────────────

-- Add is_pinned flag for pinned travel announcements
ALTER TABLE public.trip_messages
  ADD COLUMN IF NOT EXISTS is_pinned boolean NOT NULL DEFAULT false;

-- Add poll_id reference for poll-type messages
ALTER TABLE public.trip_messages
  ADD COLUMN IF NOT EXISTS poll_id uuid REFERENCES public.trip_polls(id) ON DELETE SET NULL;

-- Add message_type discriminator (text, poll, announcement, quick_travel)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'trip_messages'
      AND column_name = 'message_type'
  ) THEN
    ALTER TABLE public.trip_messages
      ADD COLUMN message_type text NOT NULL DEFAULT 'text';
  END IF;
END $$;

-- ── 4. ADD fcm_token TO users ────────────────────────────────────────────────

ALTER TABLE public.users
  ADD COLUMN IF NOT EXISTS fcm_token text;

-- ── 5. ROW LEVEL SECURITY ────────────────────────────────────────────────────

-- trip_polls RLS
ALTER TABLE public.trip_polls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "poll_member_select" ON public.trip_polls;
CREATE POLICY "poll_member_select"
  ON public.trip_polls FOR SELECT
  USING (public.is_trip_member(trip_id));

DROP POLICY IF EXISTS "poll_member_insert" ON public.trip_polls;
CREATE POLICY "poll_member_insert"
  ON public.trip_polls FOR INSERT
  WITH CHECK (auth.uid() = creator_id AND public.is_trip_member(trip_id));

DROP POLICY IF EXISTS "poll_creator_update" ON public.trip_polls;
CREATE POLICY "poll_creator_update"
  ON public.trip_polls FOR UPDATE
  USING (auth.uid() = creator_id OR public.user_owns_trip(trip_id));

DROP POLICY IF EXISTS "poll_creator_delete" ON public.trip_polls;
CREATE POLICY "poll_creator_delete"
  ON public.trip_polls FOR DELETE
  USING (auth.uid() = creator_id OR public.user_owns_trip(trip_id));

-- trip_poll_votes RLS
ALTER TABLE public.trip_poll_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "vote_member_select" ON public.trip_poll_votes;
CREATE POLICY "vote_member_select"
  ON public.trip_poll_votes FOR SELECT
  USING (public.is_trip_member(trip_id));

DROP POLICY IF EXISTS "vote_member_insert" ON public.trip_poll_votes;
CREATE POLICY "vote_member_insert"
  ON public.trip_poll_votes FOR INSERT
  WITH CHECK (auth.uid() = user_id AND public.is_trip_member(trip_id));

DROP POLICY IF EXISTS "vote_owner_delete" ON public.trip_poll_votes;
CREATE POLICY "vote_owner_delete"
  ON public.trip_poll_votes FOR DELETE
  USING (auth.uid() = user_id);

-- ── 6. REALTIME PUBLICATION ──────────────────────────────────────────────────

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'trip_polls'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_polls;
  END IF;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime'
    AND schemaname = 'public'
    AND tablename = 'trip_poll_votes'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE public.trip_poll_votes;
  END IF;
END $$;
