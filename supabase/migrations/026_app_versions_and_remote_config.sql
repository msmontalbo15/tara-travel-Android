-- ═══════════════════════════════════════════════════════════════════════════
-- TARA TRAVEL · MIGRATION 026: APP VERSIONING, REMOTE CONFIG & OTA RELEASES
-- ═══════════════════════════════════════════════════════════════════════════
--
-- Adds:
--   1. public.app_versions table — authoritative remote versioning, force-update,
--      maintenance mode, and changelog records.
--   2. Public SELECT RLS policy for anonymous and authenticated clients.
--   3. Storage bucket `app-releases` configuration for direct cloud APK updates.
--
-- ═══════════════════════════════════════════════════════════════════════════

-- ── 1. CREATE app_versions TABLE ─────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.app_versions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL DEFAULT 'android' CHECK (platform IN ('android', 'ios', 'web')),
  min_supported_version text NOT NULL,
  latest_version text NOT NULL,
  force_update_url text,
  maintenance_mode boolean NOT NULL DEFAULT false,
  maintenance_title text DEFAULT 'Under Scheduled Maintenance',
  maintenance_message text DEFAULT 'We are currently performing routine system upgrades to improve Tara Travel. Please check back shortly.',
  estimated_back_online timestamptz,
  release_notes text DEFAULT 'General performance improvements and bug fixes.',
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Index for high-frequency platform lookup
CREATE INDEX IF NOT EXISTS idx_app_versions_platform_created
  ON public.app_versions (platform, created_at DESC);

-- Enable RLS
ALTER TABLE public.app_versions ENABLE ROW LEVEL SECURITY;

-- ── 2. RLS POLICIES ──────────────────────────────────────────────────────────

-- Any client (authenticated or unauthenticated guest) can read version info
DROP POLICY IF EXISTS "anon_select_app_versions" ON public.app_versions;
CREATE POLICY "anon_select_app_versions"
  ON public.app_versions FOR SELECT
  USING (true);

-- Only service_role can insert or update version records (e.g. CI/CD pipeline)
DROP POLICY IF EXISTS "service_role_all_app_versions" ON public.app_versions;
CREATE POLICY "service_role_all_app_versions"
  ON public.app_versions FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- ── 3. SEED INITIAL BASELINE RECORD (v1.0.0+1) ────────────────────────────────

INSERT INTO public.app_versions (
  platform,
  min_supported_version,
  latest_version,
  force_update_url,
  maintenance_mode,
  release_notes
)
SELECT
  'android',
  '1.0.0+1',
  '1.0.0+1',
  'https://tara-travel.app/download/android',
  false,
  'Initial release of Tara Travel. Plan trips, collaborate in realtime, manage budgets, and explore the Philippines!'
WHERE NOT EXISTS (
  SELECT 1 FROM public.app_versions WHERE platform = 'android'
);

-- ── 4. STORAGE BUCKET CONFIGURATION FOR DIRECT APK RELEASES ───────────────────

INSERT INTO storage.buckets (id, name, public)
VALUES ('app-releases', 'app-releases', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "public_read_app_releases" ON storage.objects;
CREATE POLICY "public_read_app_releases"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'app-releases');

DROP POLICY IF EXISTS "service_role_write_app_releases" ON storage.objects;
CREATE POLICY "service_role_write_app_releases"
  ON storage.objects FOR ALL
  TO service_role
  USING (bucket_id = 'app-releases')
  WITH CHECK (bucket_id = 'app-releases');
