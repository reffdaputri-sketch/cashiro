import { NextResponse } from 'next/server';

const RAJAONGKIR_API_KEY = process.env.RAJAONGKIR_API_KEY || '';
const BASE_URL = 'https://api.rajaongkir.com/starter';

export async function POST(req: Request) {
  try {
    const { origin, destination, weight, courier } = await req.json();

    if (!origin || !destination || !weight || !courier) {
      return NextResponse.json({ error: 'Data tidak lengkap' }, { status: 400 });
    }

    const response = await fetch(`${BASE_URL}/cost`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'key': RAJAONGKIR_API_KEY,
      },
      body: new URLSearchParams({
        origin: origin.toString(),
        destination: destination.toString(),
        weight: weight.toString(),
        courier: courier.toString(),
      }),
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
