import { NextResponse } from 'next/server';
import crypto from 'crypto';

export async function POST(req: Request) {
  try {
    const { email, store_name, payment_method } = await req.json();
    if (!email || !store_name) {
      return NextResponse.json({ error: 'Email dan Nama Toko wajib diisi' }, { status: 400 });
    }

    const merchantCode = process.env.DUITKU_MERCHANT_CODE || '';
    const apiKey = process.env.DUITKU_API_KEY || '';
    const inquiryUrl = process.env.DUITKU_INQUIRY_URL || 'https://sandbox.duitku.com/webapi/api/merchant/v2/inquiry';
    const merchantOrderId = `ORDER-${Date.now()}`;
    const paymentAmount = 50000; // Harga lisensi Rp 50.000

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
