import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// Simple token: HMAC-SHA256(reseller_id + email, secret)
function generateToken(id: number, email: string): string {
  const secret = process.env.RESELLER_JWT_SECRET || 'reseller-secret-cashiro-2025';
  return crypto.createHmac('sha256', secret).update(`${id}:${email}`).digest('hex');
}

export function verifyToken(token: string, id: number, email: string): boolean {
  return token === generateToken(id, email);
}

// POST /api/reseller/auth → login reseller
export async function POST(req: Request) {
  try {
    const { email, password } = await req.json();
    if (!email || !password) {
      return NextResponse.json({ error: 'Email dan password wajib diisi' }, { status: 400 });
    }

    const { data: reseller, error } = await supabase
      .from('resellers')
      .select('id, name, slug, email, password_hash, sell_price, base_price, balance, total_sales, total_earned, is_active')
      .eq('email', email.trim().toLowerCase())
      .maybeSingle();

    if (error || !reseller) {
      return NextResponse.json({ error: 'Email atau password salah' }, { status: 401 });
    }

    if (!reseller.is_active) {
      return NextResponse.json({ error: 'Akun reseller tidak aktif' }, { status: 403 });
    }

    const valid = await bcrypt.compare(password, reseller.password_hash);
    if (!valid) {
      return NextResponse.json({ error: 'Email atau password salah' }, { status: 401 });
    }

    const token = generateToken(reseller.id, reseller.email);

    return NextResponse.json({
      success: true,
      token,
      reseller: {
        id: reseller.id,
        name: reseller.name,
        slug: reseller.slug,
        email: reseller.email,
        sell_price: reseller.sell_price,
        base_price: reseller.base_price,
        balance: reseller.balance,
        total_sales: reseller.total_sales,
        total_earned: reseller.total_earned,
      },
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
