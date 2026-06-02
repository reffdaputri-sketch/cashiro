-- Menambahkan kolom pengaturan kurir lokal ke tabel stores
ALTER TABLE stores
ADD COLUMN IF NOT EXISTS is_local_courier_active BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS local_courier_fee NUMERIC DEFAULT 0;
