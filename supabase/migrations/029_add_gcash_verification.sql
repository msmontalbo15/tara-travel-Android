-- ==============================================================================
-- Migration 029: E-Wallet Ownership Verification & Verified QR Storage (Plan 23)
-- ==============================================================================

-- 1. Add gcash_verified column to public.users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'gcash_verified'
    ) THEN
        ALTER TABLE public.users ADD COLUMN gcash_verified BOOLEAN DEFAULT false;
    END IF;
END $$;

-- 2. Add gcash_verified_at timestamp column to public.users
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'gcash_verified_at'
    ) THEN
        ALTER TABLE public.users ADD COLUMN gcash_verified_at TIMESTAMPTZ;
    END IF;
END $$;

-- 3. Add payment_provider column to public.users (gcash | maya)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'users'
          AND column_name = 'payment_provider'
    ) THEN
        ALTER TABLE public.users ADD COLUMN payment_provider TEXT DEFAULT 'gcash';
    END IF;
END $$;

-- 4. Fast lookup index for verified payment accounts
CREATE INDEX IF NOT EXISTS idx_users_payment_verified ON public.users(payment_provider, gcash_verified);

COMMENT ON COLUMN public.users.gcash_verified IS 'True if user phone number ownership has been confirmed via Firebase Phone Auth OTP';
COMMENT ON COLUMN public.users.gcash_verified_at IS 'Timestamp when e-wallet ownership OTP was successfully verified';
COMMENT ON COLUMN public.users.payment_provider IS 'Primary Philippine e-wallet provider (gcash | maya)';
