import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

const ADMIN_TOKEN = 'admin-authorized-token-cashiro';

function checkAdmin(req: Request) {
  const token = req.headers.get('Authorization') || '';
  return token === ADMIN_TOKEN;
}

// GET /api/withdrawals/referral/admin - Ambil semua withdrawal requests (admin)
export async function GET(req: Request) {
  if (!checkAdmin(req)) {
    return NextResponse.json({ error: 'Akses ditolak' }, { status: 403 });
  }

  try {
    const url = new URL(req.url);
    const status = url.searchParams.get('status') || 'pending';

    const { data, error } = await supabase
      .from('withdrawal_requests')
      .select(`
        id,
        store_id,
        seller_id,
        seller_slug,
        type,
        amount,
        status,
        note,
        created_at,
        processed_at,
        stores (store_name, owner_name, email, phone)
      `)
      .eq('type', 'referral')
      .eq('status', status)
      .order('created_at', { ascending: false });

    if (error) throw error;

    return NextResponse.json({ requests: data || [] });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PATCH /api/withdrawals/referral/admin - Approve atau Reject request (admin)
// Body: { id: string, action: 'approved' | 'rejected', note?: string }
export async function PATCH(req: Request) {
  if (!checkAdmin(req)) {
    return NextResponse.json({ error: 'Akses ditolak' }, { status: 403 });
  }

  try {
    const { id, action, note } = await req.json();

    if (!id || !['approved', 'rejected'].includes(action)) {
      return NextResponse.json({ error: 'id dan action (approved/rejected) wajib diisi' }, { status: 400 });
    }

    // Ambil detail request
    const { data: request, error: reqErr } = await supabase
      .from('withdrawal_requests')
      .select('*')
      .eq('id', id)
      .single();

    if (reqErr || !request) {
      return NextResponse.json({ error: 'Permintaan tidak ditemukan' }, { status: 404 });
    }

    if (request.status !== 'pending') {
      return NextResponse.json(
        { error: `Permintaan sudah diproses dengan status: ${request.status}` },
        { status: 400 }
      );
    }

    // Jika approve: kurangi saldo referral seller
    if (action === 'approved') {
      const { data: seller, error: sellerErr } = await supabase
        .from('sellers')
        .select('id, balance')
        .eq('id', request.seller_id)
        .single();

      if (sellerErr || !seller) {
        return NextResponse.json({ error: 'Seller tidak ditemukan' }, { status: 404 });
      }

      const currentBalance = seller.balance || 0;
      if (request.amount > currentBalance) {
        return NextResponse.json(
          { error: 'Saldo seller tidak mencukupi untuk di-approve' },
          { status: 400 }
        );
      }

      const newBalance = currentBalance - request.amount;
      const { error: updateErr } = await supabase
        .from('sellers')
        .update({ balance: newBalance })
        .eq('id', seller.id);

      if (updateErr) throw updateErr;
    }

    // Update status withdrawal request
    const { error: statusErr } = await supabase
      .from('withdrawal_requests')
      .update({
        status: action,
        note: note || null,
        processed_at: new Date().toISOString(),
      })
      .eq('id', id);

    if (statusErr) throw statusErr;

    return NextResponse.json({
      success: true,
      message: action === 'approved' ? 'Penarikan telah disetujui dan saldo dikurangi.' : 'Penarikan telah ditolak.',
    });
  } catch (error: any) {
    console.error('withdrawal admin PATCH error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
