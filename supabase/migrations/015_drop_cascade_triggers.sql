-- ============================================
-- Drop cascade triggers that auto-modify previous_final_amount
-- and cascade changes to subsequent records.
-- App (Flutter) now manages previous_final_amount explicitly.
-- ============================================

DROP TRIGGER IF EXISTS trg_set_previous_final_amount ON public.daily_cash_records;
DROP TRIGGER IF EXISTS trg_cascade_final_amount ON public.daily_cash_records;
DROP FUNCTION IF EXISTS public.set_previous_final_amount();
DROP FUNCTION IF EXISTS public.cascade_final_amount();

-- Update previous_final_amount for ALL existing records
-- to be the true running total (previous record's closing)
UPDATE public.daily_cash_records d
SET previous_final_amount = (
    SELECT COALESCE(p.previous_final_amount + p.final_amount, 0.00)
    FROM public.daily_cash_records p
    WHERE p.bag_id = d.bag_id
      AND p.entry_date < d.entry_date
    ORDER BY p.entry_date DESC
    LIMIT 1
)
WHERE EXISTS (
    SELECT 1 FROM public.daily_cash_records p
    WHERE p.bag_id = d.bag_id
      AND p.entry_date < d.entry_date
);
