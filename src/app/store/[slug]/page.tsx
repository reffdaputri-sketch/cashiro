import { Metadata } from 'next';
import { notFound } from 'next/navigation';
import StorePage from './StorePage';

interface SellerData {
  seller: {
    slug: string;
    store_name: string;
    owner_name: string;
    phone: string;
    address: string;
    city_id: number | null;
  };
  products: {
    id: number;
    name: string;
    description: string;
    price: number;
    stock: number;
    weight: number;
    image_url: string;
  }[];
}

async function getSellerData(slug: string): Promise<SellerData | null> {
  try {
    const appUrl = process.env.NEXT_PUBLIC_APP_URL || 'http://localhost:3000';
    const res = await fetch(`${appUrl}/api/sellers/${slug}`, { cache: 'no-store' });
    if (!res.ok) return null;
    return res.json();
  } catch {
    return null;
  }
}

export async function generateMetadata({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> {
  const { slug } = await params;
  const data = await getSellerData(slug);
  if (!data) return { title: 'Toko Tidak Ditemukan' };
  return {
    title: `${data.seller.store_name} - Belanja Online`,
    description: `Belanja produk berkualitas dari ${data.seller.store_name}. ${data.products.length} produk tersedia.`,
  };
}

export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  const data = await getSellerData(slug);
  if (!data) notFound();
  return <StorePage data={data} slug={slug} />;
}
