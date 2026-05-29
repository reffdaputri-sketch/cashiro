import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// POST /api/withdrawals/referral/request
// Body: { storeId: string, slug: string, amount: number, bankName?: string, bankAccount?: string, bankAccountName?: string }
export async function POST(req: Request) {
  try {
    const { storeId, slug, amount, bankName, bankAccount, bankAccountName } = await req.json();

    if ((!storeId && !slug) || typeof amount !== 'number') {
      return NextResponse.json({ error: 'storeId atau slug, dan amount wajib diisi' }, { status: 400 });
    }

    if (amount < 50000) {
      return NextResponse.json(
        { error: 'Minimum penarikan referral adalah Rp 50.000' },
        { status: 400 }
      );
    }

    // Ambil seller berdasarkan store_id atau slug
    let sellerQuery = supabase.from('sellers').select('id, slug, balance, store_id');
    if (storeId) {
      sellerQuery = sellerQuery.eq('store_id', storeId);
    } else {
      sellerQuery = sellerQuery.eq('slug', slug);
    }
    
    const { data: seller, error: sellerErr } = await sellerQuery.single();

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
      .eq('store_id', seller.store_id)
      .eq('type', 'referral')
      .eq('status', 'pending')
      .single();

    if (existingPending) {
      return NextResponse.json(
        { error: 'Masih ada permintaan penarikan yang sedang menunggu persetujuan admin' },
        { status: 400 }
      );
    }

    // Update info rekening bank di store jika diinputkan
    if (bankName || bankAccount || bankAccountName) {
      const updateData: any = {};
      if (bankName) updateData.bank_name = bankName;
      if (bankAccount) updateData.bank_account = bankAccount;
      if (bankAccountName) updateData.bank_account_name = bankAccountName;

      await supabase
        .from('stores')
        .update(updateData)
        .eq('id', seller.store_id);
    }

    // Buat permintaan penarikan
    const { data: request, error: insertErr } = await supabase
      .from('withdrawal_requests')
      .insert({
        store_id: seller.store_id,
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

// GET /api/withdrawals/referral/request
// Query params: storeId or slug
export async function GET(req: Request) {
  try {
    const url = new URL(req.url);
    const storeId = url.searchParams.get('storeId');
    const slug = url.searchParams.get('slug');

    if (!storeId && !slug) {
      return NextResponse.json({ error: 'storeId atau slug wajib diisi' }, { status: 400 });
    }

    let sellerQuery = supabase.from('sellers').select('id, store_id');
    if (storeId) {
      sellerQuery = sellerQuery.eq('store_id', storeId);
    } else {
      sellerQuery = sellerQuery.eq('slug', slug);
    }
    const { data: seller, error: sellerErr } = await sellerQuery.single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: 'Seller tidak ditemukan' }, { status: 404 });
    }

    const { data: requests, error: reqErr } = await supabase
      .from('withdrawal_requests')
      .select('*')
      .eq('store_id', seller.store_id)
      .eq('type', 'referral')
      .order('created_at', { ascending: false });

    if (reqErr) throw reqErr;

    return NextResponse.json({ requests: requests || [] });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
