"use client";

import React, { useState } from 'react';
import Link from 'next/link';
import { motion, AnimatePresence } from 'framer-motion';
import {
    ShoppingBag,
    ArrowLeft,
    Search,
    ChevronDown,
    MessageCircle,
    Download,
    ShieldCheck,
    BarChart2,
    Settings,
    Printer,
    Users,
    Package,
    HelpCircle,
} from 'lucide-react';

const categories = [
    {
        icon: <Download size={22} />,
        color: 'bg-blue-100 text-blue-600',
        title: 'Instalasi & Setup',
        faqs: [
            {
                q: 'Bagaimana cara mengunduh dan menginstal aplikasi Cashiro?',
                a: 'Unduh file Cashiro.apk dari halaman download resmi kami. Aktifkan "Instal dari sumber tidak dikenal" di pengaturan HP Anda, lalu buka file APK tersebut dan tap Instal. Proses hanya butuh 1–2 menit.',
            },
            {
                q: 'Versi Android berapa yang didukung?',
                a: 'Cashiro mendukung Android versi 7.0 (Nougat) ke atas. Kami rekomendasikan Android 10+ untuk pengalaman terbaik.',
            },
            {
                q: 'Apakah aplikasi bisa digunakan di tablet?',
                a: 'Ya, Cashiro dapat berjalan di tablet Android. Namun tampilan dioptimalkan untuk layar ponsel (5–7 inci).',
            },
        ],
    },
    {
        icon: <Package size={22} />,
        color: 'bg-green-100 text-green-600',
        title: 'Produk & Stok',
        faqs: [
            {
                q: 'Bagaimana cara menambah produk baru?',
                a: 'Masuk ke menu "Produk" → tap tombol (+) di kanan bawah → isi nama produk, harga, stok, dan kategori → tap Simpan.',
            },
            {
                q: 'Bisakah saya impor produk dalam jumlah banyak?',
                a: 'Saat ini penambahan produk dilakukan satu per satu melalui aplikasi. Fitur impor massal via Excel sedang dalam pengembangan.',
            },
            {
                q: 'Bagaimana cara mengatur notifikasi stok menipis?',
                a: 'Buka detail produk → edit → atur nilai "Stok Minimum". Saat stok menyentuh angka tersebut, aplikasi akan memberikan peringatan otomatis di dashboard.',
            },
            {
                q: 'Bisakah saya menambah produk tanpa barcode?',
                a: 'Ya! Saat tambah produk, kolom barcode bersifat opsional. Anda juga bisa generate barcode otomatis dari menu detail produk untuk dicetak dan ditempel.',
            },
        ],
    },
    {
        icon: <ShoppingBag size={22} />,
        color: 'bg-orange-100 text-orange-600',
        title: 'Transaksi & Kasir',
        faqs: [
            {
                q: 'Bagaimana cara memproses transaksi penjualan?',
                a: 'Buka menu Kasir → scan barcode atau cari produk → masukkan ke keranjang → pilih metode bayar → tap "Bayar". Transaksi otomatis tercatat dan stok terpotong.',
            },
            {
                q: 'Apa itu fitur "Uang Pas"?',
                a: 'Fitur Uang Pas memungkinkan kasir menyelesaikan transaksi tanpa perlu memasukkan nominal uang pembayaran secara manual. Cukup tap tombol "Uang Pas" dan transaksi langsung selesai dengan kembalian Rp 0.',
            },
            {
                q: 'Bagaimana cara melakukan refund / retur transaksi?',
                a: 'Buka menu Riwayat Transaksi → cari transaksi yang ingin diretur → tap detail → pilih "Batalkan Transaksi". Stok akan otomatis dikembalikan.',
            },
            {
                q: 'Bisakah transaksi berjalan tanpa internet?',
                a: 'Saat ini Cashiro membutuhkan koneksi internet untuk sinkronisasi data. Fitur offline mode sedang dalam roadmap pengembangan kami.',
            },
        ],
    },
    {
        icon: <BarChart2 size={22} />,
        color: 'bg-purple-100 text-purple-600',
        title: 'Laporan & Keuangan',
        faqs: [
            {
                q: 'Di mana saya bisa melihat laporan penjualan?',
                a: 'Menu "Laporan" menyediakan ringkasan penjualan harian, mingguan, dan bulanan. Anda juga bisa melihat produk terlaris dan total pendapatan.',
            },
            {
                q: 'Apa itu laporan Arus Kas?',
                a: 'Laporan Arus Kas menampilkan catatan pemasukan (uang masuk dari penjualan) dan pengeluaran (biaya operasional). Fitur ini membantu Anda memantau kesehatan keuangan toko.',
            },
            {
                q: 'Apakah laporan bisa diekspor ke Excel atau PDF?',
                a: 'Fitur ekspor laporan sedang dalam pengembangan dan akan hadir di versi mendatang. Saat ini laporan tersedia dalam tampilan aplikasi.',
            },
        ],
    },
    {
        icon: <Users size={22} />,
        color: 'bg-cyan-100 text-cyan-600',
        title: 'Akun & Kasir',
        faqs: [
            {
                q: 'Bisakah satu toko punya lebih dari satu kasir?',
                a: 'Ya! Pemilik toko (Admin) bisa menambah akun Kasir dari menu Pengaturan → Kelola Staf. Setiap kasir memiliki akses terbatas sesuai perannya.',
            },
            {
                q: 'Apa perbedaan akun Admin dan Kasir?',
                a: 'Admin memiliki akses penuh: produk, laporan, keuangan, pengaturan toko, dan manajemen staf. Kasir hanya bisa memproses transaksi dan melihat produk.',
            },
            {
                q: 'Bagaimana cara reset password?',
                a: 'Di halaman login, tap "Lupa Password" → masukkan email terdaftar → cek email Anda untuk link reset password.',
            },
        ],
    },
    {
        icon: <Printer size={22} />,
        color: 'bg-rose-100 text-rose-600',
        title: 'Printer & Struk',
        faqs: [
            {
                q: 'Printer apa yang kompatibel dengan Cashiro?',
                a: 'Cashiro mendukung printer thermal Bluetooth (ukuran kertas 58mm dan 80mm) yang umum dijual di pasaran seperti EPPOS, Goojprt, dan sejenisnya.',
            },
            {
                q: 'Bagaimana cara menghubungkan printer Bluetooth?',
                a: 'Buka menu Pengaturan → Printer → tap "Scan Perangkat" → pilih printer Anda dari daftar → tap "Hubungkan". Pastikan Bluetooth HP aktif dan printer dalam mode pairing.',
            },
            {
                q: 'Bisakah struk dikirim via WhatsApp tanpa printer?',
                a: 'Ya! Setelah transaksi selesai, tap "Kirim Struk" → pilih WhatsApp → masukkan nomor pelanggan. Struk dikirim dalam format teks.',
            },
        ],
    },
    {
        icon: <ShieldCheck size={22} />,
        color: 'bg-teal-100 text-teal-600',
        title: 'Keamanan & Data',
        faqs: [
            {
                q: 'Apakah data saya aman di Cashiro?',
                a: 'Ya. Semua data dienkripsi dan disimpan di server cloud yang aman. Kami tidak pernah menjual data pengguna ke pihak ketiga.',
            },
            {
                q: 'Apakah data otomatis di-backup?',
                a: 'Ya, semua data transaksi dan stok otomatis tersinkronisasi ke cloud setiap kali ada perubahan. Anda tidak perlu backup manual.',
            },
            {
                q: 'Bagaimana cara menghapus akun saya?',
                a: 'Kunjungi halaman Hapus Akun di website kami, masukkan email terdaftar, dan ikuti instruksinya. Semua data akan dihapus permanen dalam 30 hari.',
            },
        ],
    },
    {
        icon: <Settings size={22} />,
        color: 'bg-amber-100 text-amber-600',
        title: 'Lisensi & Paket',
        faqs: [
            {
                q: 'Apakah ada masa uji coba gratis?',
                a: 'Ya! Anda bisa mencoba Cashiro gratis selama periode trial. Setelah itu pilih paket yang sesuai kebutuhan toko Anda.',
            },
            {
                q: 'Bagaimana cara membeli lisensi?',
                a: 'Buka menu Pengaturan → Lisensi → pilih paket → lakukan pembayaran. Setelah pembayaran dikonfirmasi, lisensi aktif secara otomatis.',
            },
            {
                q: 'Apakah lisensi bisa dipakai di beberapa HP?',
                a: 'Satu lisensi berlaku untuk satu akun toko. Namun Anda bisa login di beberapa HP dengan akun kasir yang berbeda dalam satu lisensi.',
            },
        ],
    },
];

