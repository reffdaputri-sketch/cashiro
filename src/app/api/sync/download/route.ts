import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { store_id, license_key } = await req.json();

    if (!store_id || !license_key) {
      return NextResponse.json({ error: 'Data tidak lengkap' }, { status: 400 });
    }

    // Validate that the store is registered and matches license key
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('id')
      .eq('id', store_id)
      .eq('license_key', license_key)
      .single();

    if (storeError || !store) {
      return NextResponse.json({ error: 'Akses tidak sah' }, { status: 401 });
    }

    // Fetch all sync_data records for this store
    const { data: syncData, error: syncError } = await supabase
      .from('sync_data')
      .select('entity_type, local_id, payload')
      .eq('store_id', store_id);

    if (syncError) {
      throw new Error(`Gagal mengambil data sinkronisasi: ${syncError.message}`);
    }

    return NextResponse.json(syncData || []);
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
