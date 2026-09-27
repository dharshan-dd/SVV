ALTER TABLE public.daily_cash_records
ADD COLUMN IF NOT EXISTS deduction_details JSONB NOT NULL DEFAULT '[]'::jsonb;