function FAQItem({ q, a }: { q: string; a: string }) {
    const [open, setOpen] = useState(false);
    return (
        <div className="border border-[var(--border)] rounded-xl overflow-hidden">
            <button
                onClick={() => setOpen(!open)}
                className="w-full flex items-center justify-between text-left px-5 py-4 gap-3 hover:bg-[var(--secondary)] transition-colors"
            >
                <span className="font-medium text-[var(--foreground)] text-sm">{q}</span>
                <ChevronDown
                    size={18}
                    className={`shrink-0 text-[var(--muted-foreground)] transition-transform duration-200 ${open ? 'rotate-180' : ''}`}
                />
            </button>
            <AnimatePresence initial={false}>
                {open && (
                    <motion.div
                        key="content"
                        initial={{ height: 0, opacity: 0 }}
                        animate={{ height: 'auto', opacity: 1 }}
                        exit={{ height: 0, opacity: 0 }}
                        transition={{ duration: 0.25 }}
                        className="overflow-hidden"
                    >
                        <div className="px-5 pb-5 text-sm text-[var(--muted-foreground)] leading-relaxed border-t border-[var(--border)] pt-4 bg-[var(--secondary)]/40">
                            {a}
                        </div>
                    </motion.div>
                )}
            </AnimatePresence>
        </div>
    );
}

