-- ============================================================
-- SELLER LANDING PAGE - DATABASE MIGRATION
-- Jalankan SQL ini di Supabase Dashboard > SQL Editor
-- ============================================================

-- Update table stores untuk mendukung RajaOngkir
ALTER TABLE stores ADD COLUMN IF NOT EXISTS city_id INT;

-- 1. Tabel sellers
CREATE TABLE IF NOT EXISTS sellers (
  id          BIGSERIAL PRIMARY KEY,
  store_id    UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  slug        TEXT NOT NULL UNIQUE,
  balance     NUMERIC(15, 2) DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Tabel seller_products (katalog produk untuk landing page)
CREATE TABLE IF NOT EXISTS seller_products (
  id          BIGSERIAL PRIMARY KEY,
  seller_id   BIGINT NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  local_product_id BIGINT, -- ID produk dari aplikasi kasir (SQLite)
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  price       NUMERIC(15, 2) NOT NULL,
  stock       INT DEFAULT 0,
  weight      INT DEFAULT 0, -- Berat produk dalam gram
  image_url   TEXT DEFAULT '',
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(seller_id, local_product_id) -- Supaya tidak ada duplikat saat sync
);

-- Pastikan kolom weight ada (jika tabel sudah terlanjur dibuat sebelumnya)
ALTER TABLE seller_products ADD COLUMN IF NOT EXISTS weight INT DEFAULT 0;

-- 3. Tabel seller_orders (pesanan dari landing page)
CREATE TABLE IF NOT EXISTS seller_orders (
  id             BIGSERIAL PRIMARY KEY,
  seller_id      BIGINT NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  customer_name  TEXT DEFAULT '',
  customer_phone TEXT DEFAULT '',
  customer_address TEXT DEFAULT '', -- Alamat pengiriman
  items          JSONB NOT NULL,   -- [{productId, name, qty, price, discount}]
  total_amount   NUMERIC(15, 2) NOT NULL,
  shipping_cost  NUMERIC(15, 2) DEFAULT 0, -- Ongkos kirim
  courier_name   TEXT DEFAULT '',          -- Nama kurir (ex: JNE REG)
  payment_method TEXT DEFAULT 'manual',  -- 'manual' | 'qris'
  status         TEXT DEFAULT 'pending', -- 'pending' | 'paid' | 'cancelled'
  payment_url    TEXT DEFAULT '',        -- URL QRIS dari Duitku
  merchant_order_id TEXT DEFAULT '',     -- Order ID Duitku
  notes          TEXT DEFAULT '',
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

-- Pastikan kolom baru ada
ALTER TABLE seller_orders ADD COLUMN IF NOT EXISTS shipping_cost NUMERIC(15, 2) DEFAULT 0;
ALTER TABLE seller_orders ADD COLUMN IF NOT EXISTS courier_name TEXT DEFAULT '';

-- 4. Index untuk performa query
CREATE INDEX IF NOT EXISTS idx_sellers_slug ON sellers(slug);
CREATE INDEX IF NOT EXISTS idx_seller_products_seller_id ON seller_products(seller_id);
CREATE INDEX IF NOT EXISTS idx_seller_orders_seller_id ON seller_orders(seller_id);
CREATE INDEX IF NOT EXISTS idx_seller_orders_status ON seller_orders(status);
CREATE INDEX IF NOT EXISTS idx_seller_orders_merchant_order_id ON seller_orders(merchant_order_id);

-- 5. Row Level Security (RLS) - public read untuk seller products
ALTER TABLE seller_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE sellers ENABLE ROW LEVEL SECURITY;
ALTER TABLE seller_orders ENABLE ROW LEVEL SECURITY;

-- Policy: siapapun bisa baca seller & produk aktif (untuk landing page publik)
DROP POLICY IF EXISTS "Public read active sellers" ON sellers;
CREATE POLICY "Public read active sellers" ON sellers
  FOR SELECT USING (is_active = TRUE);

DROP POLICY IF EXISTS "Public read active products" ON seller_products;
CREATE POLICY "Public read active products" ON seller_products
  FOR SELECT USING (is_active = TRUE);

-- Service role bisa semua (untuk backend API)
DROP POLICY IF EXISTS "Service role full access sellers" ON sellers;
CREATE POLICY "Service role full access sellers" ON sellers
  FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role full access seller_products" ON seller_products;
CREATE POLICY "Service role full access seller_products" ON seller_products
  FOR ALL USING (auth.role() = 'service_role');

DROP POLICY IF EXISTS "Service role full access seller_orders" ON seller_orders;
CREATE POLICY "Service role full access seller_orders" ON seller_orders
  FOR ALL USING (auth.role() = 'service_role');

-- ============================================================
-- AFFILIATE & REFERRAL SYSTEM
-- ============================================================

-- Tambahkan kolom referred_by ke tabel stores
ALTER TABLE stores ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES stores(id);

-- Buat tabel referral_rewards
CREATE TABLE IF NOT EXISTS referral_rewards (
  id            BIGSERIAL PRIMARY KEY,
  referrer_id   UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  referred_id   UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  amount        NUMERIC(15, 2) NOT NULL,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(referred_id)
);

-- Index untuk performa
CREATE INDEX IF NOT EXISTS idx_stores_referred_by ON stores(referred_by);
CREATE INDEX IF NOT EXISTS idx_referral_rewards_referrer_id ON referral_rewards(referrer_id);

-- Enable RLS untuk tabel referral_rewards
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;

-- Service role full access untuk API backend
DROP POLICY IF EXISTS "Service role full access referral_rewards" ON referral_rewards;
CREATE POLICY "Service role full access referral_rewards" ON referral_rewards
  FOR ALL USING (auth.role() = 'service_role');

