-- ============================================
-- CASCADE FINAL AMOUNT
-- When a daily_cash_record is saved/updated,
-- propagate its final_amount as previous_final_amount
-- to all subsequent records for the same bag.
-- ============================================

-- BEFORE trigger: set previous_final_amount from actual previous day's record
CREATE OR REPLACE FUNCTION public.set_previous_final_amount()
RETURNS TRIGGER AS $$
BEGIN
    SELECT COALESCE(final_amount, 0.00)
    INTO NEW.previous_final_amount
    FROM public.daily_cash_records
    WHERE bag_id = NEW.bag_id
      AND entry_date < NEW.entry_date
    ORDER BY entry_date DESC
    LIMIT 1;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_set_previous_final_amount ON public.daily_cash_records;

CREATE TRIGGER trg_set_previous_final_amount
    BEFORE INSERT OR UPDATE ON public.daily_cash_records
    FOR EACH ROW
    EXECUTE FUNCTION public.set_previous_final_amount();

-- AFTER trigger: cascade this row's final_amount forward to all subsequent days
CREATE OR REPLACE FUNCTION public.cascade_final_amount()
RETURNS TRIGGER AS $$
DECLARE
    rec RECORD;
    running_final DECIMAL(14,2);
BEGIN
    running_final := NEW.final_amount;

    FOR rec IN
        SELECT id
        FROM public.daily_cash_records
        WHERE bag_id = NEW.bag_id
          AND entry_date > NEW.entry_date
        ORDER BY entry_date ASC
    LOOP
        UPDATE public.daily_cash_records
        SET previous_final_amount = running_final
        WHERE id = rec.id
        RETURNING final_amount INTO running_final;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_cascade_final_amount ON public.daily_cash_records;

CREATE TRIGGER trg_cascade_final_amount
    AFTER INSERT OR UPDATE ON public.daily_cash_records
    FOR EACH ROW
    EXECUTE FUNCTION public.cascade_final_amount();
