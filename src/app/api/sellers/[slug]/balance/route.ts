import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// PATCH /api/sellers/[slug]/balance - Kredit/debit saldo seller (internal)
export async function PATCH(req: Request, { params }: { params: { slug: string } }) {
  try {
    const { amount, secret } = await req.json();

    // Validasi sederhana dengan secret key internal
    if (secret !== process.env.INTERNAL_API_SECRET) {
      return NextResponse.json({ error: 'Akses ditolak' }, { status: 403 });
    }

    if (typeof amount !== 'number') {
      return NextResponse.json({ error: 'amount harus berupa angka' }, { status: 400 });
    }

    const { data: seller } = await supabase
      .from('sellers')
      .select('id, balance')
      .eq('slug', params.slug)
      .single();

    if (!seller) return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });

    const newBalance = (seller.balance || 0) + amount;
    await supabase.from('sellers').update({ balance: newBalance }).eq('id', seller.id);

    return NextResponse.json({ success: true, new_balance: newBalance });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// GET /api/sellers/[slug]/balance - Cek saldo seller
export async function GET(req: Request, { params }: { params: { slug: string } }) {
  try {
    const { data: seller } = await supabase
      .from('sellers')
      .select('balance')
      .eq('slug', params.slug)
      .single();

    if (!seller) return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });
    return NextResponse.json({ balance: seller.balance });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
