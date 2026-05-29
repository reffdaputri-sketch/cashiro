import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// Helper: generate slug unik dari nama toko
function generateSlug(name: string): string {
  const base = name
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, '')
    .trim()
    .replace(/\s+/g, '-');
  const suffix = Math.floor(1000 + Math.random() * 9000); // 4 digit random
  return `${base}-${suffix}`;
}

// POST /api/sellers - Buat seller baru dari store_id
export async function POST(req: Request) {
  try {
    const { store_id } = await req.json();

    if (!store_id) {
      return NextResponse.json({ error: 'store_id wajib diisi' }, { status: 400 });
    }

    // Cek apakah store ada
    const { data: store, error: storeErr } = await supabase
      .from('stores')
      .select('id, store_name')
      .eq('id', store_id)
      .single();

    if (storeErr || !store) {
      return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });
    }

    // Cek apakah seller sudah ada untuk store ini
    const { data: existingSeller } = await supabase
      .from('sellers')
      .select('id, slug')
      .eq('store_id', store_id)
      .maybeSingle();

    if (existingSeller) {
      return NextResponse.json({ success: true, slug: existingSeller.slug, seller_id: existingSeller.id });
    }

    // Generate slug unik
    let slug = generateSlug(store.store_name);
    let attempts = 0;
    while (attempts < 5) {
      const { data: existing } = await supabase.from('sellers').select('id').eq('slug', slug).maybeSingle();
      if (!existing) break;
      slug = generateSlug(store.store_name);
      attempts++;
    }

    // Insert seller baru
    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .insert({ store_id, slug, balance: 0, is_active: true })
      .select('id, slug')
      .single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: sellerErr?.message || 'Gagal membuat seller' }, { status: 500 });
    }

    return NextResponse.json({ success: true, slug: seller.slug, seller_id: seller.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// GET /api/sellers - List semua sellers (admin)
export async function GET() {
  try {
    const { data, error } = await supabase
      .from('sellers')
      .select('id, slug, balance, is_active, created_at, stores(store_name)')
      .order('created_at', { ascending: false });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ sellers: data });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
