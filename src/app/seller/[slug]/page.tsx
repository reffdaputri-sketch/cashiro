import { Metadata } from 'next';
import SellerDashboardPage from './SellerDashboardPage';

export const metadata: Metadata = {
  title: 'Dashboard Seller - Cashiro',
  description: 'Kelola produk, pesanan, dan saldo toko online Anda',
};

export default function Page({ params }: { params: { slug: string } }) {
  return <SellerDashboardPage slug={params.slug} />;
}
