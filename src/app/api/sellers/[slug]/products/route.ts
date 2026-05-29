import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// GET /api/sellers/[slug]/products - List produk seller
export async function GET(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;

    const { data: seller } = await supabase
      .from('sellers').select('id').eq('slug', slug).single();
    if (!seller) return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });

    const { data: products, error } = await supabase
      .from('seller_products')
      .select('*')
      .eq('seller_id', seller.id)
      .order('created_at', { ascending: false });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ products: products || [] });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// POST /api/sellers/[slug]/products - Tambah produk baru
export async function POST(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;
    const { store_id, name, description, price, stock, image_url } = await req.json();

    if (!store_id || !name || !price) {
      return NextResponse.json({ error: 'name, price wajib diisi' }, { status: 400 });
    }

    const { data: seller } = await supabase
      .from('sellers')
      .select('id, store_id')
      .eq('slug', slug)
      .eq('store_id', store_id)
      .single();

    if (!seller) return NextResponse.json({ error: 'Akses ditolak' }, { status: 403 });

    const { data: product, error } = await supabase
      .from('seller_products')
      .insert({
        seller_id: seller.id,
        name,
        description: description || '',
        price: Number(price),
        stock: Number(stock) || 0,
        image_url: image_url || '',
        is_active: true,
      })
      .select('*')
      .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, product });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT /api/sellers/[slug]/products - Update produk
export async function PUT(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;
    const { store_id, product_id, name, description, price, stock, image_url, is_active } = await req.json();

    const { data: seller } = await supabase
      .from('sellers')
      .select('id')
      .eq('slug', slug)
      .eq('store_id', store_id)
      .single();

    if (!seller) return NextResponse.json({ error: 'Akses ditolak' }, { status: 403 });

    const updates: Record<string, any> = { updated_at: new Date().toISOString() };
    if (name !== undefined) updates.name = name;
    if (description !== undefined) updates.description = description;
    if (price !== undefined) updates.price = Number(price);
    if (stock !== undefined) updates.stock = Number(stock);
    if (image_url !== undefined) updates.image_url = image_url;
    if (is_active !== undefined) updates.is_active = is_active;

    const { data: product, error } = await supabase
      .from('seller_products')
      .update(updates)
      .eq('id', product_id)
      .eq('seller_id', seller.id)
      .select('*')
      .single();

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ success: true, product });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
