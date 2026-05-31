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

// POST /api/reseller/withdraw → request penarikan komisi
export async function POST(req: Request) {
  try {
    const { reseller_id, email, bank_name, bank_account, bank_holder, amount } = await req.json();
    const token = req.headers.get('Authorization') || '';

    if (!reseller_id || !email || !token || !verifyToken(token, reseller_id, email)) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    if (!bank_name || !bank_account || !bank_holder) {
      return NextResponse.json({ error: 'Informasi rekening bank wajib diisi' }, { status: 400 });
    }

    if (!amount || Number(amount) < 10000) {
      return NextResponse.json({ error: 'Minimum penarikan Rp 10.000' }, { status: 400 });
    }

    // Ambil data reseller + cek balance
    const { data: reseller, error: rErr } = await supabase
      .from('resellers')
      .select('id, balance')
      .eq('id', reseller_id)
      .eq('is_active', true)
      .maybeSingle();

    if (rErr || !reseller) return NextResponse.json({ error: 'Reseller tidak ditemukan' }, { status: 404 });

    // Hitung saldo yang benar-benar sudah bisa ditarik (settlement 1 hari)
    const now = new Date().toISOString();
    const { data: settledSales } = await supabase
      .from('reseller_sales')
      .select('commission')
      .eq('reseller_id', reseller_id)
      .lte('can_withdraw_at', now);

    const settledBalance = (settledSales || []).reduce((sum, s) => sum + Number(s.commission), 0);
    const availableBalance = Math.min(settledBalance, Number(reseller.balance));

    // Cek ada pending withdrawal sebelumnya
    const { data: pendingWd } = await supabase
      .from('reseller_withdrawals')
      .select('id')
      .eq('reseller_id', reseller_id)
      .eq('status', 'pending')
      .maybeSingle();

    if (pendingWd) {
      return NextResponse.json({ error: 'Masih ada permintaan penarikan yang sedang diproses' }, { status: 400 });
    }

    if (Number(amount) > availableBalance) {
      return NextResponse.json({
        error: `Saldo yang bisa ditarik hanya Rp ${availableBalance.toLocaleString('id-ID')} (saldo lain masih dalam masa settlement 1x24 jam)`,
      }, { status: 400 });
    }

    // Buat withdrawal request
    const { data: wd, error: wErr } = await supabase
      .from('reseller_withdrawals')
      .insert({
        reseller_id,
        amount: Number(amount),
        bank_name,
        bank_account,
        bank_holder,
        status: 'pending',
      })
      .select()
      .single();

    if (wErr) throw wErr;

    return NextResponse.json({ success: true, withdrawal: wd, message: 'Permintaan penarikan berhasil dikirim, admin akan memproses dalam 1x24 jam' });
  } catch (err: any) {
    return NextResponse.json({ error: err.message }, { status: 500 });
  }
}
