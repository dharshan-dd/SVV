-- ============================================
-- ADD ENTRY TYPE SUPPORT
-- ============================================

-- Add entry_type column to daily_collection_entries
ALTER TABLE public.daily_collection_entries
ADD COLUMN IF NOT EXISTS entry_type TEXT NOT NULL DEFAULT 'daily' CHECK (entry_type IN ('daily', 'weekly', 'monthly'));

-- Add unique constraint for weekly/monthly entries
-- For weekly: unique per week start date + region + model + bag
-- For monthly: unique per month start date + region + model + bag
-- We'll keep existing unique constraint for daily entries

-- Create separate tables for weekly and monthly entries
CREATE TABLE IF NOT EXISTS public.weekly_collection_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    week_start_date DATE NOT NULL,
    region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES public.models(id) ON DELETE CASCADE,
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,

    -- Credit Breakdown
    opening_balance DECIMAL(12,2) DEFAULT 0.00,
    collection_cash DECIMAL(12,2) DEFAULT 0.00,
    collection_upi DECIMAL(12,2) DEFAULT 0.00,
    document_charges DECIMAL(12,2) DEFAULT 0.00,

    -- Debit Breakdown
    new_loan_cash DECIMAL(12,2) DEFAULT 0.00,
    new_loan_upi DECIMAL(12,2) DEFAULT 0.00,
    chit_payment DECIMAL(12,2) DEFAULT 0.00,
    misc_expenses DECIMAL(12,2) DEFAULT 0.00,

    -- Calculated Fields
    total_credit DECIMAL(12,2) GENERATED ALWAYS AS (
        opening_balance + collection_cash + collection_upi + document_charges
    ) STORED,

    total_debit DECIMAL(12,2) GENERATED ALWAYS AS (
        new_loan_cash + new_loan_upi + chit_payment + misc_expenses
    ) STORED,

    net_closing_balance DECIMAL(12,2) GENERATED ALWAYS AS (
        opening_balance + collection_cash + collection_upi + document_charges
        - new_loan_cash - new_loan_upi - chit_payment - misc_expenses
    ) STORED,

    UNIQUE(week_start_date, region_id, model_id, bag_id)
);

CREATE TABLE IF NOT EXISTS public.monthly_collection_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    month_start_date DATE NOT NULL,
    region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES public.models(id) ON DELETE CASCADE,
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,

    -- Credit Breakdown
    opening_balance DECIMAL(12,2) DEFAULT 0.00,
    collection_cash DECIMAL(12,2) DEFAULT 0.00,
    collection_upi DECIMAL(12,2) DEFAULT 0.00,
    document_charges DECIMAL(12,2) DEFAULT 0.00,

    -- Debit Breakdown
    new_loan_cash DECIMAL(12,2) DEFAULT 0.00,
    new_loan_upi DECIMAL(12,2) DEFAULT 0.00,
    chit_payment DECIMAL(12,2) DEFAULT 0.00,
    misc_expenses DECIMAL(12,2) DEFAULT 0.00,

    -- Calculated Fields
    total_credit DECIMAL(12,2) GENERATED ALWAYS AS (
        opening_balance + collection_cash + collection_upi + document_charges
    ) STORED,

    total_debit DECIMAL(12,2) GENERATED ALWAYS AS (
        new_loan_cash + new_loan_upi + chit_payment + misc_expenses
    ) STORED,

    net_closing_balance DECIMAL(12,2) GENERATED ALWAYS AS (
        opening_balance + collection_cash + collection_upi + document_charges
        - new_loan_cash - new_loan_upi - chit_payment - misc_expenses
    ) STORED,

    UNIQUE(month_start_date, region_id, model_id, bag_id)
);

-- Indexes for weekly entries
CREATE INDEX IF NOT EXISTS idx_weekly_entries_week_start ON public.weekly_collection_entries(week_start_date);
CREATE INDEX IF NOT EXISTS idx_weekly_entries_region ON public.weekly_collection_entries(region_id);
CREATE INDEX IF NOT EXISTS idx_weekly_entries_model ON public.weekly_collection_entries(model_id);
CREATE INDEX IF NOT EXISTS idx_weekly_entries_bag ON public.weekly_collection_entries(bag_id);
CREATE INDEX IF NOT EXISTS idx_weekly_entries_user ON public.weekly_collection_entries(created_by);

-- Indexes for monthly entries
CREATE INDEX IF NOT EXISTS idx_monthly_entries_month_start ON public.monthly_collection_entries(month_start_date);
CREATE INDEX IF NOT EXISTS idx_monthly_entries_region ON public.monthly_collection_entries(region_id);
CREATE INDEX IF NOT EXISTS idx_monthly_entries_model ON public.monthly_collection_entries(model_id);
CREATE INDEX IF NOT EXISTS idx_monthly_entries_bag ON public.monthly_collection_entries(bag_id);
CREATE INDEX IF NOT EXISTS idx_monthly_entries_user ON public.monthly_collection_entries(created_by);

-- Enable RLS
ALTER TABLE public.weekly_collection_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.monthly_collection_entries ENABLE ROW LEVEL SECURITY;

-- RLS Policies for weekly entries
DROP POLICY IF EXISTS "Allow read own weekly entries for authenticated users" ON public.weekly_collection_entries;
DROP POLICY IF EXISTS "Allow insert weekly entries for authenticated users" ON public.weekly_collection_entries;
DROP POLICY IF EXISTS "Allow update own weekly entries for authenticated users" ON public.weekly_collection_entries;
DROP POLICY IF EXISTS "Allow delete own weekly entries for authenticated users" ON public.weekly_collection_entries;

CREATE POLICY "Allow all weekly_collection_entries" ON public.weekly_collection_entries FOR ALL USING (true);

-- RLS Policies for monthly entries
DROP POLICY IF EXISTS "Allow read own monthly entries for authenticated users" ON public.monthly_collection_entries;
DROP POLICY IF EXISTS "Allow insert monthly entries for authenticated users" ON public.monthly_collection_entries;
DROP POLICY IF EXISTS "Allow update own monthly entries for authenticated users" ON public.monthly_collection_entries;
DROP POLICY IF EXISTS "Allow delete own monthly entries for authenticated users" ON public.monthly_collection_entries;

CREATE POLICY "Allow all monthly_collection_entries" ON public.monthly_collection_entries FOR ALL USING (true);

-- Triggers for timestamps
DROP TRIGGER IF EXISTS handle_weekly_entries_updated_at ON public.weekly_collection_entries;
DROP TRIGGER IF EXISTS handle_monthly_entries_updated_at ON public.monthly_collection_entries;

CREATE TRIGGER handle_weekly_entries_updated_at BEFORE UPDATE ON public.weekly_collection_entries
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_monthly_entries_updated_at BEFORE UPDATE ON public.monthly_collection_entries
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();
