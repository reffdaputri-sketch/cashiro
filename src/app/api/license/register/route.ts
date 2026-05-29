import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { license_key, email, store_name, owner_name, phone, address, pin } = await req.json();

    if (!license_key || !email || !store_name) {
      return NextResponse.json({ error: 'Data tidak lengkap' }, { status: 400 });
    }

    // 1. Get the license info
    const { data: license, error: licError } = await supabase
      .from('licenses')
      .select('*')
      .eq('key', license_key)
      .single();

    if (licError || !license) {
      return NextResponse.json({ error: 'Lisensi tidak ditemukan atau tidak valid' }, { status: 400 });
    }

    if (license.is_used) {
      return NextResponse.json({ error: 'Lisensi sudah digunakan oleh toko lain' }, { status: 400 });
    }

    // Verify email matches the purchase email (case-insensitive)
    if (license.email.toLowerCase() !== email.toLowerCase()) {
      return NextResponse.json({ error: 'Email pendaftaran tidak cocok dengan email pembelian lisensi ini' }, { status: 400 });
    }

    // 2. Insert the store
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .insert({
        email,
        store_name,
        license_key,
        owner_name: owner_name || 'Pemilik',
        phone: phone || '',
        address: address || '',
        pin: pin || ''
      })
      .select('*')
      .single();

    if (storeError || !store) {
      return NextResponse.json({ error: storeError?.message || 'Gagal mendaftarkan toko baru' }, { status: 500 });
    }

    // 3. Mark the license as used
    const { error: updateError } = await supabase
      .from('licenses')
      .update({ is_used: true })
      .eq('key', license_key);

    if (updateError) {
      // Rollback or ignore? Let's throw to be safe
      throw new Error(`Gagal memperbarui status lisensi: ${updateError.message}`);
    }

    return NextResponse.json({ success: true, store_id: store.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
