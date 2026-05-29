import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// GET /api/sellers/[slug] - Info seller + katalog produk (publik)
export async function GET(req: Request, { params }: { params: { slug: string } }) {
  try {
    const { slug } = params;

    const { data: seller, error } = await supabase
      .from('sellers')
      .select(`
        id, slug, balance, is_active, created_at,
        stores(store_name, owner_name, phone, address)
      `)
      .eq('slug', slug)
      .eq('is_active', true)
      .single();

    if (error || !seller) {
      return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });
    }

    // Ambil produk aktif
    const { data: products } = await supabase
      .from('seller_products')
      .select('id, name, description, price, stock, image_url')
      .eq('seller_id', seller.id)
      .eq('is_active', true)
      .order('created_at', { ascending: false });

    return NextResponse.json({
      seller: {
        slug: seller.slug,
        store_name: (seller as any).stores?.store_name,
        owner_name: (seller as any).stores?.owner_name,
        phone: (seller as any).stores?.phone,
        address: (seller as any).stores?.address,
      },
      products: products || [],
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
