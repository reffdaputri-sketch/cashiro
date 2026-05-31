import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

const ADMIN_TOKEN = 'admin-authorized-token-cashiro';

function isAdmin(req: Request) {
  return req.headers.get('Authorization') === ADMIN_TOKEN;
}

// GET /api/resellers/withdrawals/admin?status=pending
export async function GET(req: Request) {
  if (!isAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  const url = new URL(req.url);
  const status = url.searchParams.get('status') || 'pending';

  const { data, error } = await supabase
    .from('reseller_withdrawals')
    .select('*, resellers(name, slug, email)')
    .eq('status', status)
    .order('created_at', { ascending: false });

  if (error) return NextResponse.json({ error: error.message }, { status: 500 });
  return NextResponse.json({ requests: data });
}

// PATCH /api/resellers/withdrawals/admin → approve / reject
export async function PATCH(req: Request) {
  if (!isAdmin(req)) return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });

  try {
    const { id, action, note } = await req.json();
    if (!id || !action) return NextResponse.json({ error: 'id dan action wajib diisi' }, { status: 400 });

    // Ambil withdrawal
    const { data: wd, error: wErr } = await supabase
      .from('reseller_withdrawals')
      .select('*')
      .eq('id', id)
      .eq('status', 'pending')
      .maybeSingle();

    if (wErr || !wd) return NextResponse.json({ error: 'Permintaan tidak ditemukan atau sudah diproses' }, { status: 404 });

    if (action === 'approved') {
      // Kurangi balance reseller
      const { error: balErr } = await supabase.rpc('decrement_reseller_balance', {
        p_reseller_id: wd.reseller_id,
        p_amount: wd.amount,
      });

      // Fallback jika RPC belum ada: update manual
      if (balErr) {
        const { data: res } = await supabase
          .from('resellers')
          .select('balance')
          .eq('id', wd.reseller_id)
          .single();

        await supabase
          .from('resellers')
          .update({ balance: Math.max(0, Number(res?.balance || 0) - Number(wd.amount)) })
          .eq('id', wd.reseller_id);
      }
    }

    // Update status withdrawal
    const { error: updErr } = await supabase
      .from('reseller_withdrawals')
      .update({ status: action, note: note || '' })
      .eq('id', id);

    if (updErr) throw updErr;

    return NextResponse.json({ success: true, message: action === 'approved' ? 'Penarikan disetujui' : 'Penarikan ditolak' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
