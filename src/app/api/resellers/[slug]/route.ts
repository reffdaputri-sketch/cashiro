import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

const ADMIN_TOKEN = 'admin-authorized-token-cashiro';

// GET /api/resellers/[slug] → info reseller by slug (untuk checkout page - public)
export async function GET(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;

  const { data, error } = await supabase
    .from('resellers')
    .select('id, name, slug, sell_price, base_price, is_active')
    .eq('slug', slug)
    .eq('is_active', true)
    .maybeSingle();

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  if (!data) return NextResponse.json({ error: 'Reseller tidak ditemukan' }, { status: 404 });

  return NextResponse.json({ reseller: data });
}

// PATCH /api/resellers/[slug] → update reseller (admin only)
export async function PATCH(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  if (req.headers.get('Authorization') !== ADMIN_TOKEN) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
  }

  try {
    const body = await req.json();
    const updates: Record<string, any> = {};

    if (body.sell_price !== undefined) updates.sell_price = body.sell_price;
    if (body.base_price !== undefined) updates.base_price = body.base_price;
    if (body.is_active !== undefined) updates.is_active = body.is_active;
    if (body.name !== undefined) updates.name = body.name;
    if (body.password !== undefined) {
      updates.password_hash = await bcrypt.hash(body.password, 10);
    }

    if (updates.sell_price && updates.base_price && Number(updates.sell_price) <= Number(updates.base_price)) {
      return NextResponse.json({ error: 'Harga jual harus lebih besar dari harga dasar' }, { status: 400 });
    }

    const { data, error } = await supabase
      .from('resellers')
      .update(updates)
      .eq('slug', slug)
      .select('id, name, slug, sell_price, base_price, is_active')
      .single();

    if (error) throw error;
    return NextResponse.json({ success: true, reseller: data });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
