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

    const { merchantCode, amount, merchantOrderId, signature, resultCode, email } = body;
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
      
      const customerEmail = email || 'customer@example.com';

      // Insert license to Supabase
      const { error } = await supabase
        .from('licenses')
        .insert({ key: licenseKey, email: customerEmail, is_used: false });

      if (error) throw error;

      // In real production, send email to customer with the licenseKey here

      return new Response('OK', { status: 200 });
    }

    return new Response('Payment callback processed (ignored or failed status)', { status: 200 });
  } catch (error: any) {
    return new Response(error.message, { status: 500 });
  }
}
