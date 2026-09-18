-- ============================================
-- DAILY CASH RECORDS
-- Day-wise cash/collection record with
-- auditable calculation trail and carry-forward.
-- ============================================

CREATE TABLE IF NOT EXISTS public.daily_cash_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    entry_date DATE NOT NULL,
    region_id UUID NOT NULL REFERENCES public.regions(id) ON DELETE CASCADE,
    model_id UUID NOT NULL REFERENCES public.models(id) ON DELETE CASCADE,
    bag_id UUID NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),

    -- Inputs
    net_amount_in_hand DECIMAL(14,2) DEFAULT 0.00,
    collected_amount DECIMAL(14,2) DEFAULT 0.00,
    remaining_amount DECIMAL(14,2) DEFAULT 0.00,
    remaining_reason TEXT DEFAULT '',
    document_fees DECIMAL(14,2) DEFAULT 0.00,

    -- Calculated fields
    total_amount DECIMAL(14,2) GENERATED ALWAYS AS (
        net_amount_in_hand + collected_amount + remaining_amount + document_fees
    ) STORED,

    adap_amount DECIMAL(14,2) DEFAULT 0.00,
    amount_after_adap DECIMAL(14,2) GENERATED ALWAYS AS (
        (net_amount_in_hand + collected_amount + remaining_amount + document_fees) - adap_amount
    ) STORED,

    rr_gpay_amount DECIMAL(14,2) DEFAULT 0.00,
    amount_after_gpay DECIMAL(14,2) GENERATED ALWAYS AS (
        (net_amount_in_hand + collected_amount + remaining_amount + document_fees) - adap_amount - rr_gpay_amount
    ) STORED,

    expense DECIMAL(14,2) DEFAULT 0.00,
    final_amount DECIMAL(14,2) GENERATED ALWAYS AS (
        (net_amount_in_hand + collected_amount + remaining_amount + document_fees) - adap_amount - rr_gpay_amount - expense
    ) STORED,

    additional_collection DECIMAL(14,2) DEFAULT 0.00,
    additional_deduction DECIMAL(14,2) DEFAULT 0.00,
    other_amount DECIMAL(14,2) DEFAULT 0.00,

    previous_final_amount DECIMAL(14,2) DEFAULT 0.00,

    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,

    UNIQUE(entry_date, region_id, model_id, bag_id)
);

CREATE INDEX IF NOT EXISTS idx_daily_cash_records_bag ON public.daily_cash_records(bag_id);
CREATE INDEX IF NOT EXISTS idx_daily_cash_records_date ON public.daily_cash_records(entry_date);
CREATE INDEX IF NOT EXISTS idx_daily_cash_records_week ON public.daily_cash_records(week_start_date);
CREATE INDEX IF NOT EXISTS idx_daily_cash_records_day ON public.daily_cash_records(day_of_week);

ALTER TABLE public.daily_cash_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow all daily_cash_records" ON public.daily_cash_records FOR ALL USING (true);

CREATE TRIGGER handle_daily_cash_records_updated_at BEFORE UPDATE ON public.daily_cash_records
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Function to get previous day's final amount for a bag
CREATE OR REPLACE FUNCTION public.get_previous_day_final_amount(
    p_bag_id UUID,
    p_entry_date DATE
)
RETURNS DECIMAL AS $$
DECLARE
    prev_final DECIMAL(14,2) := 0.00;
BEGIN
    SELECT COALESCE(d.final_amount, 0.00)
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
