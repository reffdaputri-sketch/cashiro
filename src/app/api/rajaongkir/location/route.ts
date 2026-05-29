import { NextResponse } from 'next/server';

const RAJAONGKIR_API_KEY = process.env.RAJAONGKIR_API_KEY || '';
const BASE_URL = 'https://api.rajaongkir.com/starter';

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const type = searchParams.get('type') || 'province'; // 'province' or 'city'
    const provinceId = searchParams.get('province');

    let url = `${BASE_URL}/${type}`;
    if (type === 'city' && provinceId) {
      url += `?province=${provinceId}`;
    }

    const response = await fetch(url, {
      headers: {
        'key': RAJAONGKIR_API_KEY,
      },
    });

    const data = await response.json();

    if (data.rajaongkir.status.code !== 200) {
      return NextResponse.json({ error: data.rajaongkir.status.description }, { status: 400 });
    }

    return NextResponse.json(data.rajaongkir.results);
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
