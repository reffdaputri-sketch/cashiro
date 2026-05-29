import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';

// GET /api/sellers/[slug]/referrals - Get referred stores and rewards info
export async function GET(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;

    // 1. Get seller and store ID
    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .select('id, store_id, balance')
      .eq('slug', slug)
      .single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });
    }

    // 2. Query referred stores count & details
    const { data: referredStores, error: refErr } = await supabase
      .from('stores')
      .select('id, store_name, created_at, email')
      .eq('referred_by', seller.store_id)
      .order('created_at', { ascending: false });

    if (refErr) throw refErr;

    // 3. Query rewards transactions list
    const { data: rewards, error: rewErr } = await supabase
      .from('referral_rewards')
      .select('id, amount, created_at, referred:referred_id(store_name)')
      .eq('referrer_id', seller.store_id)
      .order('created_at', { ascending: false });

    if (rewErr) throw rewErr;

    return NextResponse.json({
      success: true,
      balance: seller.balance || 0,
      referred_count: referredStores?.length || 0,
      referred_stores: referredStores || [],
      rewards: rewards || []
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
