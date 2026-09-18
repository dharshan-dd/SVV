-- ============================================
-- DATABASE FUNCTIONS FOR ANALYTICS
-- ============================================

-- Daily Summary Function
CREATE OR REPLACE FUNCTION public.get_daily_summary(p_date DATE)
RETURNS TABLE (
    total_credit DECIMAL,
    total_debit DECIMAL,
    net_balance DECIMAL,
    entry_count BIGINT,
    total_collection_cash DECIMAL,
    total_collection_upi DECIMAL,
    total_document_charges DECIMAL,
    total_new_loan_cash DECIMAL,
    total_new_loan_upi DECIMAL,
    total_chit_payment DECIMAL,
    total_misc_expenses DECIMAL
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COALESCE(SUM(total_credit), 0)::DECIMAL as total_credit,
        COALESCE(SUM(total_debit), 0)::DECIMAL as total_debit,
        COALESCE(SUM(net_closing_balance), 0)::DECIMAL as net_balance,
        COUNT(*)::BIGINT as entry_count,
        COALESCE(SUM(collection_cash), 0)::DECIMAL as total_collection_cash,
        COALESCE(SUM(collection_upi), 0)::DECIMAL as total_collection_upi,
        COALESCE(SUM(document_charges), 0)::DECIMAL as total_document_charges,
        COALESCE(SUM(new_loan_cash), 0)::DECIMAL as total_new_loan_cash,
        COALESCE(SUM(new_loan_upi), 0)::DECIMAL as total_new_loan_upi,
        COALESCE(SUM(chit_payment), 0)::DECIMAL as total_chit_payment,
        COALESCE(SUM(misc_expenses), 0)::DECIMAL as total_misc_expenses
    FROM public.daily_collection_entries
    WHERE entry_date = p_date;
END;
$$ LANGUAGE plpgsql;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION public.get_daily_summary(DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_daily_summary(DATE) TO anon;
