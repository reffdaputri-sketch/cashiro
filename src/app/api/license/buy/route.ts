import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { email, store_name, payment_method } = await req.json();
    if (!email || !store_name) {
      return NextResponse.json({ error: 'Email dan Nama Toko wajib diisi' }, { status: 400 });
    }

    // Check if email is already registered for another store
    const { data: existingStore } = await supabase
      .from('stores')
      .select('id')
      .eq('email', email.toLowerCase().trim())
      .maybeSingle();

    if (existingStore) {
      return NextResponse.json({ error: 'Email ini sudah terdaftar untuk toko lain' }, { status: 400 });
    }

    const merchantCode = process.env.DUITKU_MERCHANT_CODE || '';
    const apiKey = process.env.DUITKU_API_KEY || '';
    const inquiryUrl = process.env.DUITKU_INQUIRY_URL || 'https://sandbox.duitku.com/webapi/api/merchant/v2/inquiry';
    const merchantOrderId = `ORDER-${Date.now()}`;
    const paymentAmount = 25000; // Harga lisensi Rp 25.000

    // Duitku Signature: md5(merchantCode + merchantOrderId + paymentAmount + apiKey)
    const signatureSource = merchantCode + merchantOrderId + paymentAmount + apiKey;
    const signature = crypto.createHash('md5').update(signatureSource).digest('hex');

    const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';

    const payload = {
      merchantCode,
      paymentAmount,
      merchantOrderId,
      productDetails: `Lisensi Aktivasi Cashiro - ${store_name}`,
      email,
      paymentMethod: payment_method || 'VC', // Duitku V2 requires paymentMethod (e.g. VC = Credit Card, SP = ShopeePay, NQ = QRIS)
      signature,
      callbackUrl: `${appUrl}/api/license/callback`,
      returnUrl: `${appUrl}/payment-success`,
      additionalParam: email, // Pass email in additionalParam so callback can retrieve it
    };

    const response = await fetch(inquiryUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
    });

    const data = await response.json();
    console.log('Duitku payload:', payload);
    console.log('Duitku Response:', data);
    if (data.statusCode === '00') {
      return NextResponse.json({ payment_url: data.paymentUrl, order_id: merchantOrderId });
    } else {
      return NextResponse.json({ error: data.statusMessage || 'Gagal meminta URL Pembayaran dari Duitku' }, { status: 400 });
    }
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
