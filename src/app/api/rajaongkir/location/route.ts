import { NextResponse } from 'next/server';

const RAJAONGKIR_API_KEY = process.env.RAJAONGKIR_API_KEY || '';
const BASE_URL = 'https://rajaongkir.komerce.id/api/v1/destination';

export async function GET(req: Request) {
  try {
    const { searchParams } = new URL(req.url);
    const type = searchParams.get('type') || 'province'; // 'province', 'city', or 'district'
    const provinceId = searchParams.get('province');
    const cityId = searchParams.get('city');

    let url = `${BASE_URL}/province`;
    if (type === 'city' && provinceId) {
      url = `${BASE_URL}/city/${provinceId}`;
    } else if (type === 'district' && cityId) {
      url = `${BASE_URL}/district/${cityId}`;
    }

    const response = await fetch(url, {
      headers: {
        'key': RAJAONGKIR_API_KEY,
      },
    });

    const data = await response.json();

    if (data.meta.code !== 200) {
      return NextResponse.json({ error: data.meta.message }, { status: 400 });
    }

    // Map Komerce response to match old Starter API structure
    if (type === 'province') {
      const mappedProvinces = data.data.map((p: any) => ({
        province_id: p.id.toString(),
        province: p.name,
      }));
      return NextResponse.json(mappedProvinces);
    } else if (type === 'city') {
      const mappedCities = data.data.map((c: any) => ({
        city_id: c.id.toString(),
        province_id: provinceId,
        type: 'Kota/Kab',
        city_name: c.name,
        postal_code: '',
      }));
      return NextResponse.json(mappedCities);
    } else {
      const mappedDistricts = data.data.map((d: any) => ({
        district_id: d.id.toString(),
        city_id: cityId,
        district_name: d.name,
      }));
      return NextResponse.json(mappedDistricts);
    }
  } catch (error: any) {
    // Fallback dummy data jika server RajaOngkir down / timeout
    const { searchParams } = new URL(req.url);
    const type = searchParams.get('type') || 'province';
    const cityId = searchParams.get('city');
    if (type === 'province') {
      return NextResponse.json([
        { province_id: "6", province: "DKI Jakarta" },
        { province_id: "9", province: "Jawa Barat" },
        { province_id: "10", province: "Jawa Tengah" },
        { province_id: "11", province: "Jawa Timur" }
      ]);
    } else if (type === 'city') {
      return NextResponse.json([
        { city_id: "152", province_id: "6", type: "Kota", city_name: "Jakarta Pusat", postal_code: "10540" },
        { city_id: "153", province_id: "6", type: "Kota", city_name: "Jakarta Selatan", postal_code: "12230" },
        { city_id: "22", province_id: "9", type: "Kota", city_name: "Bandung", postal_code: "40111" }
      ]);
    } else {
      return NextResponse.json([
        { district_id: "91", city_id: cityId || "10", district_name: "TALIWANG" },
        { district_id: "92", city_id: cityId || "10", district_name: "JEREWEH" }
      ]);
    }
  }
}
