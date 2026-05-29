import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { store_id, license_key, store_name, owner_name, phone, address, pin, city_id } = await req.json();

    if (!store_id || !license_key) {
      return NextResponse.json({ error: 'Store ID dan License Key wajib diisi' }, { status: 400 });
    }

    // 1. Verify store exists and matches the license key
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .eq('id', store_id)
      .eq('license_key', license_key)
      .single();

    if (storeError || !store) {
      return NextResponse.json({ error: 'Validasi toko atau lisensi gagal' }, { status: 401 });
    }

    // 2. Prepare update payload
    const updateData: any = {};
    if (store_name !== undefined) updateData.store_name = store_name;
    if (owner_name !== undefined) updateData.owner_name = owner_name;
    if (phone !== undefined) updateData.phone = phone;
    if (address !== undefined) updateData.address = address;
    if (pin !== undefined && pin !== null && pin !== '') updateData.pin = pin;
    if (city_id !== undefined) updateData.city_id = city_id;

    if (Object.keys(updateData).length === 0) {
      return NextResponse.json({ success: true, message: 'Tidak ada perubahan yang dikirim' });
    }

    // 3. Update in Supabase
    const { error: updateError } = await supabase
      .from('stores')
      .update(updateData)
      .eq('id', store_id);

    if (updateError) {
      throw updateError;
    }

    return NextResponse.json({ success: true, message: 'Profil toko berhasil diperbarui di cloud' });
  } catch (error: any) {
    console.error('Update profile error:', error);
    return NextResponse.json({ error: error.message || 'Gagal memperbarui profil toko di cloud' }, { status: 500 });
  }
}
