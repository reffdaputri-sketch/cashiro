import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// POST /api/sellers/auth - Login seller, cari slug berdasarkan email + license_key
export async function POST(req: Request) {
  try {
    const { email, license_key } = await req.json();

    if (!email || !license_key) {
      return NextResponse.json({ error: 'Email dan kode lisensi wajib diisi' }, { status: 400 });
    }

    // Verifikasi store
    const { data: store, error: storeErr } = await supabase
      .from('stores')
      .select('id, store_name, owner_name, phone, address')
      .eq('email', email.toLowerCase().trim())
      .eq('license_key', license_key.trim())
      .single();

    if (storeErr || !store) {
      return NextResponse.json({ error: 'Email atau kode lisensi salah' }, { status: 401 });
    }

    // Cari seller yang terhubung dengan store ini
    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .select('id, slug, balance')
      .eq('store_id', store.id)
      .eq('is_active', true)
      .single();

    if (sellerErr || !seller) {
      // Belum punya landing page — otomatis buatkan
      const slug = store.store_name
        .toLowerCase()
        .replace(/[^a-z0-9\s]/g, '')
        .trim()
        .replace(/\s+/g, '-') + '-' + Math.floor(1000 + Math.random() * 9000);

      const { data: newSeller, error: createErr } = await supabase
        .from('sellers')
        .insert({ store_id: store.id, slug, balance: 0, is_active: true })
        .select('id, slug, balance')
        .single();

      if (createErr || !newSeller) {
        return NextResponse.json({ error: 'Gagal membuat landing page' }, { status: 500 });
      }

      return NextResponse.json({
        success: true,
        slug: newSeller.slug,
        seller_id: newSeller.id,
        balance: newSeller.balance,
        store: { store_name: store.store_name, owner_name: store.owner_name, phone: store.phone, address: store.address },
        new_store: true,
      });
    }

    return NextResponse.json({
      success: true,
      slug: seller.slug,
      seller_id: seller.id,
      balance: seller.balance,
      store: { store_name: store.store_name, owner_name: store.owner_name, phone: store.phone, address: store.address },
      new_store: false,
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
