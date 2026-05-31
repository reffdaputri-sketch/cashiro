import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { merchantOrderId, email: clientEmail, store_name: clientStoreName, wa_number: clientWaNumber } = await req.json();
    if (!merchantOrderId) {
      return NextResponse.json({ error: 'merchantOrderId wajib diisi' }, { status: 400 });
    }

    const merchantCode = process.env.DUITKU_MERCHANT_CODE || '';
    const apiKey = process.env.DUITKU_API_KEY || '';

    // Duitku check transaction signature: md5(merchantCode + merchantOrderId + apiKey)
    const signature = crypto
      .createHash('md5')
      .update(merchantCode + merchantOrderId + apiKey)
      .digest('hex');

    // Check transaction status from Duitku
    const checkUrl = 'https://passport.duitku.com/webapi/api/merchant/transactionStatus';
    const checkRes = await fetch(checkUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ merchantCode, merchantOrderId, signature }),
    });

    const checkData = await checkRes.json();
    console.log('[verify-payment] Duitku check response:', checkData);

    if (!checkData || checkData.statusCode !== '00') {
      return NextResponse.json(
        { error: 'Pembayaran belum dikonfirmasi atau gagal', detail: checkData?.statusMessage },
        { status: 400 }
      );
    }

    // Check if license already issued for this order (prevent duplicate)
    const { data: existing } = await supabase
      .from('licenses')
      .select('key, email')
      .eq('merchant_order_id', merchantOrderId)
      .maybeSingle();

    if (existing) {
      // Already processed — return existing key
      return NextResponse.json({
        success: true,
        license_key: existing.key,
        email: existing.email,
        already_issued: true,
      });
    }

    // Parse additionalParam for customer data
    const additionalParam = checkData.additionalParam || '';
    let customerEmail = checkData.email || clientEmail || 'customer@cashiro.app';
    let waNumber = clientWaNumber || '';
    let storeName = clientStoreName || 'Toko Anda';

    if (additionalParam) {
      try {
        const parsed = JSON.parse(additionalParam);
        customerEmail = parsed.email || customerEmail;
        waNumber = parsed.wa_number || waNumber;
        storeName = parsed.store_name || storeName;
      } catch {
        customerEmail = additionalParam;
      }
    }

    // Generate license key
    const rawKey = crypto.randomBytes(4).toString('hex').toUpperCase();
    const licenseKey = `CSH-${rawKey.slice(0, 4)}-${rawKey.slice(4)}`;

    // Save to Supabase
    const { error: insertError } = await supabase
      .from('licenses')
      .insert({
        key: licenseKey,
        email: customerEmail,
        is_used: false,
        merchant_order_id: merchantOrderId,
      });

    if (insertError) {
      console.error('[verify-payment] Supabase insert error:', insertError);
      throw insertError;
    }

    // Send WhatsApp notification
    if (waNumber) {
      try {
        let formattedNumber = waNumber.replace(/\D/g, '');
        if (formattedNumber.startsWith('0')) {
          formattedNumber = '62' + formattedNumber.slice(1);
        } else if (formattedNumber.startsWith('8')) {
          formattedNumber = '62' + formattedNumber;
        }

        const apkLink = 'https://cashiro.web.id/download';
        const waMessage =
          `🎉 *Pembayaran Berhasil!*\n\n` +
          `Terima kasih telah membeli lisensi Cashiro.\n\n` +
          `*Detail Pembelian:*\n` +
          `• Nama Toko: *${storeName}*\n` +
          `• Email: *${customerEmail}*\n\n` +
          `Berikut adalah *Kode Lisensi* Anda:\n` +
          `\`${licenseKey}\`\n\n` +
          `⬇️ *Download Aplikasi Cashiro:*\n${apkLink}\n\n` +
          `Silakan buka aplikasi, pilih "Daftar Toko", lalu masukkan kode lisensi di atas.`;

        const waRes = await fetch('https://serv.kiosly.web.id/send-message', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            number: formattedNumber,
            message: waMessage,
            api_key: 'MEDIKA-SECRET-KEY',
          }),
        });

        const waData = await waRes.json();
        console.log('[verify-payment] WA response:', waData);
      } catch (waErr) {
        console.error('[verify-payment] Gagal kirim WA:', waErr);
        // Non-fatal: license still issued
      }
    }

    return NextResponse.json({
      success: true,
      license_key: licenseKey,
      email: customerEmail,
      store_name: storeName,
      wa_number: waNumber,
    });
  } catch (error: any) {
    console.error('[verify-payment] Error:', error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
