"use client";

import React, { useState } from 'react';
import Link from 'next/link';
import { motion } from 'framer-motion';
import {
    ShoppingBag,
    ArrowLeft,
    BookOpen,
    Download,
    Package,
    ShoppingCart,
    BarChart2,
    Printer,
    Users,
    Settings,
    ChevronRight,
    CheckCircle,
    MessageCircle,
    Play,
} from 'lucide-react';

const guides = [
    {
        id: 'getting-started',
        icon: <Download size={24} />,
        color: 'from-blue-500 to-blue-600',
        lightColor: 'bg-blue-50 text-blue-600',
        badge: 'Mulai Di Sini',
        title: 'Mulai Menggunakan Cashiro',
        desc: 'Panduan pertama untuk pengguna baru. Dari instalasi hingga transaksi pertama.',
        steps: [
            {
                title: 'Download & Instal Aplikasi',
                content:
                    'Unduh file Cashiro.apk dari halaman download resmi. Aktifkan "Instal dari sumber tidak dikenal" di Pengaturan HP Anda, buka file APK, lalu tap Instal. Proses selesai dalam 1–2 menit.',
                tips: ['Pastikan storage HP Anda tersedia minimal 200MB', 'Koneksi internet diperlukan untuk aktivasi pertama'],
            },
            {
                title: 'Daftar & Buat Akun Toko',
                content:
                    'Setelah instalasi, buka Cashiro → tap "Daftar" → isi nama toko, email, nomor HP, dan buat password → tap "Buat Akun". Anda akan menerima email verifikasi.',
                tips: ['Gunakan email aktif yang sering Anda cek', 'Password minimal 8 karakter'],
            },
            {
                title: 'Isi Profil Toko',
                content:
                    'Masuk ke Pengaturan → Profil Toko → lengkapi nama toko, alamat, dan nomor telepon. Data ini akan muncul di struk transaksi pelanggan Anda.',
            },
            {
                title: 'Tambah Produk Pertama',
                content:
                    'Buka menu "Produk" → tap tombol (+) → isi nama produk, harga jual, stok awal, dan kategori → tap Simpan. Ulangi untuk semua produk Anda.',
                tips: ['Anda bisa tambah foto produk agar tampilan lebih menarik', 'Gunakan kategori untuk mengelompokkan produk'],
            },
            {
                title: 'Transaksi Pertama',
                content:
                    'Buka menu "Kasir" → cari atau scan barcode produk → produk masuk ke keranjang → atur jumlah jika perlu → tap "Bayar" → pilih metode bayar → selesai!',
            },
        ],
    },
    {
        id: 'products',
        icon: <Package size={24} />,
        color: 'from-green-500 to-green-600',
        lightColor: 'bg-green-50 text-green-600',
        badge: 'Manajemen',
        title: 'Manajemen Produk & Stok',
        desc: 'Cara mengelola produk, stok, kategori, dan barcode secara efektif.',
        steps: [
            {
                title: 'Tambah Produk Manual',
                content:
                    'Menu Produk → (+) → isi formulir produk. Untuk produk tanpa barcode fisik, biarkan kolom barcode kosong — sistem akan otomatis generate kode unik.',
                tips: ['Produk tanpa barcode tetap bisa dicari manual di kasir', 'Generate barcode untuk dicetak & ditempel di produk'],
            },
            {
                title: 'Cetak & Share Barcode',
                content:
                    'Buka detail produk → tap ikon "Barcode" → pilih "Cetak" untuk printer thermal atau "Bagikan" untuk kirim gambar barcode via WhatsApp. Barcode mencakup nama produk, kode, dan gambar barcode.',
                tips: ['Ideal untuk produk yang tidak punya barcode bawaan', 'Kirim ke WhatsApp untuk dicetak di tempat lain'],
            },
            {
                title: 'Atur Stok Minimum',
                content:
                    'Edit produk → isi nilai "Stok Minimum" → simpan. Saat stok menyentuh angka ini, notifikasi peringatan akan muncul di dashboard.',
            },
            {
                title: 'Tambah Produk Dadakan (Add Manual)',
                content:
                    'Di layar kasir, tap "Tambah Manual" → isi nama produk, harga, dan jumlah → tap Tambahkan. Produk langsung masuk ke keranjang tanpa perlu tersimpan di database.',
                tips: ['Fitur ini untuk produk sementara yang tidak perlu dicatat di inventori', 'Gunakan untuk barang titipan atau produk sekali jual'],
            },
            {
                title: 'Kelola Kategori',
                content:
                    'Menu Produk → tab Kategori → tambah atau edit kategori. Kategori membantu mencari produk lebih cepat di kasir dan laporan.',
            },
        ],
    },
    {
        id: 'cashier',
        icon: <ShoppingCart size={24} />,
        color: 'from-orange-500 to-orange-600',
        lightColor: 'bg-orange-50 text-orange-600',
        badge: 'Transaksi',
        title: 'Penggunaan Kasir (POS)',
        desc: 'Panduan lengkap memproses transaksi, pembayaran, dan berbagai fitur kasir.',
        steps: [
            {
                title: 'Proses Transaksi Dasar',
                content:
                    'Tap ikon kasir → scan barcode atau ketik nama produk di kolom pencarian → produk masuk keranjang → atur jumlah dengan (+) / (-) → tap "Bayar".',
            },
            {
                title: 'Fitur Uang Pas',
                content:
                    'Saat halaman pembayaran muncul, jika pembeli membayar tepat sesuai total belanja, tap tombol "Uang Pas". Transaksi langsung selesai tanpa perlu input nominal — kembalian otomatis Rp 0.',
                tips: ['Sangat menghemat waktu untuk antrian panjang', 'Tombol terletak di atas area input nominal pembayaran'],
            },
            {
                title: 'Metode Pembayaran',
                content:
                    'Cashiro mendukung Tunai, Transfer Bank, dan QRIS. Pilih metode yang digunakan pelanggan, masukkan nominal (atau tap Uang Pas untuk tunai), lalu konfirmasi.',
            },
            {
                title: 'Cetak atau Kirim Struk',
                content:
                    'Setelah bayar, tap "Cetak Struk" untuk printer thermal, atau "Kirim via WA" untuk kirim struk digital ke pelanggan.',
            },
            {
                title: 'Batalkan / Refund Transaksi',
                content:
                    'Riwayat Transaksi → cari transaksi → tap Detail → "Batalkan Transaksi". Stok produk otomatis dikembalikan ke jumlah semula.',
                tips: ['Hanya Admin yang bisa menghapus riwayat transaksi', 'Pembatalan tidak bisa dilakukan jika shift sudah ditutup'],
            },
        ],
    },
    {
        id: 'reports',
        icon: <BarChart2 size={24} />,
        color: 'from-purple-500 to-purple-600',
        lightColor: 'bg-purple-50 text-purple-600',
        badge: 'Analitik',
        title: 'Laporan & Keuangan',
        desc: 'Cara membaca laporan penjualan, stok, dan arus kas toko Anda.',
        steps: [
            {
                title: 'Laporan Penjualan',
                content:
                    'Menu Laporan → pilih rentang waktu (Hari ini / Minggu / Bulan / Custom) → lihat total penjualan, jumlah transaksi, dan produk terlaris.',
            },
            {
                title: 'Laporan Stok Barang',
                content:
                    'Menu Stok → lihat status stok semua produk dengan indikator warna: Hijau (aman), Kuning (menipis), Merah (habis). Filter berdasarkan kategori atau status stok.',
            },
            {
                title: 'Laporan Arus Kas',
                content:
                    'Menu Keuangan → lihat total uang masuk (pendapatan), uang keluar (pengeluaran), dan saldo bersih per periode. Gunakan tab untuk beralih antara Pemasukan, Pengeluaran, dan Semua.',
            },
            {
                title: 'Riwayat Transaksi',
                content:
                    'Menu Riwayat → lihat semua transaksi yang pernah terjadi. Tap transaksi untuk melihat detail produk, nominal, kasir, dan waktu transaksi.',
                tips: ['Admin bisa menghapus riwayat transaksi jika diperlukan', 'Filter berdasarkan tanggal atau kasir'],
            },
        ],
    },
    {
        id: 'printer',
        icon: <Printer size={24} />,
        color: 'from-rose-500 to-rose-600',
        lightColor: 'bg-rose-50 text-rose-600',
        badge: 'Perangkat',
        title: 'Koneksi Printer Thermal',
        desc: 'Cara menghubungkan dan mengkonfigurasi printer struk Bluetooth.',
        steps: [
            {
                title: 'Pilih Printer yang Kompatibel',
                content:
                    'Cashiro mendukung printer thermal Bluetooth 58mm dan 80mm. Merek yang direkomendasikan: EPPOS, Goojprt, Xprinter, dan sejenisnya yang banyak dijual di marketplace.',
            },
            {
                title: 'Aktifkan Bluetooth & Pairing',
                content:
                    'Nyalakan printer → aktifkan Bluetooth di HP → masuk ke Pengaturan Bluetooth HP → pilih nama printer dari daftar perangkat → tap Pasangkan (pairing).',
            },
            {
                title: 'Hubungkan di Aplikasi Cashiro',
                content:
                    'Buka Cashiro → Pengaturan → Printer → tap "Scan Perangkat" → pilih printer Anda dari daftar → tap "Hubungkan". Printer siap digunakan.',
                tips: ['Pastikan printer sudah di-pairing di Bluetooth HP dulu', 'Jika tidak muncul, tap "Scan Ulang"'],
            },
            {
                title: 'Uji Cetak',
                content:
                    'Setelah terhubung, tap "Cetak Test" untuk memastikan printer berfungsi. Jika berhasil, Anda akan melihat struk percobaan tercetak.',
            },
        ],
    },
    {
        id: 'staff',
        icon: <Users size={24} />,
        color: 'from-cyan-500 to-cyan-600',
        lightColor: 'bg-cyan-50 text-cyan-600',
        badge: 'Tim',
        title: 'Kelola Staf & Kasir',
        desc: 'Cara menambah, mengatur peran, dan memantau aktivitas kasir Anda.',
        steps: [
            {
                title: 'Tambah Akun Kasir',
                content:
                    'Pengaturan → Kelola Staf → "Tambah Staf" → isi nama dan email → pilih peran "Kasir" → kirim undangan. Kasir akan menerima email untuk buat password.',
            },
            {
                title: 'Peran & Hak Akses',
                content:
                    'Admin: akses penuh ke semua fitur. Kasir: hanya bisa akses menu Kasir, lihat produk, dan riwayat transaksinya sendiri. Admin bisa merubah peran kapan saja.',
            },
            {
                title: 'Pantau Aktivitas Kasir',
                content:
                    'Laporan → filter berdasarkan Kasir → lihat total transaksi, omzet, dan riwayat per kasir. Berguna untuk evaluasi performa staf.',
            },
        ],
    },
    {
        id: 'settings',
        icon: <Settings size={24} />,
        color: 'from-amber-500 to-amber-600',
        lightColor: 'bg-amber-50 text-amber-600',
        badge: 'Konfigurasi',
        title: 'Pengaturan Toko',
        desc: 'Kustomisasi profil toko, struk, notifikasi, dan preferensi aplikasi.',
        steps: [
            {
                title: 'Edit Informasi Toko',
                content:
                    'Pengaturan → Profil Toko → edit nama, alamat, nomor telepon, dan logo toko. Info ini tampil di header struk yang dicetak.',
            },
            {
                title: 'Kustomisasi Struk',
                content:
                    'Pengaturan → Struk → atur header (nama toko, tagline), footer (ucapan terima kasih, nomor WA), dan apakah menampilkan logo atau tidak.',
            },
            {
                title: 'Atur Notifikasi',
                content:
                    'Pengaturan → Notifikasi → aktifkan/matikan notifikasi untuk stok menipis, laporan harian otomatis, atau pengingat tutup shift.',
            },
            {
                title: 'Ganti Password',
                content:
                    'Pengaturan → Akun → "Ubah Password" → masukkan password lama dan password baru → konfirmasi. Berlaku langsung.',
            },
        ],
    },
];

