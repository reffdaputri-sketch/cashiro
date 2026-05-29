-- ============================================================
-- SEED DATA UNTUK TESTING SELLER LANDING PAGE
-- Jalankan di Supabase Dashboard > SQL Editor
-- Jalankan SETELAH seller_migration.sql berhasil
-- ============================================================

-- Step 1: Insert toko sample ke tabel stores
INSERT INTO stores (
  store_name, email, license_key, owner_name, phone, address, pin
) VALUES (
  'Toko Sample Cashiro',
  'test@cashiro.com',
  'TEST-LICENSE-001',
  'Budi Santoso',
  '08123456789',
  'Jl. Contoh No. 1, Jakarta',
  '123456'
)
ON CONFLICT DO NOTHING;

-- Step 2: Ambil store_id yang baru dibuat (untuk dipakai di bawah)
-- Jalankan ini dulu untuk lihat UUID-nya:
SELECT id, store_name, email FROM stores WHERE email = 'test@cashiro.com';

-- ============================================================
-- SETELAH DAPAT UUID dari query di atas,
-- ganti 'PASTE_UUID_DISINI' di bawah dengan UUID tersebut
-- ============================================================

-- Step 3: Insert seller (landing page) untuk toko tersebut
INSERT INTO sellers (store_id, slug, balance, is_active)
VALUES (
  (SELECT id FROM stores WHERE email = 'test@cashiro.com' LIMIT 1),
  'toko-sample-cashiro',
  0,
  true
)
ON CONFLICT DO NOTHING;

-- Step 4: Insert produk-produk sample
INSERT INTO seller_products (seller_id, name, description, price, stock, image_url, is_active)
VALUES
  (
    (SELECT id FROM sellers WHERE slug = 'toko-sample-cashiro' LIMIT 1),
    'Kopi Arabica Premium',
    'Kopi pilihan dari dataran tinggi Aceh, aroma kuat dan rasa smooth',
    35000,
    50,
    'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400',
    true
  ),
  (
    (SELECT id FROM sellers WHERE slug = 'toko-sample-cashiro' LIMIT 1),
    'Teh Hijau Organik',
    'Teh hijau segar tanpa pestisida, cocok untuk kesehatan',
    25000,
    30,
    'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=400',
    true
  ),
  (
    (SELECT id FROM sellers WHERE slug = 'toko-sample-cashiro' LIMIT 1),
    'Snack Keripik Tempe',
    'Keripik tempe renyah buatan rumahan, berbagai rasa',
    15000,
    100,
    'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=400',
    true
  ),
  (
    (SELECT id FROM sellers WHERE slug = 'toko-sample-cashiro' LIMIT 1),
    'Madu Hutan Asli',
    'Madu murni langsung dari sarang lebah hutan Kalimantan',
    75000,
    20,
    'https://images.unsplash.com/photo-1558642452-9d2a7deb7f62?w=400',
    true
  ),
  (
    (SELECT id FROM sellers WHERE slug = 'toko-sample-cashiro' LIMIT 1),
    'Sambal Bajak Homemade',
    'Sambal pedas manis buatan sendiri, tahan 2 minggu di kulkas',
    20000,
    5,
    'https://images.unsplash.com/photo-1607301405752-71263df54bd5?w=400',
    true
  ),
  (
    (SELECT id FROM sellers WHERE slug = 'toko-sample-cashiro' LIMIT 1),
    'Brownies Cokelat',
    'Brownies cokelat lembut dan moist, bisa custom rasa',
    45000,
    0,
    'https://images.unsplash.com/photo-1607920593519-de0b1b5b5f85?w=400',
    true
  )
ON CONFLICT DO NOTHING;

-- Step 5: Verifikasi data berhasil dibuat
SELECT 
  s.slug,
  st.store_name,
  st.email,
  COUNT(sp.id) as total_produk,
  s.balance
FROM sellers s
JOIN stores st ON s.store_id = st.id
LEFT JOIN seller_products sp ON sp.seller_id = s.id
WHERE s.slug = 'toko-sample-cashiro'
GROUP BY s.slug, st.store_name, st.email, s.balance;
