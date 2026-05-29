-- ============================================================
-- SELLER LANDING PAGE - DATABASE MIGRATION
-- Jalankan SQL ini di Supabase Dashboard > SQL Editor
-- ============================================================

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
  name        TEXT NOT NULL,
  description TEXT DEFAULT '',
  price       NUMERIC(15, 2) NOT NULL,
  stock       INT DEFAULT 0,
  image_url   TEXT DEFAULT '',
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Tabel seller_orders (pesanan dari landing page)
CREATE TABLE IF NOT EXISTS seller_orders (
  id             BIGSERIAL PRIMARY KEY,
  seller_id      BIGINT NOT NULL REFERENCES sellers(id) ON DELETE CASCADE,
  customer_name  TEXT DEFAULT '',
  customer_phone TEXT DEFAULT '',
  items          JSONB NOT NULL,   -- [{productId, name, qty, price, discount}]
  total_amount   NUMERIC(15, 2) NOT NULL,
  payment_method TEXT DEFAULT 'manual',  -- 'manual' | 'qris'
  status         TEXT DEFAULT 'pending', -- 'pending' | 'paid' | 'cancelled'
  payment_url    TEXT DEFAULT '',        -- URL QRIS dari Duitku
  merchant_order_id TEXT DEFAULT '',     -- Order ID Duitku
  notes          TEXT DEFAULT '',
  created_at     TIMESTAMPTZ DEFAULT NOW(),
  updated_at     TIMESTAMPTZ DEFAULT NOW()
);

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
CREATE POLICY "Public read active sellers" ON sellers
  FOR SELECT USING (is_active = TRUE);

CREATE POLICY "Public read active products" ON seller_products
  FOR SELECT USING (is_active = TRUE);

-- Service role bisa semua (untuk backend API)
CREATE POLICY "Service role full access sellers" ON sellers
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access seller_products" ON seller_products
  FOR ALL USING (auth.role() = 'service_role');

CREATE POLICY "Service role full access seller_orders" ON seller_orders
  FOR ALL USING (auth.role() = 'service_role');
