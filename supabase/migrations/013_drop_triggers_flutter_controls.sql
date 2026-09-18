-- Drop triggers that override previous_final_amount
-- Flutter will manage opening balance correctly
DROP TRIGGER IF EXISTS trg_set_previous_final_amount ON public.daily_cash_records;
DROP TRIGGER IF EXISTS trg_cascade_final_amount ON public.daily_cash_records;
DROP FUNCTION IF EXISTS public.set_previous_final_amount();
DROP FUNCTION IF EXISTS public.cascade_final_amount();

-- Simple function: get the true closing amount of the latest record for a bag on or before a date
-- true closing = previous_final_amount + final_amount (since final_amount generated col excludes it)
CREATE OR REPLACE FUNCTION public.get_latest_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    result DECIMAL(14,2) := 0.00;
BEGIN
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
