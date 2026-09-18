-- ============================================
-- MICROFINANCE COLLECTION MANAGEMENT SYSTEM
-- Supabase PostgreSQL Schema
-- ============================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLE 1: REGIONS
-- ============================================
CREATE TABLE IF NOT EXISTS public.regions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ============================================
-- TABLE 2: MODELS (Type/Line)
-- ============================================
CREATE TABLE IF NOT EXISTS public.models (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ============================================
-- TABLE 3: COLLECTION BAGS (Area)
-- ============================================
CREATE TABLE IF NOT EXISTS public.collection_bags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL UNIQUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ============================================
-- TABLE 4: BAG CONFIGURATIONS (Admin Settings)
-- ============================================
CREATE TABLE IF NOT EXISTS public.bag_configurations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entity TEXT NOT NULL DEFAULT 'Line',
    region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES public.models(id) ON DELETE CASCADE,
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    frequency TEXT NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(region_id, model_id, bag_id)
);

-- ============================================
-- TABLE 5: DAILY COLLECTION ENTRIES
-- ============================================
CREATE TABLE IF NOT EXISTS public.daily_collection_entries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_date DATE NOT NULL,
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

    UNIQUE(entry_date, region_id, model_id, bag_id)
);

-- ============================================
-- INDEXES FOR PERFORMANCE
-- ============================================
CREATE INDEX IF NOT EXISTS idx_daily_entries_date ON public.daily_collection_entries(entry_date);
CREATE INDEX IF NOT EXISTS idx_daily_entries_region ON public.daily_collection_entries(region_id);
CREATE INDEX IF NOT EXISTS idx_daily_entries_model ON public.daily_collection_entries(model_id);
CREATE INDEX IF NOT EXISTS idx_daily_entries_bag ON public.daily_collection_entries(bag_id);
CREATE INDEX IF NOT EXISTS idx_daily_entries_user ON public.daily_collection_entries(created_by);
CREATE INDEX IF NOT EXISTS idx_bag_config_region ON public.bag_configurations(region_id);
CREATE INDEX IF NOT EXISTS idx_bag_config_model ON public.bag_configurations(model_id);
CREATE INDEX IF NOT EXISTS idx_bag_config_bag ON public.bag_configurations(bag_id);

-- ============================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================

-- Enable RLS
ALTER TABLE public.regions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.models ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.collection_bags ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bag_configurations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_collection_entries ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Allow read regions for authenticated users" ON public.regions;
DROP POLICY IF EXISTS "Allow insert regions for admins" ON public.regions;
DROP POLICY IF EXISTS "Allow update regions for admins" ON public.regions;
DROP POLICY IF EXISTS "Allow delete regions for admins" ON public.regions;

DROP POLICY IF EXISTS "Allow read models for authenticated users" ON public.models;
DROP POLICY IF EXISTS "Allow insert models for admins" ON public.models;
DROP POLICY IF EXISTS "Allow update models for admins" ON public.models;
DROP POLICY IF EXISTS "Allow delete models for admins" ON public.models;

DROP POLICY IF EXISTS "Allow read collection_bags for authenticated users" ON public.collection_bags;
DROP POLICY IF EXISTS "Allow insert collection_bags for admins" ON public.collection_bags;
DROP POLICY IF EXISTS "Allow update collection_bags for admins" ON public.collection_bags;
DROP POLICY IF EXISTS "Allow delete collection_bags for admins" ON public.collection_bags;

DROP POLICY IF EXISTS "Allow read bag_configurations for authenticated users" ON public.bag_configurations;
DROP POLICY IF EXISTS "Allow insert bag_configurations for admins" ON public.bag_configurations;
DROP POLICY IF EXISTS "Allow update bag_configurations for admins" ON public.bag_configurations;
DROP POLICY IF EXISTS "Allow delete bag_configurations for admins" ON public.bag_configurations;

DROP POLICY IF EXISTS "Allow read own entries for authenticated users" ON public.daily_collection_entries;
DROP POLICY IF EXISTS "Allow insert entries for authenticated users" ON public.daily_collection_entries;
DROP POLICY IF EXISTS "Allow update own entries for authenticated users" ON public.daily_collection_entries;
DROP POLICY IF EXISTS "Allow delete own entries for authenticated users" ON public.daily_collection_entries;

-- REGIONS: full access for operational app
CREATE POLICY "Allow all regions" ON public.regions FOR ALL USING (true);

-- MODELS: full access for operational app
CREATE POLICY "Allow all models" ON public.models FOR ALL USING (true);

-- COLLECTION BAGS: full access for operational app
CREATE POLICY "Allow all collection_bags" ON public.collection_bags FOR ALL USING (true);

-- BAG CONFIGURATIONS: full access for operational app
CREATE POLICY "Allow all bag_configurations" ON public.bag_configurations FOR ALL USING (true);

-- DAILY COLLECTION ENTRIES: full access for operational app
CREATE POLICY "Allow all daily_collection_entries" ON public.daily_collection_entries FOR ALL USING (true);

-- ============================================
-- FUNCTIONS & TRIGGERS
-- ============================================

-- Update timestamps on row modification
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc'::text, NOW());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS handle_regions_updated_at ON public.regions;
DROP TRIGGER IF EXISTS handle_models_updated_at ON public.models;
DROP TRIGGER IF EXISTS handle_collection_bags_updated_at ON public.collection_bags;
DROP TRIGGER IF EXISTS handle_bag_configurations_updated_at ON public.bag_configurations;
DROP TRIGGER IF EXISTS handle_daily_collection_entries_updated_at ON public.daily_collection_entries;

CREATE TRIGGER handle_regions_updated_at BEFORE UPDATE ON public.regions
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_models_updated_at BEFORE UPDATE ON public.models
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_collection_bags_updated_at BEFORE UPDATE ON public.collection_bags
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_bag_configurations_updated_at BEFORE UPDATE ON public.bag_configurations
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_daily_collection_entries_updated_at BEFORE UPDATE ON public.daily_collection_entries
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- ============================================
-- SEED DATA (Optional - remove if not needed)
-- ============================================

-- Insert default regions
INSERT INTO public.regions (name) VALUES
    ('Ooty'),
    ('Karur'),
    ('Nagercoil')
ON CONFLICT (name) DO NOTHING;

-- Insert default models
INSERT INTO public.models (name) VALUES
    ('Daily Line'),
    ('Weekly Line'),
    ('Monthly Line')
ON CONFLICT (name) DO NOTHING;

-- Insert default collection bags
INSERT INTO public.collection_bags (name) VALUES
    ('Collection Bag 1'),
    ('Collection Bag 2'),
    ('Collection Bag 3'),
    ('Collection Bag 4'),
    ('Collection Bag 5'),
    ('Collection Bag 6'),
    ('Collection Bag 7'),
    ('Collection Bag 8'),
    ('Collection Bag 9'),
    ('Collection Bag 10')
ON CONFLICT (name) DO NOTHING;
