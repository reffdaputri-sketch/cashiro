import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// POST /api/withdrawals/referral/request
// Body: { storeId: string, amount: number }
export async function POST(req: Request) {
  try {
    const { storeId, amount } = await req.json();

    if (!storeId || typeof amount !== 'number') {
      return NextResponse.json({ error: 'storeId dan amount wajib diisi' }, { status: 400 });
    }

    if (amount < 50000) {
      return NextResponse.json(
        { error: 'Minimum penarikan referral adalah Rp 50.000' },
        { status: 400 }
      );
    }

    // Ambil seller berdasarkan store_id
    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .select('id, slug, balance, store_id')
      .eq('store_id', storeId)
      .single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: 'Seller tidak ditemukan' }, { status: 404 });
    }

    const currentBalance = seller.balance || 0;

    if (amount > currentBalance) {
      return NextResponse.json(
        { error: `Saldo tidak cukup. Saldo saat ini: Rp ${currentBalance.toLocaleString('id-ID')}` },
        { status: 400 }
      );
    }

    // Cek apakah ada permintaan pending yang belum diproses
    const { data: existingPending } = await supabase
      .from('withdrawal_requests')
      .select('id')
      .eq('store_id', storeId)
      .eq('type', 'referral')
      .eq('status', 'pending')
      .single();

    if (existingPending) {
      return NextResponse.json(
        { error: 'Masih ada permintaan penarikan yang sedang menunggu persetujuan admin' },
        { status: 400 }
      );
    }

    // Buat permintaan penarikan
    const { data: request, error: insertErr } = await supabase
      .from('withdrawal_requests')
      .insert({
        store_id: storeId,
        seller_id: seller.id,
        seller_slug: seller.slug,
        type: 'referral',
        amount,
        status: 'pending',
        created_at: new Date().toISOString(),
      })
      .select()
      .single();

    if (insertErr) throw insertErr;

    return NextResponse.json({
      success: true,
      message: 'Permintaan penarikan telah dikirim. Menunggu persetujuan admin.',
      request_id: request.id,
    });
  } catch (error: any) {
    console.error('withdrawal request error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
