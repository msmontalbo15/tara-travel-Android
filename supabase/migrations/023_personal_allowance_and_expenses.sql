-- 023_personal_allowance_and_expenses.sql
-- Personal Allowance and Private Solo Expenses per Trip Member

CREATE TABLE IF NOT EXISTS public.trip_personal_allowances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    total_allowance NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    emergency_buffer_percent NUMERIC(4, 2) NOT NULL DEFAULT 0.10,
    cash_on_hand NUMERIC(12, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT unique_trip_user_allowance UNIQUE (trip_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.personal_expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    description TEXT NOT NULL,
    amount NUMERIC(12, 2) NOT NULL,
    category TEXT NOT NULL DEFAULT 'custom',
    payment_mode TEXT NOT NULL DEFAULT 'cash', -- 'cash' or 'digital'
    date TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Enable Row Level Security
ALTER TABLE public.trip_personal_allowances ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.personal_expenses ENABLE ROW LEVEL SECURITY;

-- Drop legacy/existing policies if re-run
DROP POLICY IF EXISTS "Users can only manage their own trip allowance" ON public.trip_personal_allowances;
DROP POLICY IF EXISTS "Users can only manage their own personal expenses" ON public.personal_expenses;

-- RLS: Strictly private to the individual user
CREATE POLICY "Users can only manage their own trip allowance"
ON public.trip_personal_allowances
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can only manage their own personal expenses"
ON public.personal_expenses
FOR ALL
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);
