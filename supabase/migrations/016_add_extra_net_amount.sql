-- ============================================
-- Add extra_net_amount column to daily_cash_records
-- This stores additional net amount that should be added
-- to the final_amount calculation for carry-forward purposes.
-- ============================================

ALTER TABLE public.daily_cash_records 
ADD COLUMN IF NOT EXISTS extra_net_amount DECIMAL(14,2) DEFAULT 0.00;

-- Fix the generated columns to include extra_net_amount
-- Note: PostgreSQL doesn't allow modifying generated columns directly,
-- so we handle the extra_net_amount inclusion client-side instead.

-- Update get_latest_final_amount function to include extra_net_amount
CREATE OR REPLACE FUNCTION public.get_latest_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    result DECIMAL(14,2) := 0.00;
BEGIN
    -- previous_final_amount + final_amount + extra_net_amount of latest record
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

-- Fix get_previous_day_final_amount to include extra_net_amount
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

-- Update cascade trigger function to include extra_net_amount
CREATE OR REPLACE FUNCTION public.cascade_final_amount()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    running_total DECIMAL(14,2);
BEGIN
    -- running_total after this record = previous_final_amount + final_amount + extra_net_amount
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

-- Recreate all triggers since migration 015 dropped them
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
