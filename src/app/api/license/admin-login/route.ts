import { NextResponse } from 'next/server';

export async function POST(req: Request) {
  try {
    const { username, password } = await req.json();
    
    const adminUser = process.env.ADMIN_USERNAME || 'admin';
    const adminPass = process.env.ADMIN_PASSWORD || 'cashiro2026';

    if (username === adminUser && password === adminPass) {
      return NextResponse.json({ success: true, token: 'admin-authorized-token-cashiro' });
    }

    return NextResponse.json({ error: 'Username atau Password Admin salah' }, { status: 401 });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
