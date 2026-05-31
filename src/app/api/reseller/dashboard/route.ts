import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import crypto from 'crypto';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

function verifyToken(token: string, id: number, email: string): boolean {
  const secret = process.env.RESELLER_JWT_SECRET || 'reseller-secret-cashiro-2025';
  const expected = crypto.createHmac('sha256', secret).update(`${id}:${email}`).digest('hex');
  return token === expected;
}

// GET /api/reseller/dashboard?id=<id>&email=<email>
// Header: Authorization: <token>
export async function GET(req: Request) {
  try {
    const url = new URL(req.url);
    const id = Number(url.searchParams.get('id'));
    const email = url.searchParams.get('email') || '';
    const token = req.headers.get('Authorization') || '';

    if (!id || !email || !token || !verifyToken(token, id, email)) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    // Data reseller
    const { data: reseller, error: rErr } = await supabase
      .from('resellers')
      .select('id, name, slug, sell_price, base_price, balance, total_sales, total_earned, is_active')
      .eq('id', id)
      .eq('email', email)
      .maybeSingle();

    if (rErr || !reseller) return NextResponse.json({ error: 'Reseller tidak ditemukan' }, { status: 404 });

    // Riwayat penjualan (max 50 terbaru)
    const { data: sales, error: sErr } = await supabase
      .from('reseller_sales')
      .select('id, order_id, buyer_email, buyer_store_name, sale_price, commission, can_withdraw_at, created_at')
      .eq('reseller_id', id)
      .order('created_at', { ascending: false })
      .limit(50);

    if (sErr) throw sErr;

    // Riwayat withdrawal
    const { data: withdrawals, error: wErr } = await supabase
      .from('reseller_withdrawals')
      .select('id, amount, bank_name, bank_account, bank_holder, status, note, created_at')
      .eq('reseller_id', id)
      .order('created_at', { ascending: false })
      .limit(20);

    if (wErr) throw wErr;

    // Hitung saldo yang sudah bisa ditarik (can_withdraw_at <= NOW())
    const now = new Date();
    const withdrawableSales = (sales || []).filter(s => new Date(s.can_withdraw_at) <= now);
    const withdrawableAmount = withdrawableSales.reduce((sum, s) => sum + Number(s.commission), 0);

    return NextResponse.json({
      reseller,
      sales: sales || [],
      withdrawals: withdrawals || [],
      withdrawable_amount: Math.min(withdrawableAmount, Number(reseller.balance)), // tidak lebih dari balance
    });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