export default function HelpPage() {
    const [search, setSearch] = useState('');
    const [activeCategory, setActiveCategory] = useState<string | null>(null);

    const filtered = categories
        .map((cat) => ({
            ...cat,
            faqs: cat.faqs.filter(
                (f) =>
                    f.q.toLowerCase().includes(search.toLowerCase()) ||
                    f.a.toLowerCase().includes(search.toLowerCase())
            ),
        }))
        .filter((cat) => cat.faqs.length > 0)
        .filter((cat) => !activeCategory || cat.title === activeCategory);

    return (
        <div className="min-h-screen bg-[#f8fafc]">
            {/* Header */}
            <header className="sticky top-0 z-50 bg-white/80 backdrop-blur-md border-b border-[var(--border)] shadow-sm">
                <div className="max-w-6xl mx-auto px-4 h-16 flex items-center justify-between">
                    <Link href="/" className="flex items-center gap-2 group">
                        <ArrowLeft size={18} className="text-[var(--muted-foreground)] group-hover:text-[var(--primary)] transition-colors" />
                        <div className="w-8 h-8 rounded-lg bg-[var(--primary)] flex items-center justify-center text-white">
                            <ShoppingBag size={18} />
                        </div>
                        <span className="text-xl font-bold bg-clip-text text-transparent bg-gradient-to-r from-[var(--primary)] to-blue-500">
                            Cashiro
                        </span>
                    </Link>
                    <span className="text-sm text-[var(--muted-foreground)]">Pusat Bantuan</span>
                </div>
            </header>

            {/* Hero Banner */}
            <section className="relative overflow-hidden bg-gradient-to-br from-[var(--primary)] via-blue-600 to-blue-800 py-16 text-white">
                <div className="absolute -top-24 -right-24 w-96 h-96 bg-white/10 rounded-full blur-3xl pointer-events-none" />
                <div className="absolute -bottom-32 -left-24 w-80 h-80 bg-white/10 rounded-full blur-3xl pointer-events-none" />
                <div className="relative max-w-3xl mx-auto px-4 text-center">
                    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.5 }}>
                        <div className="inline-flex items-center gap-2 bg-white/15 border border-white/25 rounded-full px-4 py-1.5 text-sm font-medium mb-5">
                            <HelpCircle size={16} /> Pusat Bantuan
                        </div>
                        <h1 className="text-4xl font-extrabold mb-3">Ada yang bisa kami bantu?</h1>
                        <p className="text-blue-100 mb-8">Temukan jawaban dari pertanyaan yang sering ditanyakan pengguna Cashiro.</p>

                        {/* Search */}
                        <div className="relative max-w-xl mx-auto">
                            <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-[var(--muted-foreground)]" />
                            <input
                                type="text"
                                placeholder="Cari pertanyaan…"
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className="w-full pl-11 pr-4 py-3.5 rounded-2xl text-[var(--foreground)] bg-white shadow-lg outline-none focus:ring-2 focus:ring-blue-300 text-sm"
                            />
                        </div>
                    </motion.div>
                </div>
            </section>

            {/* Category Filter */}
            <section className="bg-white border-b border-[var(--border)] sticky top-16 z-40">
                <div className="max-w-6xl mx-auto px-4 py-3 flex gap-2 overflow-x-auto scrollbar-hide">
                    <button
                        onClick={() => setActiveCategory(null)}
                        className={`shrink-0 px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${activeCategory === null ? 'bg-[var(--primary)] text-white' : 'bg-[var(--secondary)] text-[var(--foreground)] hover:bg-blue-50'}`}
                    >
                        Semua
                    </button>
                    {categories.map((cat) => (
                        <button
                            key={cat.title}
                            onClick={() => setActiveCategory(cat.title === activeCategory ? null : cat.title)}
                            className={`shrink-0 flex items-center gap-1.5 px-4 py-1.5 rounded-full text-sm font-medium transition-colors ${activeCategory === cat.title ? 'bg-[var(--primary)] text-white' : 'bg-[var(--secondary)] text-[var(--foreground)] hover:bg-blue-50'}`}
                        >
                            {cat.title}
                        </button>
                    ))}
                </div>
            </section>

            {/* FAQ Content */}
            <section className="max-w-4xl mx-auto px-4 py-12">
                {filtered.length === 0 ? (
                    <div className="text-center py-20 text-[var(--muted-foreground)]">
                        <HelpCircle size={48} className="mx-auto mb-4 opacity-30" />
                        <p className="text-lg font-medium">Tidak ada hasil untuk &ldquo;{search}&rdquo;</p>
                        <p className="text-sm mt-1">Coba kata kunci lain atau hubungi support kami.</p>
                    </div>
                ) : (
                    <div className="space-y-10">
                        {filtered.map((cat, idx) => (
                            <motion.div
                                key={cat.title}
                                initial={{ opacity: 0, y: 20 }}
                                animate={{ opacity: 1, y: 0 }}
                                transition={{ duration: 0.35, delay: idx * 0.05 }}
                            >
                                <div className="flex items-center gap-3 mb-4">
                                    <div className={`w-10 h-10 rounded-xl flex items-center justify-center ${cat.color}`}>
                                        {cat.icon}
                                    </div>
                                    <h2 className="text-lg font-bold text-[var(--foreground)]">{cat.title}</h2>
                                </div>
                                <div className="space-y-2">
                                    {cat.faqs.map((faq) => (
                                        <FAQItem key={faq.q} q={faq.q} a={faq.a} />
                                    ))}
                                </div>
                            </motion.div>
                        ))}
                    </div>
                )}
            </section>

            {/* Still need help? */}
            <section className="bg-gradient-to-r from-[var(--primary)] to-blue-600 py-14 text-white text-center">
                <MessageCircle size={40} className="mx-auto mb-4 opacity-80" />
                <h2 className="text-2xl font-bold mb-2">Masih butuh bantuan?</h2>
                <p className="text-blue-100 mb-6 max-w-md mx-auto text-sm">
                    Tim support kami siap membantu Anda setiap hari. Hubungi kami via WhatsApp untuk respons tercepat.
                </p>
                <a
                    href="https://wa.me/6285157578692"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-flex items-center gap-2 bg-white text-[var(--primary)] font-bold px-7 py-3.5 rounded-2xl hover:scale-105 active:scale-95 transition-all shadow-lg"
                >
                    <MessageCircle size={20} /> Chat via WhatsApp
                </a>
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
                    <Link href="/guide" className="hover:text-[var(--primary)] transition-colors">Panduan Penggunaan</Link>
                    <span>·</span>
                    <Link href="/privacy-policy" className="hover:text-[var(--primary)] transition-colors">Kebijakan Privasi</Link>
                    <span>·</span>
                    <Link href="/" className="hover:text-[var(--primary)] transition-colors">Kembali ke Beranda</Link>
                </div>
            </footer>
        </div>
    );
}
