import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const contentType = req.headers.get('content-type') || '';
    let body: any = {};

    if (contentType.includes('application/json')) {
      body = await req.json();
    } else if (contentType.includes('application/x-www-form-urlencoded')) {
      const text = await req.text();
      const params = new URLSearchParams(text);
      params.forEach((value, key) => {
        body[key] = value;
      });
    } else {
      const formData = await req.formData();
      formData.forEach((value, key) => {
        body[key] = value;
      });
    }

    const { merchantCode, amount, merchantOrderId, signature, resultCode, email, additionalParam } = body;
    const apiKey = process.env.DUITKU_API_KEY || '';

    console.log('--- DUKTUI CALLBACK DEBUG ---');
    console.log('Received Body:', body);
    console.log('API Key configured (exists):', !!apiKey);

    // Verify signature: md5(merchantCode + amount + merchantOrderId + apiKey)
    const signatureSource = (merchantCode || '') + (amount || '') + (merchantOrderId || '') + apiKey;
    const localSignature = crypto.createHash('md5').update(signatureSource).digest('hex');

    console.log('Signature Source String:', signatureSource);
    console.log('Local Signature Calculated:', localSignature);
    console.log('Received Signature from Duitku:', signature);

    const isMock = false;
    if (signature !== localSignature) {
      console.error('VERIFICATION ERROR: local signature does not match received signature');
      return new Response('Signature verification failed', { status: 401 });
    }

    // resultCode '00' indicates success
    if (resultCode === '00') {
      let licenseKey: string;
      
      if (isMock) {
        // Match Flutter client-side simulation key generation logic:
        const cleanOrder = (merchantOrderId || '').replace('ORDER-', '');
        const part1 = cleanOrder.substring(0, 4) || '0000';
        const part2 = (merchantOrderId || '').substring((merchantOrderId || '').length - 4) || '0000';
        licenseKey = `CSH-${part1}-${part2}`;
      } else {
        // Generate unique license key (CSH-XXXX-XXXX)
        const rawKey = crypto.randomBytes(4).toString('hex').toUpperCase();
        licenseKey = `CSH-${rawKey.slice(0, 4)}-${rawKey.slice(4)}`;
      }

      // Parse additionalParam
      let customerEmail = email || 'customer@example.com';
      let waNumber = '';
      let storeName = 'Cashiro';

      if (additionalParam) {
        try {
          const parsed = JSON.parse(additionalParam);
          customerEmail = parsed.email || customerEmail;
          waNumber = parsed.wa_number || '';
          storeName = parsed.store_name || storeName;
        } catch (e) {
          // Fallback if not JSON (old format)
          customerEmail = additionalParam;
        }
      }
      // Insert license to Supabase
      const { error } = await supabase
        .from('licenses')
        .insert({
          key: licenseKey,
          email: customerEmail,
          is_used: false,
          merchant_order_id: merchantOrderId
        });

      if (error) throw error;

      // Catat penjualan reseller jika ada reseller_id
      let resellerId: number | null = null;
      let commissionAmount: number = 0;
      let storeName2 = storeName;

      if (additionalParam) {
        try {
          const parsed = JSON.parse(additionalParam);
          resellerId = parsed.reseller_id ? Number(parsed.reseller_id) : null;
          commissionAmount = parsed.commission ? Number(parsed.commission) : 0;
          storeName2 = parsed.store_name || storeName;
        } catch {}
      }

      if (resellerId && commissionAmount > 0) {
        // Buat record penjualan reseller
        const canWithdrawAt = new Date();
        canWithdrawAt.setDate(canWithdrawAt.getDate() + 1); // 1 hari settlement

        await supabase.from('reseller_sales').insert({
          reseller_id: resellerId,
          order_id: merchantOrderId,
          buyer_email: customerEmail,
          buyer_store_name: storeName2,
          sale_price: Number(amount),
          commission: commissionAmount,
          can_withdraw_at: canWithdrawAt.toISOString(),
        });

        // Update balance, total_sales, total_earned reseller
        const { data: currentReseller } = await supabase
          .from('resellers')
          .select('balance, total_sales, total_earned')
          .eq('id', resellerId)
          .single();

        if (currentReseller) {
          await supabase
            .from('resellers')
            .update({
              balance: Number(currentReseller.balance) + commissionAmount,
              total_sales: Number(currentReseller.total_sales) + 1,
              total_earned: Number(currentReseller.total_earned) + commissionAmount,
            })
            .eq('id', resellerId);
        }

        console.log(`Komisi reseller ID ${resellerId}: Rp ${commissionAmount.toLocaleString('id-ID')}`);
      }

      // In real production, send email to customer with the licenseKey here

      // Send WhatsApp message if wa_number exists
      if (waNumber) {
        try {
          let formattedNumber = waNumber.replace(/\D/g, '');
          if (formattedNumber.startsWith('0')) {
            formattedNumber = '62' + formattedNumber.slice(1);
          } else if (formattedNumber.startsWith('8')) {
            formattedNumber = '62' + formattedNumber;
          }

          const apkLink = 'https://cashiro.web.id/download';
          const waMessage = `🎉 *Pembayaran Berhasil!*\n\nTerima kasih telah membeli lisensi Cashiro.\n\n*Detail Pembelian:*\n• Nama Toko: *${storeName}*\n• Email: *${customerEmail}*\n\nBerikut adalah *Kode Lisensi* Anda:\n\`${licenseKey}\`\n\n⬇️ *Download Aplikasi Cashiro:*\n${apkLink}\n\nSilakan buka aplikasi, pilih menu "Daftar Toko", dan masukkan kode lisensi di atas untuk mengaktifkan akun Anda.`;
          
          await fetch('http://localhost:3001/send-message', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
              number: formattedNumber,
              message: waMessage,
              api_key: "MEDIKA-SECRET-KEY"
            })
          });
          console.log(`Pesan WA ke ${formattedNumber} berhasil di-trigger.`);
        } catch (waError) {
          console.error('Gagal menembak WA server:', waError);
        }
      }

      return new Response('OK', { status: 200 });
    }

    return new Response('Payment callback processed (ignored or failed status)', { status: 200 });
  } catch (error: any) {
    return new Response(error.message, { status: 500 });
  }
}
