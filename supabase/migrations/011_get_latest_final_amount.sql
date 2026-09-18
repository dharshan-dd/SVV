-- ============================================
-- Get latest final amount for a bag on or before a given date (inclusive)
-- Used as opening balance when adding a new record on the same day
-- ============================================

CREATE OR REPLACE FUNCTION public.get_latest_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    result DECIMAL(14,2) := 0.00;
BEGIN
    -- Opening balance = previous_final_amount + final_amount of the latest record
    -- because final_amount generated column does NOT include previous_final_amount
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
