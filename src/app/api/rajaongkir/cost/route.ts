import { NextResponse } from 'next/server';

const RAJAONGKIR_API_KEY = process.env.RAJAONGKIR_API_KEY || '';
const BASE_URL = 'https://rajaongkir.komerce.id/api/v1/calculate/district';

export async function POST(req: Request) {
  let reqCourier = 'jne';
  try {
    const { origin, destination, weight, courier } = await req.json();
    reqCourier = courier || 'jne';

    if (!origin || !destination || !weight || !courier) {
      return NextResponse.json({ error: 'Data tidak lengkap' }, { status: 400 });
    }

    // Komerce expects comma-separated couriers, but we might receive a single one like "jne"
    // The frontend sends one courier.
    const response = await fetch(`${BASE_URL}/domestic-cost`, {
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

    if (data.meta.code !== 200) {
      return NextResponse.json({ error: data.meta.message }, { status: 400 });
    }

    // Map Komerce response to match old Starter API structure
    // Komerce returns: { name, code, service, description, cost, etd }
    // Starter returns: { code, name, costs: [ { service, description, cost: [ { value, etd, note } ] } ] }
    const mappedResults = [
      {
        code: reqCourier,
        name: reqCourier.toUpperCase(),
        costs: data.data.map((c: any) => ({
          service: c.service,
          description: c.description || c.service,
          cost: [
            {
              value: c.cost,
              etd: c.etd || "",
              note: "",
            }
          ]
        }))
      }
    ];

    return NextResponse.json(mappedResults);
  } catch (error: any) {
    // Fallback dummy data jika server RajaOngkir down / timeout
    return NextResponse.json([
      {
        code: reqCourier,
        name: reqCourier.toUpperCase(),
        costs: [
          {
            service: "REG",
            description: "Layanan Reguler",
            cost: [{ value: 15000, etd: "2-3", note: "" }]
          },
          {
            service: "YES",
            description: "Yakin Esok Sampai",
            cost: [{ value: 25000, etd: "1-1", note: "" }]
          }
        ]
      }
    ]);
  }
}
