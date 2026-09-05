-- =============================================================================
-- 027_storage_avatars_bucket.sql
-- Sets up Supabase Storage bucket 'avatars' with public read CDN access
-- and authenticated owner-only write, update, and delete RLS policies.
-- =============================================================================

-- 1. Create 'avatars' storage bucket if it does not already exist
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'avatars',
  'avatars',
  true,
  5242880, -- 5MB maximum file limit
  ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif']
)
ON CONFLICT (id) DO UPDATE SET
  public = true,
  file_size_limit = 5242880,
  allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

-- 2. Storage RLS Policies for avatars bucket

-- Drop existing policies if previously applied to prevent conflicts
DROP POLICY IF EXISTS "Public Avatar Read Access" ON storage.objects;
DROP POLICY IF EXISTS "User Avatar Write Access" ON storage.objects;
DROP POLICY IF EXISTS "User Avatar Update Access" ON storage.objects;
DROP POLICY IF EXISTS "User Avatar Delete Access" ON storage.objects;

-- Storage table `storage.objects` has RLS enabled by default in Supabase.
-- Note: Do NOT execute `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;`
-- because standard database roles (such as `postgres` or project users) are not the
-- owner of system schema `storage.objects` (owned by `supabase_storage_admin`),
-- which causes error 42501: must be owner of table objects.

-- Policy A: Anyone can read avatars (public CDN)
CREATE POLICY "Public Avatar Read Access"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Policy B: Authenticated users can upload to their own user folder (avatars/{user_id}/*)
CREATE POLICY "User Avatar Write Access"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy C: Authenticated users can update/overwrite their own avatar
CREATE POLICY "User Avatar Update Access"
  ON storage.objects FOR UPDATE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Policy D: Authenticated users can delete their own avatar
CREATE POLICY "User Avatar Delete Access"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'avatars'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
