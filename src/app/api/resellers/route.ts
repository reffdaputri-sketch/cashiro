import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

const ADMIN_TOKEN = 'admin-authorized-token-cashiro';

function isAdmin(req: Request) {
  return req.headers.get('Authorization') === ADMIN_TOKEN;
}

// GET /api/resellers → list semua reseller (admin only)
export async function GET(req: Request) {
  if (!isAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const { data, error } = await supabase
    .from('resellers')
    .select('id, name, slug, email, sell_price, base_price, balance, total_sales, total_earned, is_active, created_at')
    .order('created_at', { ascending: false });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ resellers: data });
}

// POST /api/resellers → tambah reseller baru (admin only)
export async function POST(req: Request) {
  if (!isAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  try {
    const { name, slug, email, password, sell_price, base_price } = await req.json();

    if (!name || !slug || !email || !password || !sell_price || !base_price) {
      return NextResponse.json({ error: 'Semua field wajib diisi' }, { status: 400 });
    }

    if (Number(sell_price) <= Number(base_price)) {
      return NextResponse.json({ error: 'Harga jual harus lebih besar dari harga dasar' }, { status: 400 });
    }

    // Cek slug & email sudah ada
    const { data: existing } = await supabase
      .from('resellers')
      .select('id')
      .or(`slug.eq.${slug},email.eq.${email}`)
      .maybeSingle();

    if (existing) {
      return NextResponse.json({ error: 'Slug atau email sudah terdaftar' }, { status: 400 });
    }

    const password_hash = await bcrypt.hash(password, 10);

    const { data, error } = await supabase
      .from('resellers')
      .insert({ name, slug: slug.toLowerCase().replace(/\s+/g, '-'), email, password_hash, sell_price, base_price })
      .select('id, name, slug, email, sell_price, base_price, is_active, created_at')
      .single();

    if (error) throw error;
    return NextResponse.json({ success: true, reseller: data });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
