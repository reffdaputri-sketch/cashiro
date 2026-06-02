import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// GET /api/sellers/[slug] - Ambil data publik seller (untuk landing page)
export async function GET(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;

    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .select('id, slug, balance, stores(store_name, owner_name, phone, address, city_id, bank_name, bank_account, bank_account_name, qris_payload)')
      .eq('slug', slug)
      .eq('is_active', true)
      .single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });
    }

    const { data: products } = await supabase
      .from('seller_products')
      .select('id, name, description, price, stock, weight, image_url')
      .eq('seller_id', seller.id)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    const storeData = (seller as any).stores || {};

    return NextResponse.json({
      seller: {
        slug: seller.slug,
        store_name: storeData.store_name || slug,
        owner_name: storeData.owner_name || '',
        phone: storeData.phone || '',
        address: storeData.address || '',
        city_id: storeData.city_id || null,
        bank_name: storeData.bank_name || '',
        bank_account: storeData.bank_account || '',
        bank_account_name: storeData.bank_account_name || '',
        qris_payload: storeData.qris_payload || null,
      },
      products: products || [],
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PATCH /api/sellers/[slug] - Update slug seller
export async function PATCH(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;
    const { new_slug } = await req.json();

    if (!new_slug || typeof new_slug !== 'string') {
      return NextResponse.json({ error: 'Slug baru harus diisi' }, { status: 400 });
    }

    const formattedSlug = new_slug.toLowerCase().replace(/[^a-z0-9-]/g, '-').replace(/-+/g, '-').replace(/^-|-$/g, '');

    if (formattedSlug.length < 3) {
      return NextResponse.json({ error: 'Slug minimal 3 karakter' }, { status: 400 });
    }

    // Check if new slug exists
    const { data: existing } = await supabase
      .from('sellers')
      .select('id')
      .eq('slug', formattedSlug)
      .single();

    if (existing) {
      return NextResponse.json({ error: 'Link (slug) sudah digunakan, silakan pilih yang lain' }, { status: 400 });
    }

    const { data: seller, error: updateErr } = await supabase
      .from('sellers')
      .update({ slug: formattedSlug })
      .eq('slug', slug)
      .select('slug')
      .single();

    if (updateErr || !seller) {
      return NextResponse.json({ error: 'Gagal memperbarui link toko' }, { status: 500 });
    }

    return NextResponse.json({ success: true, slug: seller.slug });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
