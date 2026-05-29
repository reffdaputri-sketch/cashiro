-- Migration: Buat tabel withdrawal_requests untuk penarikan saldo referral
-- Jalankan di Supabase SQL Editor

CREATE TABLE IF NOT EXISTS withdrawal_requests (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id      UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  seller_id     UUID REFERENCES sellers(id) ON DELETE SET NULL,
  seller_slug   TEXT,
  type          TEXT NOT NULL DEFAULT 'referral' CHECK (type IN ('referral', 'seller')),
  amount        NUMERIC(15, 2) NOT NULL CHECK (amount > 0),
  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected')),
  note          TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  processed_at  TIMESTAMPTZ
);

-- Index untuk query cepat by status
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_status ON withdrawal_requests(status);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_store_id ON withdrawal_requests(store_id);
CREATE INDEX IF NOT EXISTS idx_withdrawal_requests_type ON withdrawal_requests(type);

-- Pastikan kolom balance ada di tabel sellers (saldo referral)
ALTER TABLE sellers ADD COLUMN IF NOT EXISTS balance NUMERIC(15, 2) NOT NULL DEFAULT 0;
