-- ============================================================
-- RESELLER SYSTEM - DATABASE MIGRATION
-- Jalankan SQL ini di Supabase Dashboard > SQL Editor
-- ============================================================

-- 1. Tabel utama reseller
CREATE TABLE IF NOT EXISTS resellers (
  id            BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL,                          -- Nama reseller
  slug          TEXT NOT NULL UNIQUE,                   -- Slug unik untuk link checkout (?ref=slug)
  email         TEXT NOT NULL UNIQUE,                   -- Email untuk login reseller
  password_hash TEXT NOT NULL,                          -- bcrypt hash password
  sell_price    NUMERIC(15, 2) NOT NULL,                -- Harga jual ke pembeli (custom per reseller)
  base_price    NUMERIC(15, 2) NOT NULL DEFAULT 25000,  -- Harga dasar (bisa diubah admin)
  balance       NUMERIC(15, 2) DEFAULT 0,               -- Saldo komisi siap ditarik
  total_sales   INT DEFAULT 0,                          -- Total lisensi terjual
  total_earned  NUMERIC(15, 2) DEFAULT 0,               -- Total komisi pernah didapat (all-time)
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Riwayat penjualan per reseller
CREATE TABLE IF NOT EXISTS reseller_sales (
  id               BIGSERIAL PRIMARY KEY,
  reseller_id      BIGINT NOT NULL REFERENCES resellers(id) ON DELETE CASCADE,
  order_id         TEXT NOT NULL UNIQUE,           -- merchant_order_id dari Duitku
  buyer_email      TEXT NOT NULL,
  buyer_store_name TEXT DEFAULT '',
  sale_price       NUMERIC(15, 2) NOT NULL,        -- Harga yang dibayar pembeli
  commission       NUMERIC(15, 2) NOT NULL,        -- Komisi reseller = sale_price - base_price
  can_withdraw_at  TIMESTAMPTZ NOT NULL,            -- Boleh tarik setelah 1 hari (settlement)
  created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Request penarikan komisi reseller
CREATE TABLE IF NOT EXISTS reseller_withdrawals (
  id           BIGSERIAL PRIMARY KEY,
  reseller_id  BIGINT NOT NULL REFERENCES resellers(id) ON DELETE CASCADE,
  amount       NUMERIC(15, 2) NOT NULL,
  bank_name    TEXT DEFAULT '',
  bank_account TEXT DEFAULT '',
  bank_holder  TEXT DEFAULT '',
  status       TEXT DEFAULT 'pending',   -- 'pending' | 'approved' | 'rejected'
  note         TEXT DEFAULT '',          -- Catatan dari admin saat reject
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Index untuk performa
CREATE INDEX IF NOT EXISTS idx_resellers_slug         ON resellers(slug);
CREATE INDEX IF NOT EXISTS idx_resellers_email        ON resellers(email);
CREATE INDEX IF NOT EXISTS idx_reseller_sales_rid     ON reseller_sales(reseller_id);
CREATE INDEX IF NOT EXISTS idx_reseller_sales_orderid ON reseller_sales(order_id);
CREATE INDEX IF NOT EXISTS idx_reseller_wd_rid        ON reseller_withdrawals(reseller_id);
CREATE INDEX IF NOT EXISTS idx_reseller_wd_status     ON reseller_withdrawals(status);

-- 5. Row Level Security
ALTER TABLE resellers             ENABLE ROW LEVEL SECURITY;
ALTER TABLE reseller_sales        ENABLE ROW LEVEL SECURITY;
ALTER TABLE reseller_withdrawals  ENABLE ROW LEVEL SECURITY;

-- Service role full access (untuk API backend)
DROP POLICY IF EXISTS "Service role full access resellers"            ON resellers;
CREATE POLICY "Service role full access resellers" ON resellers
  FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role full access reseller_sales"       ON reseller_sales;
CREATE POLICY "Service role full access reseller_sales" ON reseller_sales
  FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role full access reseller_withdrawals" ON reseller_withdrawals;
CREATE POLICY "Service role full access reseller_withdrawals" ON reseller_withdrawals
  FOR ALL USING (auth.role() = 'service_role');
