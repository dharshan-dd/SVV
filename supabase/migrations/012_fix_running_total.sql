-- ============================================
-- FIX: previous_final_amount stores the FULL running total from previous record
-- (i.e. previous record's previous_final_amount + previous record's final_amount)
-- So opening balance for next entry = just previous_final_amount of latest record
-- ============================================

-- Fix get_latest_final_amount: opening balance = previous_final_amount of latest record
-- (which already IS the full running total up to that point)
CREATE OR REPLACE FUNCTION public.get_latest_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    result DECIMAL(14,2) := 0.00;
BEGIN
    -- previous_final_amount of the latest record = full running total before that record
    -- So opening balance for a new entry = previous_final_amount + final_amount of latest record
    SELECT COALESCE(previous_final_amount + final_amount, 0.00)
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

-- Fix BEFORE trigger: set previous_final_amount = full running total of previous record
-- (previous record's previous_final_amount + previous record's final_amount)
CREATE OR REPLACE FUNCTION public.set_previous_final_amount()
RETURNS TRIGGER AS $$
BEGIN
    SELECT COALESCE(previous_final_amount + final_amount, 0.00)
    INTO NEW.previous_final_amount
    FROM public.daily_cash_records
    WHERE bag_id = NEW.bag_id
      AND entry_date < NEW.entry_date
    ORDER BY entry_date DESC
    LIMIT 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Fix cascade AFTER trigger: propagate full running total forward
CREATE OR REPLACE FUNCTION public.cascade_final_amount()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    running_total DECIMAL(14,2);
BEGIN
    -- running_total after this record = its previous_final_amount + its final_amount
    running_total := NEW.previous_final_amount + NEW.final_amount;

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
        RETURNING previous_final_amount + final_amount INTO running_total;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
