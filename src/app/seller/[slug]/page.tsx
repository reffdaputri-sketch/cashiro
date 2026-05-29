import { Metadata } from 'next';
import SellerDashboardPage from './SellerDashboardPage';

export const metadata: Metadata = {
  title: 'Dashboard Seller - Cashiro',
  description: 'Kelola produk, pesanan, dan saldo toko online Anda',
};

export default async function Page({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params;
  return <SellerDashboardPage slug={slug} />;
}
