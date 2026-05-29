import { NextResponse } from 'next/server';
import crypto from 'crypto';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// Get both licenses and registered stores
export async function GET(req: Request) {
  try {
    const authHeader = req.headers.get('Authorization');
    if (authHeader !== 'admin-authorized-token-cashiro') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { data: licenses, error: licError } = await supabase
      .from('licenses')
      .select('*')
      .order('created_at', { ascending: false });

    if (licError) throw licError;

    const { data: stores, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .order('created_at', { ascending: false });

    if (storeError) throw storeError;

    return NextResponse.json({ licenses, stores });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// Generate license manually
export async function POST(req: Request) {
  try {
    const authHeader = req.headers.get('Authorization');
    if (authHeader !== 'admin-authorized-token-cashiro') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { email } = await req.json();
    if (!email) {
      return NextResponse.json({ error: 'Email wajib diisi' }, { status: 400 });
    }

    // Generate unique license key (CSH-XXXX-XXXX)
    const rawKey = crypto.randomBytes(4).toString('hex').toUpperCase();
    const licenseKey = `CSH-${rawKey.slice(0, 4)}-${rawKey.slice(4)}`;

    const { data, error } = await supabase
      .from('licenses')
      .insert({ key: licenseKey, email: email.toLowerCase().trim(), is_used: false })
      .select()
      .single();

    if (error) throw error;

    return NextResponse.json({ success: true, license: data });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
