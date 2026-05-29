import { NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { v2 as cloudinary } from 'cloudinary';

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL || '',
  process.env.SUPABASE_SERVICE_ROLE_KEY || ''
);

// Configure Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
});

export async function POST(req: Request) {
  try {
    const formData = await req.formData();
    const file = formData.get('file') as Blob | null;
    const storeId = formData.get('store_id') as string | null;
    const licenseKey = formData.get('license_key') as string | null;

    if (!file || !storeId || !licenseKey) {
      return NextResponse.json({ error: 'File, store_id, dan license_key wajib diisi' }, { status: 400 });
    }

    // 1. Verify store exists and matches the license key
    const { data: store, error: storeError } = await supabase
      .from('stores')
      .select('*')
      .eq('id', storeId)
      .eq('license_key', licenseKey)
      .single();

    if (storeError || !store) {
      return NextResponse.json({ error: 'Validasi toko atau lisensi gagal' }, { status: 401 });
    }

    // 2. Convert file to buffer
    const arrayBuffer = await file.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);

    // 3. Upload to Cloudinary using upload_stream
    const uploadResult: any = await new Promise((resolve, reject) => {
      cloudinary.uploader.upload_stream(
        {
          folder: `kiosly/${storeId}/products`,
          resource_type: 'auto',
        },
        (error, result) => {
          if (error) {
            reject(error);
          } else {
            resolve(result);
          }
        }
      ).end(buffer);
    });

    return NextResponse.json({
      success: true,
      url: uploadResult.secure_url,
    });
  } catch (error: any) {
    console.error('Upload image error:', error);
    return NextResponse.json({ error: error.message || 'Gagal mengunggah gambar ke cloud' }, { status: 500 });
  }
}
