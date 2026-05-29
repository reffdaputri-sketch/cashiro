import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { store_id, license_key, sync_items } = await req.json();

    if (!store_id || !license_key || !sync_items) {
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

    // Upsert items to sync_data table
    for (const item of sync_items) {
      const { entity_type, local_id, payload } = item;
      
      const { error: upsertError } = await supabase
        .from('sync_data')
        .upsert(
          {
            store_id,
            entity_type,
            local_id,
            payload,
            updated_at: new Date().toISOString(),
          },
          { onConflict: 'store_id,entity_type,local_id' }
        );

      if (upsertError) {
        throw new Error(`Gagal menyimpan data sinkronisasi: ${upsertError.message}`);
      }

      // Auto-sync ke Toko Online jika seller sudah aktif
      if (entity_type === 'products') {
        const { data: seller } = await supabase
          .from('sellers')
          .select('id')
          .eq('store_id', store_id)
          .single();

        if (seller) {
          const isOnline = payload.is_online === 1;
          
          if (isOnline) {
            await supabase.from('seller_products').upsert({
              seller_id: seller.id,
              local_product_id: local_id,
              name: payload.name,
              description: payload.category || '',
              price: payload.price,
              stock: payload.stock,
              weight: payload.weight || 0,
              image_url: payload.image_path || '',
              is_active: true,
              updated_at: new Date().toISOString(),
            }, { onConflict: 'seller_id,local_product_id' });
          } else {
            // Nonaktifkan jika is_online = false
            await supabase.from('seller_products')
              .update({ is_active: false })
              .eq('seller_id', seller.id)
              .eq('local_product_id', local_id);
          }
        }
      }
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
