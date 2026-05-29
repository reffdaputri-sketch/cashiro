import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// POST /api/sellers/[slug]/login - Login seller dengan email + license_key
export async function POST(req: Request, { params }: { params: { slug: string } }) {
  try {
    const { email, license_key } = await req.json();

    if (!email || !license_key) {
      return NextResponse.json({ error: 'Email dan kode lisensi wajib diisi' }, { status: 400 });
    }

    // Verifikasi store berdasarkan email + license_key
    const { data: store, error: storeErr } = await supabase
      .from('stores')
      .select('id, store_name, owner_name, phone, address')
      .eq('email', email.toLowerCase().trim())
      .eq('license_key', license_key.trim())
      .single();

    if (storeErr || !store) {
      return NextResponse.json({ error: 'Email atau kode lisensi salah' }, { status: 401 });
    }

    // Ambil seller berdasarkan store_id + slug
    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .select('id, slug, balance')
      .eq('store_id', store.id)
      .eq('slug', params.slug)
      .single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: 'Landing page ini bukan milik toko Anda' }, { status: 403 });
    }

    return NextResponse.json({
      success: true,
      seller_id: seller.id,
      slug: seller.slug,
      balance: seller.balance,
      store: {
        store_name: store.store_name,
        owner_name: store.owner_name,
        phone: store.phone,
        address: store.address,
      },
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
