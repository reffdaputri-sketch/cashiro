import type { Metadata } from "next";
import { Inter } from "next/font/google";
import "./globals.css";

const inter = Inter({ subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Kiosly - Solusi Kasir Pintar & Toko Online UMKM",
  description: "Aplikasi Cloud Kasir terpadu untuk kelola stok dan penjualan. Buat Website Toko Online hanya dengan hitungan detik!",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="id" className="scroll-smooth">
      <body className={inter.className}>{children}</body>
    </html>
  );
}
