import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const email = searchParams.get('email');

    if (!email) {
      return NextResponse.json({ error: 'Email wajib disertakan' }, { status: 400 });
    }

    // Query active un-used license for this email
    const { data: licenses, error } = await supabase
      .from('licenses')
      .select('key')
      .eq('email', email.toLowerCase().trim())
      .eq('is_used', false)
      .order('created_at', { ascending: false });

    if (error || !licenses || licenses.length === 0) {
      return NextResponse.json({ license_key: null });
    }

    // Return the latest license key generated
    return NextResponse.json({ license_key: licenses[0].key });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
