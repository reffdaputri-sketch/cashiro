import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

export async function POST(req: Request) {
  try {
    const { license_key, email, store_name, owner_name, phone, address, pin, referral_code } = await req.json();

    if (!license_key || !email || !store_name) {
      return NextResponse.json({ error: 'Data tidak lengkap' }, { status: 400 });
    }

    // 1. Get the license info
    const { data: license, error: licError } = await supabase
      .from('licenses')
      .select('*')
      .eq('key', license_key)
      .single();

    if (licError || !license) {
      return NextResponse.json({ error: 'Lisensi tidak ditemukan atau tidak valid' }, { status: 400 });
    }

    if (license.is_used) {
      return NextResponse.json({ error: 'Lisensi sudah digunakan oleh toko lain' }, { status: 400 });
    }

    // Verify email matches the purchase email (case-insensitive)
    if (license.email.toLowerCase() !== email.toLowerCase()) {
      return NextResponse.json({ error: 'Email pendaftaran tidak cocok dengan email pembelian lisensi ini' }, { status: 400 });
    }

    // Check if email is already registered for another store
    const { data: existingStore } = await supabase
      .from('stores')
      .select('id')
      .ilike('email', email.trim())
      .maybeSingle();

    if (existingStore) {
      return NextResponse.json({ error: 'Email ini sudah terdaftar untuk toko lain' }, { status: 400 });
    }

    // Validate referral code if provided
    let referrerStoreId: string | null = null;
    if (referral_code && referral_code.trim().length > 0) {
      const code = referral_code.trim();
      // Cari store yang memiliki license_key tersebut
      const { data: referrerStore, error: refError } = await supabase
        .from('stores')
        .select('id')
        .eq('license_key', code)
        .maybeSingle();

      if (refError || !referrerStore) {
        return NextResponse.json({ error: 'Kode referral tidak ditemukan atau tidak valid' }, { status: 400 });
      }
      referrerStoreId = referrerStore.id;
    }

    // 2. Insert the store
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .insert({
        email: email.toLowerCase().trim(),
        store_name,
        license_key,
        owner_name: owner_name || 'Pemilik',
        phone: phone || '',
        address: address || '',
        pin: pin || '',
        referred_by: referrerStoreId
      })
      .select('*')
      .single();

    if (storeError || !store) {
      return NextResponse.json({ error: storeError?.message || 'Gagal mendaftarkan toko baru' }, { status: 500 });
    }

    // 3. Mark the license as used
    const { error: updateError } = await supabase
      .from('licenses')
      .update({ is_used: true })
      .eq('key', license_key);

    if (updateError) {
      // Rollback or ignore? Let's throw to be safe
      throw new Error(`Gagal memperbarui status lisensi: ${updateError.message}`);
    }

    // 4. Process Referral Reward (if referred_by exists)
    if (referrerStoreId) {
      try {
        const rewardAmount = 5000.00; // Reward default Rp 5.000

        // Insert log referral_rewards
        const { error: rewardErr } = await supabase
          .from('referral_rewards')
          .insert({
            referrer_id: referrerStoreId,
            referred_id: store.id,
            amount: rewardAmount
          });

        if (!rewardErr) {
          // Cari seller pengajak untuk menambahkan balance nya
          const { data: referrerSeller } = await supabase
            .from('sellers')
            .select('id, balance')
            .eq('store_id', referrerStoreId)
            .maybeSingle();

          if (referrerSeller) {
            const newBalance = Number(referrerSeller.balance || 0) + rewardAmount;
            await supabase
              .from('sellers')
              .update({ balance: newBalance })
              .eq('id', referrerSeller.id);
          } else {
            // Jika seller landing page belum terdaftar, buatkan baris sellers baru dengan balance awal
            const slugBase = store_name.toLowerCase().replace(/[^a-z0-9\s]/g, '').trim().replace(/\s+/g, '-');
            const randomSuffix = Math.floor(1000 + Math.random() * 9000);
            await supabase
              .from('sellers')
              .insert({
                store_id: referrerStoreId,
                slug: `${slugBase}-${randomSuffix}`,
                balance: rewardAmount,
                is_active: true
              });
          }
        }
      } catch (rewardProcessError) {
        console.error('Error processing referral reward:', rewardProcessError);
        // Jangan block registrasi utama jika hanya proses reward gagal
      }
    }

    return NextResponse.json({ success: true, store_id: store.id });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

