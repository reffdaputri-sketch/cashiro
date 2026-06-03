-- Menambahkan kolom order_type dan table_number ke tabel seller_orders
ALTER TABLE seller_orders
ADD COLUMN IF NOT EXISTS order_type TEXT DEFAULT 'delivery',
ADD COLUMN IF NOT EXISTS table_number TEXT;
