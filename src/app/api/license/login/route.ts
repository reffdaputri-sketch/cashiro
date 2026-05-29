import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { email, license_key } = await req.json();

    if (!email || !license_key) {
      return NextResponse.json({ error: 'Email dan Kode Lisensi wajib diisi' }, { status: 400 });
    }

    // Check if store matches email and license_key
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .ilike('email', email.trim())
      .eq('license_key', license_key.trim())
      .single();

    if (storeError || !store) {
      return NextResponse.json({ error: 'Email atau kode lisensi salah / belum terdaftar' }, { status: 400 });
    }

    return NextResponse.json({
      success: true,
      store: {
        store_id: store.id,
        store_name: store.store_name,
        owner_name: store.owner_name || 'Pemilik',
        phone: store.phone || '',
        address: store.address || '',
        pin: store.pin || '123456',
        bank_name: store.bank_name || '',
        bank_account: store.bank_account || '',
        bank_account_name: store.bank_account_name || ''
      }
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
