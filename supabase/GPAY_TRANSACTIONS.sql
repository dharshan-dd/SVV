-- GPAY_TRANSACTIONS.sql
-- Run this in the Supabase SQL Editor. Idempotent and safe to re-run.
-- Creates itemised GPay transactions table, RLS, replace_gpay_transactions function, and bag_gpay_summary view.

CREATE TABLE IF NOT EXISTS public.gpay_transactions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  daily_cash_record_id uuid NOT NULL REFERENCES public.daily_cash_records(id) ON DELETE CASCADE,
  bag_id uuid NOT NULL REFERENCES public.collection_bags(id) ON DELETE CASCADE,
  region_id uuid NOT NULL,
  model_id uuid NOT NULL,
  entry_date date NOT NULL,
  amount numeric(14,2) NOT NULL CHECK (amount > 0),
  payer_name text,
  reference text,
  note text,
  method text NOT NULL DEFAULT 'gpay' CHECK (method IN ('gpay','phonepe','paytm','bank','rr','other')),
  received_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid DEFAULT auth.uid(),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gpay_transactions_bag_date ON public.gpay_transactions(bag_id, entry_date);
CREATE INDEX IF NOT EXISTS idx_gpay_transactions_record ON public.gpay_transactions(daily_cash_record_id);
CREATE INDEX IF NOT EXISTS idx_gpay_transactions_reference ON public.gpay_transactions(reference) WHERE reference IS NOT NULL;

ALTER TABLE public.gpay_transactions ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow all on gpay_transactions" ON public.gpay_transactions;
CREATE POLICY "Allow all on gpay_transactions" ON public.gpay_transactions FOR ALL USING (true) WITH CHECK (true);

CREATE OR REPLACE FUNCTION public.replace_gpay_transactions(p_record_id uuid, p_items jsonb)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  rec RECORD;
  item JSONB;
  v_sum numeric(14,2) := 0;
BEGIN
  SELECT id, bag_id, region_id, model_id, entry_date, rr_gpay_amount
    INTO rec
  FROM public.daily_cash_records
  WHERE id = p_record_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'DAILY_CASH_RECORD_NOT_FOUND';
  END IF;

  DELETE FROM public.gpay_transactions WHERE daily_cash_record_id = p_record_id;

  IF p_items IS NOT NULL AND jsonb_array_length(p_items) > 0 THEN
    FOR item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
      v_sum := v_sum + COALESCE((item->>'amount')::numeric, 0);
      INSERT INTO public.gpay_transactions(daily_cash_record_id, bag_id, region_id, model_id, entry_date, amount, payer_name, reference, note, method, received_at)
      VALUES (rec.id, rec.bag_id, rec.region_id, rec.model_id, rec.entry_date, COALESCE((item->>'amount')::numeric, 0), NULLIF(item->>'payer_name',''), NULLIF(item->>'reference',''), NULLIF(item->>'note',''), COALESCE(NULLIF(item->>'method',''),'gpay'), COALESCE((item->>'received_at')::timestamptz, now()));
    END LOOP;
  END IF;

  IF ABS(v_sum - COALESCE(rec.rr_gpay_amount, 0)) > 0.01 THEN
    RAISE EXCEPTION 'GPAY_SUM_MISMATCH';
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.replace_gpay_transactions(uuid, jsonb) TO authenticated, anon;

CREATE OR REPLACE VIEW public.bag_gpay_summary AS
SELECT dcr.bag_id, dcr.region_id, dcr.model_id, dcr.entry_date, COALESCE(SUM(dcr.rr_gpay_amount), 0) AS record_gpay_total, COALESCE(SUM(gt.amount), 0) AS itemised_total, COALESCE(SUM(dcr.rr_gpay_amount), 0) - COALESCE(SUM(gt.amount), 0) AS unitemised_total, COUNT(DISTINCT gt.id) AS payment_count
FROM public.daily_cash_records dcr
LEFT JOIN public.gpay_transactions gt ON gt.daily_cash_record_id = dcr.id
GROUP BY dcr.bag_id, dcr.region_id, dcr.model_id, dcr.entry_date;