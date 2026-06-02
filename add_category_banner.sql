-- Tambah kolom category ke seller_products
ALTER TABLE seller_products ADD COLUMN IF NOT EXISTS category TEXT DEFAULT '';

-- Tambah kolom banners ke stores (array URL gambar JSON)
ALTER TABLE stores ADD COLUMN IF NOT EXISTS banners JSONB DEFAULT '[]';
