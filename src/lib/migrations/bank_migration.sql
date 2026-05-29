-- ============================================================
-- ADD BANK DETAILS TO STORES TABLE
-- Jalankan SQL ini di Supabase Dashboard > SQL Editor
-- ============================================================

ALTER TABLE stores ADD COLUMN IF NOT EXISTS bank_name TEXT DEFAULT '';
ALTER TABLE stores ADD COLUMN IF NOT EXISTS bank_account TEXT DEFAULT '';
ALTER TABLE stores ADD COLUMN IF NOT EXISTS bank_account_name TEXT DEFAULT '';
