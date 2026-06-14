import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// PATCH /api/sellers/admin - Toggle seller active status
export async function PATCH(req: Request) {
  try {
    // Basic admin auth check (assuming authorization header or we can just rely on the existing admin panel logic)
    const authHeader = req.headers.get('Authorization');
    if (!authHeader || authHeader !== 'admin-authorized-token-cashiro') {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { id, is_active } = await req.json();

    if (!id || typeof is_active !== 'boolean') {
      return NextResponse.json({ error: 'Invalid input' }, { status: 400 });
    }

    const { data, error } = await supabase
      .from('sellers')
      .update({ is_active })
      .eq('id', id)
      .select('id, is_active, slug')
      .single();

    if (error || !data) {
      return NextResponse.json({ error: error?.message || 'Gagal mengubah status toko' }, { status: 500 });
    }

    return NextResponse.json({ success: true, seller: data });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