function GuideCard({ guide, onClick, isActive }: { guide: typeof guides[0]; onClick: () => void; isActive: boolean }) {
    return (
        <motion.button
            onClick={onClick}
            whileHover={{ y: -3 }}
            whileTap={{ scale: 0.98 }}
            className={`w-full text-left p-5 rounded-2xl border-2 transition-all ${isActive ? 'border-[var(--primary)] bg-blue-50 shadow-md' : 'border-[var(--border)] bg-white hover:border-blue-200 hover:shadow-sm'}`}
        >
            <div className={`w-11 h-11 rounded-xl flex items-center justify-center mb-3 ${guide.lightColor}`}>
                {guide.icon}
            </div>
            <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-0.5 rounded-full ${guide.lightColor} mb-2 inline-block`}>
                {guide.badge}
            </span>
            <h3 className="font-bold text-[var(--foreground)] text-sm leading-snug mb-1">{guide.title}</h3>
            <p className="text-xs text-[var(--muted-foreground)] leading-relaxed">{guide.desc}</p>
        </motion.button>
    );
}

export default function GuidePage() {
    const [activeGuide, setActiveGuide] = useState(guides[0]);

    return (
        <div className="min-h-screen bg-[#f8fafc]">
            {/* Header */}
            <header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-[var(--border)] shadow-sm">
                <div className="max-w-7xl mx-auto px-4 h-16 flex items-center justify-between">
                    <Link href="/" className="flex items-center gap-2 group">
                        <ArrowLeft size={18} className="text-[var(--muted-foreground)] group-hover:text-[var(--primary)] transition-colors" />
                        <div className="w-8 h-8 rounded-lg bg-[var(--primary)] flex items-center justify-center text-white">
                            <ShoppingBag size={18} />
                        </div>
                        <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-[var(--primary)] to-blue-500">
                            Cashiro
                        </span>
                    </Link>
                    <span className="text-sm text-[var(--muted-foreground)]">Panduan Penggunaan</span>
                </div>
            </header>

            {/* Page Hero */}
            <section className="relative overflow-hidden bg-gradient-to-br from-[var(--primary)] via-blue-600 to-blue-800 py-14 text-white">
                <div className="absolute -top-24 -right-24 w-96 h-96 bg-white/10 rounded-full blur-3xl pointer-events-none" />
                <div className="absolute -bottom-32 -left-24 w-80 h-80 bg-white/10 rounded-full blur-3xl pointer-events-none" />
                <div className="relative max-w-4xl mx-auto px-4 text-center">
                    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                        <div className="inline-flex items-center gap-2 bg-white/15 border border-white/25 rounded-full px-4 py-1.5 text-sm font-medium mb-5">
                            <BookOpen size={16} /> Panduan Penggunaan
                        </div>
                        <h1 className="text-4xl font-extrabold mb-3">Kuasai Cashiro dalam Hitungan Menit</h1>
                        <p className="text-blue-100 max-w-xl mx-auto">
                            Panduan lengkap step-by-step untuk memaksimalkan setiap fitur aplikasi kasir Cashiro.
                        </p>
                    </motion.div>
                </div>
            </section>

            {/* Content */}
            <div className="max-w-7xl mx-auto px-4 py-10">
                <div className="flex flex-col lg:flex-row gap-8">
                    {/* Sidebar — Guide List */}
                    <aside className="lg:w-80 shrink-0">
                        <div className="sticky top-24">
                            <p className="text-xs font-bold text-[var(--muted-foreground)] uppercase tracking-wider mb-3">Daftar Panduan</p>
                            <div className="grid grid-cols-1 gap-3">
                                {guides.map((g) => (
                                    <GuideCard
                                        key={g.id}
                                        guide={g}
                                        onClick={() => setActiveGuide(g)}
                                        isActive={activeGuide.id === g.id}
                                    />
                                ))}
                            </div>
                        </div>
                    </aside>

                    {/* Main — Steps */}
                    <main className="flex-1 min-w-0">
                        <motion.div
                            key={activeGuide.id}
                            initial={{ opacity: 0, x: 16 }}
                            animate={{ opacity: 1, x: 0 }}
                            transition={{ duration: 0.3 }}
                        >
                            {/* Guide Header */}
                            <div className={`relative overflow-hidden rounded-2xl bg-gradient-to-br ${activeGuide.color} p-8 text-white mb-8 shadow-lg`}>
                                <div className="absolute -top-8 -right-8 w-32 h-32 bg-white/10 rounded-full blur-2xl" />
                                <div className="relative">
                                    <span className="inline-block text-[10px] font-bold uppercase tracking-widest bg-white/20 border border-white/30 rounded-full px-3 py-1 mb-3">
                                        {activeGuide.badge}
                                    </span>
                                    <h2 className="text-2xl font-extrabold mb-2">{activeGuide.title}</h2>
                                    <p className="text-white/80 text-sm">{activeGuide.desc}</p>
                                </div>
                            </div>

                            {/* Steps */}
                            <div className="space-y-5">
                                {activeGuide.steps.map((step, idx) => (
                                    <motion.div
                                        key={step.title}
                                        initial={{ opacity: 0, y: 16 }}
                                        animate={{ opacity: 1, y: 0 }}
                                        transition={{ duration: 0.3, delay: idx * 0.07 }}
                                        className="bg-white rounded-2xl border border-[var(--border)] p-6 shadow-sm hover:shadow-md transition-shadow"
                                    >
                                        <div className="flex items-start gap-4">
                                            {/* Step number */}
                                            <div className={`shrink-0 w-10 h-10 rounded-xl flex items-center justify-center font-bold text-white text-sm bg-gradient-to-br ${activeGuide.color} shadow`}>
                                                {String(idx + 1).padStart(2, '0')}
                                            </div>
                                            <div className="flex-1">
                                                <h3 className="font-bold text-[var(--foreground)] mb-2 flex items-center gap-2">
                                                    {step.title}
                                                    <ChevronRight size={16} className="text-[var(--muted-foreground)]" />
                                                </h3>
                                                <p className="text-sm text-[var(--muted-foreground)] leading-relaxed">{step.content}</p>

                                                {step.tips && step.tips.length > 0 && (
                                                    <div className="mt-4 space-y-2">
                                                        {step.tips.map((tip) => (
                                                            <div key={tip} className="flex items-start gap-2 text-sm text-green-700 bg-green-50 rounded-lg px-3 py-2">
                                                                <CheckCircle size={14} className="shrink-0 mt-0.5" />
                                                                {tip}
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}
                                            </div>
                                        </div>
                                    </motion.div>
                                ))}
                            </div>

                            {/* Nav between guides */}
                            <div className="flex justify-between mt-8 pt-6 border-t border-[var(--border)]">
                                {guides.findIndex((g) => g.id === activeGuide.id) > 0 ? (
                                    <button
                                        onClick={() => setActiveGuide(guides[guides.findIndex((g) => g.id === activeGuide.id) - 1])}
                                        className="flex items-center gap-2 text-sm font-medium text-[var(--primary)] hover:underline"
                                    >
                                        ← Panduan Sebelumnya
                                    </button>
                                ) : <div />}
                                {guides.findIndex((g) => g.id === activeGuide.id) < guides.length - 1 ? (
                                    <button
                                        onClick={() => setActiveGuide(guides[guides.findIndex((g) => g.id === activeGuide.id) + 1])}
                                        className="flex items-center gap-2 text-sm font-medium text-[var(--primary)] hover:underline"
                                    >
                                        Panduan Berikutnya →
                                    </button>
                                ) : <div />}
                            </div>
                        </motion.div>
                    </main>
                </div>
            </div>

            {/* CTA Section */}
            <section className="bg-gradient-to-r from-[var(--primary)] to-blue-600 py-14 text-white text-center mt-6">
                <Play size={40} className="mx-auto mb-4 opacity-80" />
                <h2 className="text-2xl font-bold mb-2">Siap mencoba sendiri?</h2>
                <p className="text-blue-100 mb-6 max-w-md mx-auto text-sm">
                    Download aplikasi Cashiro sekarang dan mulai kelola toko Anda lebih efisien!
                </p>
                <div className="flex flex-col sm:flex-row gap-3 justify-center">
                    <Link
                        href="/download"
                        className="inline-flex items-center justify-center gap-2 bg-white text-[var(--primary)] font-bold px-7 py-3.5 rounded-2xl hover:scale-105 active:scale-95 transition-all shadow-lg"
                    >
                        <Download size={20} /> Download Sekarang
                    </Link>
                    <a
                        href="https://wa.me/6285157578692"
                        target="_blank"
                        rel="noopener noreferrer"
                        className="inline-flex items-center justify-center gap-2 border-2 border-white text-white font-bold px-7 py-3.5 rounded-2xl hover:bg-white/10 transition-all"
                    >
                        <MessageCircle size={20} /> Tanya via WhatsApp
                    </a>
                </div>
            </section>

            {/* Footer */}
            <footer className="bg-white border-t border-[var(--border)] py-8 text-center text-sm text-[var(--muted-foreground)]">
                <div className="flex items-center justify-center gap-2 mb-2">
                    <div className="w-6 h-6 rounded-md bg-[var(--primary)] flex items-center justify-center text-white">
                        <ShoppingBag size={14} />
                    </div>
                    <span className="font-semibold text-[var(--foreground)]">Cashiro</span>
                </div>
                <p>© {new Date().getFullYear()} Cashiro. Hak cipta dilindungi.</p>
                <div className="mt-2 flex items-center justify-center gap-4">
                    <Link href="/help" className="hover:text-[var(--primary)] transition-colors">Pusat Bantuan</Link>
                    <span>·</span>
                    <Link href="/privacy-policy" className="hover:text-[var(--primary)] transition-colors">Kebijakan Privasi</Link>
                    <span>·</span>
                    <Link href="/" className="hover:text-[var(--primary)] transition-colors">Kembali ke Beranda</Link>
                </div>
            </footer>
        </div>
    );
}
