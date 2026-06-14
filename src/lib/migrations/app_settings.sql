-- Migration untuk tabel pengaturan aplikasi (app_settings)

CREATE TABLE IF NOT EXISTS public.app_settings (
    id SERIAL PRIMARY KEY,
    apk_url TEXT NOT NULL DEFAULT '/Cashiro.apk',
    app_version TEXT NOT NULL DEFAULT '1.0.0',
    app_size TEXT NOT NULL DEFAULT '128 MB',
    last_updated TEXT NOT NULL DEFAULT '30 Mei 2025',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Hanya akan ada 1 baris (id=1)
INSERT INTO public.app_settings (id, apk_url, app_version, app_size, last_updated)
VALUES (1, '/Cashiro.apk', '1.0.0', '128 MB', '30 Mei 2025')
ON CONFLICT (id) DO NOTHING;

-- Policies (Opsional, jika diaktifkan RLS)
ALTER TABLE public.app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Allow public read access to app_settings"
ON public.app_settings FOR SELECT
USING (true);

-- Untuk update kita akan melakukan bypass menggunakan service_role di API atau kita bisa izinkan khusus jika ada rule
-- Di kasus API kita menggunakan supabase dengan role service / admin panel jadi aman.
