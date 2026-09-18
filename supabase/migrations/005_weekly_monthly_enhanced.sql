-- ============================================
-- WEEKLY/MONTHLY ENTRY SCHEMA UPDATE
-- ============================================

-- Add new columns to weekly_collection_entries for the detailed calculation flow
ALTER TABLE public.weekly_collection_entries
ADD COLUMN IF NOT EXISTS remaining_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS remaining_reason TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS adap_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS rr_gpay_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS additional_collection DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS additional_deduction DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS other_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS final_balance DECIMAL(12,2) GENERATED ALWAYS AS (
    opening_balance 
    + collection_cash + collection_upi + document_charges 
    + remaining_amount + other_amount + additional_collection
    - adap_amount - rr_gpay_amount - additional_deduction
    - new_loan_cash - new_loan_upi - chit_payment - misc_expenses
) STORED;

-- Add new columns to monthly_collection_entries for the detailed calculation flow
ALTER TABLE public.monthly_collection_entries
ADD COLUMN IF NOT EXISTS remaining_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS remaining_reason TEXT DEFAULT '',
ADD COLUMN IF NOT EXISTS adap_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS rr_gpay_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS additional_collection DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS additional_deduction DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS other_amount DECIMAL(12,2) DEFAULT 0.00,
ADD COLUMN IF NOT EXISTS final_balance DECIMAL(12,2) GENERATED ALWAYS AS (
    opening_balance 
    + collection_cash + collection_upi + document_charges 
    + remaining_amount + other_amount + additional_collection
    - adap_amount - rr_gpay_amount - additional_deduction
    - new_loan_cash - new_loan_upi - chit_payment - misc_expenses
) STORED;
