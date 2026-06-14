-- Hapus tabel lama jika ada agar tidak bentrok
DROP TABLE IF EXISTS public.web_panel_licenses;

-- Buat tabel licenses baru
CREATE TABLE public.web_panel_licenses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  license_key TEXT UNIQUE NOT NULL,
  registered_domain TEXT,
  status TEXT DEFAULT 'active',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE
);

-- Masukkan lisensi contoh untuk testing
INSERT INTO public.web_panel_licenses (license_key, status) 
VALUES ('KIOSLY-1234-ABCD', 'active')
ON CONFLICT (license_key) DO NOTHING;
