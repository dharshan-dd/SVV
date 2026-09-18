-- ============================================
-- UPDATE get_daily_summary RPC
-- Query daily_cash_records instead of daily_collection_entries
-- Return field names expected by the dashboard UI
-- ============================================

CREATE OR REPLACE FUNCTION public.get_daily_summary(p_date DATE)
RETURNS TABLE (
    total_final_amount DECIMAL,
    total_collected DECIMAL,
    total_expense DECIMAL,
    total_adap_amount DECIMAL,
    total_document_fees DECIMAL,
    total_remaining DECIMAL,
    total_amount DECIMAL,
    entry_count BIGINT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(d.final_amount), 0)::DECIMAL as total_final_amount,
        COALESCE(SUM(d.collected_amount), 0)::DECIMAL as total_collected,
        COALESCE(SUM(d.expense), 0)::DECIMAL as total_expense,
        COALESCE(SUM(d.adap_amount), 0)::DECIMAL as total_adap_amount,
        COALESCE(SUM(d.document_fees), 0)::DECIMAL as total_document_fees,
        COALESCE(SUM(d.remaining_amount), 0)::DECIMAL as total_remaining,
        COALESCE(SUM(d.total_amount), 0)::DECIMAL as total_amount,
        COUNT(*)::BIGINT as entry_count
    FROM public.daily_cash_records d
    WHERE d.entry_date = p_date;
END;
$$ LANGUAGE plpgsql;

GRANT EXECUTE ON FUNCTION public.get_daily_summary(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_summary(DATE) TO anon;
