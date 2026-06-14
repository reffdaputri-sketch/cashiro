import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// GET /api/settings/app - Public endpoint untuk mengambil pengaturan aplikasi (download link dsb)
export async function GET() {
  try {
    const { data, error } = await supabase
      .from('app_settings')
      .select('apk_url, app_version, app_size, last_updated')
      .eq('id', 1)
      .single();

    // Jika tabel belum ada atau error, kembalikan nilai default agar frontend tidak crash
    if (error || !data) {
      return NextResponse.json({
        settings: {
          apk_url: '/Cashiro.apk',
          app_version: '1.0.0',
          app_size: '128 MB',
          last_updated: '30 Mei 2025'
        }
      });
    }

    return NextResponse.json({ settings: data });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PATCH /api/settings/app - Admin endpoint untuk mengubah pengaturan aplikasi
export async function PATCH(req: Request) {
  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || authHeader !== 'admin-authorized-token-cashiro') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { apk_url, app_version, app_size, last_updated } = await req.json();

    const { data, error } = await supabase
      .from('app_settings')
      .update({
        apk_url,
        app_version,
        app_size,
        last_updated,
        updated_at: new Date().toISOString()
      })
      .eq('id', 1)
      .select()
      .single();

    if (error || !data) {
      return NextResponse.json({ error: error?.message || 'Gagal menyimpan pengaturan' }, { status: 500 });
    }

    return NextResponse.json({ success: true, settings: data });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
