-- ==============================================================================
-- Migration 028: FCM Device Token Management (Plan 21 - Dual-Cloud Ecosystem)
-- ==============================================================================

-- 1. Add fcm_token column to public.users if not already present
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'fcm_token'
    ) THEN
        ALTER TABLE public.users ADD COLUMN fcm_token TEXT;
    END IF;
END $$;

-- 2. Create index for fast token lookups and notification relays
CREATE INDEX IF NOT EXISTS idx_users_fcm_token ON public.users(fcm_token)
WHERE fcm_token IS NOT NULL;

-- 3. Ensure users can update their own fcm_token
-- (Inherits existing RLS policy "Users can update their own profile")
COMMENT ON COLUMN public.users.fcm_token IS 'Firebase Cloud Messaging device registration token for remote push wake-up';
