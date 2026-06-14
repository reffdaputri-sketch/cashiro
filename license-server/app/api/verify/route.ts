import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase Client
// In production, these should be in your .env.local
const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY || '';

const supabase = createClient(supabaseUrl, supabaseServiceKey);

export async function POST(request: Request) {
  try {
    const { licenseKey, domain } = await request.json();

    if (!licenseKey) {
      return NextResponse.json({ status: 'invalid', message: 'License key is required' }, { status: 400 });
    }

    // Optional: Check if a secret token matches to ensure requests only come from your app
    const appToken = request.headers.get('x-app-token');
    if (appToken !== 'kiosly-secret-token') {
      return NextResponse.json({ status: 'invalid', message: 'Unauthorized request origin' }, { status: 401 });
    }

    // Query the database for the license
    const { data: license, error } = await supabase
      .from('web_panel_licenses')
      .select('*')
      .eq('license_key', licenseKey)
      .single();

    if (error || !license) {
      return NextResponse.json({ status: 'invalid', message: 'License not found' }, { status: 404 });
    }

    // Check if license is active
    if (license.status !== 'active') {
      return NextResponse.json({ status: 'invalid', message: 'License is suspended or inactive' }, { status: 403 });
    }

    // Check expiration date if applicable
    if (license.expires_at) {
      const expirationDate = new Date(license.expires_at);
      if (expirationDate < new Date()) {
        return NextResponse.json({ status: 'invalid', message: 'License has expired' }, { status: 403 });
      }
    }

    // Domain binding logic
    // If domain is not registered yet, bind it to the first domain that uses it
    if (!license.registered_domain) {
      // Bind to this domain
      await supabase
        .from('web_panel_licenses')
        .update({ registered_domain: domain })
        .eq('id', license.id);
    } else {
      // If it has a registered domain, ensure it matches the request domain
      // In development environments like localhost, you might want to skip domain checking
      const isLocalhost = domain.includes('localhost') || domain.includes('127.0.0.1');
      if (!isLocalhost && license.registered_domain !== domain) {
        return NextResponse.json({ status: 'invalid', message: 'License used on unauthorized domain' }, { status: 403 });
      }
    }

    return NextResponse.json({ status: 'valid', message: 'License is valid' });
  } catch (error) {
    console.error('API Error:', error);
    return NextResponse.json({ status: 'error', message: 'Internal server error' }, { status: 500 });
  }
}
