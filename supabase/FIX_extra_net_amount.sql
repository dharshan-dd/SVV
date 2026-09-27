-- ============================================================
-- FIX: "Could not find the 'extra_net_amount' column of
--       'daily_cash_records' in the schema cache" (PGRST204)
--
-- Cause: migrations 016-018 (which add extra_net_amount,
-- the bag_net_amounts table, and deduction_details) were
-- never applied to this Supabase project, so PostgREST's
-- schema cache doesn't know the column exists.
--
-- HOW TO RUN:
--   1. Open your Supabase project -> SQL Editor.
--   2. Paste this entire file and click "Run".
--   3. Retry adding a record in the app.
--
-- This script is idempotent - safe to run even if some or
-- all of it was already applied.
-- ============================================================

-- ---- from 016_add_extra_net_amount.sql ----

ALTER TABLE public.daily_cash_records
ADD COLUMN IF NOT EXISTS extra_net_amount DECIMAL(14,2) DEFAULT 0.00;

CREATE OR REPLACE FUNCTION public.get_latest_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    result DECIMAL(14,2) := 0.00;
BEGIN
    SELECT COALESCE(previous_final_amount + final_amount + COALESCE(extra_net_amount, 0), 0.00)
    INTO result
    FROM public.daily_cash_records
    WHERE bag_id = p_bag_id
      AND entry_date <= p_entry_date
    ORDER BY entry_date DESC, updated_at DESC
    LIMIT 1;

    RETURN result;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_latest_final_amount(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_latest_final_amount(UUID, DATE) TO anon;

CREATE OR REPLACE FUNCTION public.get_previous_day_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    prev_final DECIMAL(14,2) := 0.00;
BEGIN
    SELECT COALESCE(d.final_amount + COALESCE(d.extra_net_amount, 0), 0.00)
    INTO prev_final
    FROM public.daily_cash_records d
    WHERE d.bag_id = p_bag_id
    AND d.entry_date < p_entry_date
    ORDER BY d.entry_date DESC
    LIMIT 1;

    RETURN prev_final;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_previous_day_final_amount(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_previous_day_final_amount(UUID, DATE) TO anon;

CREATE OR REPLACE FUNCTION public.cascade_final_amount()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    running_total DECIMAL(14,2);
BEGIN
    running_total := NEW.previous_final_amount + NEW.final_amount + COALESCE(NEW.extra_net_amount, 0);

    FOR rec IN
        SELECT id
        FROM public.daily_cash_records
        WHERE bag_id = NEW.bag_id
          AND entry_date > NEW.entry_date
        ORDER BY entry_date ASC
    LOOP
        UPDATE public.daily_cash_records
        SET previous_final_amount = running_total
        WHERE id = rec.id
        RETURNING previous_final_amount + final_amount + COALESCE(extra_net_amount, 0) INTO running_total;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.cascade_final_amount() TO authenticated;
GRANT EXECUTE ON FUNCTION public.cascade_final_amount() TO anon;

DROP TRIGGER IF EXISTS trg_set_previous_final_amount ON public.daily_cash_records;

CREATE OR REPLACE FUNCTION public.set_previous_final_amount()
RETURNS TRIGGER AS $$
BEGIN
    SELECT COALESCE(previous_final_amount + final_amount + COALESCE(extra_net_amount, 0), 0.00)
    INTO NEW.previous_final_amount
    FROM public.daily_cash_records
    WHERE bag_id = NEW.bag_id
      AND entry_date < NEW.entry_date
    ORDER BY entry_date DESC
    LIMIT 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_set_previous_final_amount
    BEFORE INSERT OR UPDATE ON public.daily_cash_records
    FOR EACH ROW EXECUTE FUNCTION public.set_previous_final_amount();

DROP TRIGGER IF EXISTS trg_cascade_final_amount ON public.daily_cash_records;
CREATE TRIGGER trg_cascade_final_amount
    AFTER INSERT OR UPDATE ON public.daily_cash_records
    FOR EACH ROW EXECUTE FUNCTION public.cascade_final_amount();

-- ---- from 017_bag_net_amounts_table.sql ----

CREATE TABLE IF NOT EXISTS public.bag_net_amounts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    entry_date DATE NOT NULL,
    amount DECIMAL(14,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    UNIQUE(bag_id, entry_date)
);

CREATE INDEX IF NOT EXISTS idx_bag_net_amounts_bag ON public.bag_net_amounts(bag_id);
CREATE INDEX IF NOT EXISTS idx_bag_net_amounts_date ON public.bag_net_amounts(entry_date);

ALTER TABLE public.bag_net_amounts ENABLE ROW LEVEL SECURITY;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename = 'bag_net_amounts'
          AND policyname = 'Allow all bag_net_amounts'
    ) THEN
        CREATE POLICY "Allow all bag_net_amounts" ON public.bag_net_amounts FOR ALL USING (true);
    END IF;
END $$;

DROP TRIGGER IF EXISTS handle_bag_net_amounts_updated_at ON public.bag_net_amounts;
CREATE TRIGGER handle_bag_net_amounts_updated_at BEFORE UPDATE ON public.bag_net_amounts
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE OR REPLACE FUNCTION public.get_bag_extra_net_amounts(
    p_bag_id UUID,
    p_on_or_before_date DATE
)
RETURNS TABLE (
    entry_date DATE,
    amount DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT n.entry_date, n.amount
    FROM public.bag_net_amounts n
    WHERE n.bag_id = p_bag_id
      AND n.entry_date <= p_on_or_before_date
    ORDER BY n.entry_date;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_bag_extra_net_amounts(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_bag_extra_net_amounts(UUID, DATE) TO anon;

-- ---- from 018_daily_deduction_details.sql ----

ALTER TABLE public.daily_cash_records
ADD COLUMN IF NOT EXISTS deduction_details JSONB NOT NULL DEFAULT '[]'::jsonb;

-- ---- force PostgREST to pick up the schema changes now ----
NOTIFY pgrst, 'reload schema';
