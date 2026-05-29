import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';
import crypto from 'crypto';

// POST /api/sellers/[slug]/orders/callback - Callback Duitku setelah pembayaran QRIS
export async function POST(req: Request, { params }: { params: { slug: string } }) {
  try {
    const body = await req.formData().catch(() => null);
    let merchantOrderId: string;
    let resultCode: string;

    if (body) {
      merchantOrderId = body.get('merchantOrderId') as string;
      resultCode = body.get('resultCode') as string;
    } else {
      const json = await req.json();
      merchantOrderId = json.merchantOrderId;
      resultCode = json.resultCode;
    }

    if (resultCode !== '00') {
      return NextResponse.json({ message: 'Pembayaran gagal atau pending' });
    }

    // Update order menjadi paid
    const { data: order, error: orderErr } = await supabase
      .from('seller_orders')
      .update({ status: 'paid', updated_at: new Date().toISOString() })
      .eq('merchant_order_id', merchantOrderId)
      .select('seller_id, total_amount')
      .single();

    if (orderErr || !order) {
      return NextResponse.json({ error: 'Order tidak ditemukan' }, { status: 404 });
    }

    // Tambahkan saldo seller
    const { data: seller } = await supabase
      .from('sellers')
      .select('balance')
      .eq('id', order.seller_id)
      .single();

    await supabase
      .from('sellers')
      .update({ balance: (seller?.balance || 0) + order.total_amount })
      .eq('id', order.seller_id);

    return NextResponse.json({ message: 'OK' });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
