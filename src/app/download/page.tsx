"use client";

import React, { useState } from 'react';
import Link from 'next/link';
import {
    Download,
    ShoppingBag,
    Star,
    Shield,
    Zap,
    Users,
    CheckCircle,
    Smartphone,
    Settings,
    Package,
    ChevronRight,
    AlertCircle,
    ArrowLeft,
} from 'lucide-react';
import { motion } from 'framer-motion';

const APP_VERSION = '1.0.0';
const APP_SIZE = '128 MB';
const LAST_UPDATED = '30 Mei 2025';
const APK_URL = '/Cashiro.apk';

const features = [
    { icon: <Package size={20} />, label: 'Manajemen Stok' },
    { icon: <Zap size={20} />, label: 'Kasir Cepat' },
    { icon: <Users size={20} />, label: 'Multi-Kasir' },
    { icon: <Shield size={20} />, label: 'Cloud Backup' },
];

const steps = [
    {
        number: '01',
        title: 'Izinkan Sumber Tidak Dikenal',
        description:
            'Buka Pengaturan → Keamanan (atau Privasi) → aktifkan "Instal dari sumber tidak dikenal" atau "Izinkan dari sumber ini".',
        icon: <Settings size={28} />,
        warning: 'Langkah ini perlu dilakukan karena APK tidak berasal dari Google Play Store.',
    },
    {
        number: '02',
        title: 'Unduh File APK',
        description:
            'Tap tombol "Download APK" di atas. File Cashiro.apk akan tersimpan otomatis di folder Unduhan (Downloads) perangkat Anda.',
        icon: <Download size={28} />,
    },
    {
        number: '03',
        title: 'Buka File Manager',
        description:
            'Buka aplikasi File Manager / Pengelola File di HP Anda. Masuk ke folder "Unduhan" atau "Downloads", lalu temukan file Cashiro.apk.',
        icon: <Smartphone size={28} />,
    },
    {
        number: '04',
        title: 'Tap & Instal',
        description:
            'Ketuk file Cashiro.apk. Akan muncul dialog konfirmasi instalasi — tap "Instal" dan tunggu hingga proses selesai.',
        icon: <Package size={28} />,
    },
    {
        number: '05',
        title: 'Buka & Daftar',
        description:
            'Setelah terinstal, buka aplikasi Cashiro. Daftarkan toko Anda atau masuk dengan akun yang sudah ada. Selamat berjualan! 🎉',
        icon: <CheckCircle size={28} />,
    },
];

export default function DownloadPage() {
    const [downloading, setDownloading] = useState(false);
    const [downloaded, setDownloaded] = useState(false);

    const handleDownload = () => {
        setDownloading(true);
        setTimeout(() => {
            setDownloading(false);
            setDownloaded(true);
        }, 1800);
    };

    return (
        <div className="min-h-screen bg-[#f8fafc]">
            {/* ─── HEADER ──────────────────────────────────────────────── */}
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
                    <span className="text-sm text-[var(--muted-foreground)]">Halaman Unduhan Resmi</span>
                </div>
            </header>

            {/* ─── HERO / APP CARD ─────────────────────────────────────── */}
            <section className="relative overflow-hidden bg-gradient-to-br from-[var(--primary)] via-blue-600 to-blue-800 pt-16 pb-24 text-white">
                {/* Decorative blobs */}
                <div className="absolute -top-24 -right-24 w-96 h-96 bg-white/10 rounded-full blur-3xl pointer-events-none" />
                <div className="absolute -bottom-32 -left-24 w-80 h-80 bg-white/10 rounded-full blur-3xl pointer-events-none" />

                <div className="relative max-w-6xl mx-auto px-4">
                    <motion.div
                        initial={{ opacity: 0, y: 24 }}
                        animate={{ opacity: 1, y: 0 }}
                        transition={{ duration: 0.55 }}
                        className="flex flex-col md:flex-row items-center md:items-start gap-8"
                    >
                        {/* App Icon */}
                        <div className="shrink-0 w-28 h-28 rounded-[28px] bg-white shadow-2xl flex items-center justify-center">
                            <ShoppingBag size={56} className="text-[var(--primary)]" />
                        </div>

                        {/* App Info */}
                        <div className="flex-1 text-center md:text-left">
                            <h1 className="text-4xl font-extrabold tracking-tight mb-1">Cashiro</h1>
                            <p className="text-blue-200 text-base mb-4">
                                Aplikasi Kasir &amp; Manajemen Stok untuk UMKM Indonesia
                            </p>

                            {/* Stars */}
                            <div className="flex items-center justify-center md:justify-start gap-1 mb-5">
                                {[...Array(5)].map((_, i) => (
                                    <Star key={i} size={16} fill="currentColor" className="text-yellow-400" />
                                ))}
                                <span className="ml-2 text-sm text-blue-100">4.9 · 1.200+ ulasan</span>
                            </div>

                            {/* Feature Chips */}
                            <div className="flex flex-wrap justify-center md:justify-start gap-2 mb-8">
                                {features.map((f) => (
                                    <span
                                        key={f.label}
                                        className="flex items-center gap-1.5 px-3 py-1 rounded-full bg-white/15 border border-white/25 text-sm font-medium"
                                    >
                                        {f.icon} {f.label}
                                    </span>
                                ))}
                            </div>

                            {/* Download Button */}
                            <a
                                href={APK_URL}
                                download="Cashiro.apk"
                                onClick={handleDownload}
                                className="inline-flex items-center gap-3 px-8 py-4 rounded-2xl font-bold text-lg bg-white text-[var(--primary)] shadow-lg hover:shadow-xl hover:scale-105 active:scale-95 transition-all duration-200 select-none cursor-pointer"
                            >
                                {downloaded ? (
                                    <>
                                        <CheckCircle size={24} className="text-green-500" />
                                        Berhasil Diunduh!
                                    </>
                                ) : downloading ? (
                                    <>
                                        <svg className="animate-spin" width={24} height={24} viewBox="0 0 24 24" fill="none">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v8H4z" />
                                        </svg>
                                        Mengunduh…
                                    </>
                                ) : (
                                    <>
                                        <Download size={24} />
                                        Download APK
                                    </>
                                )}
                            </a>

                            {/* Meta */}
                            <div className="mt-5 flex flex-wrap justify-center md:justify-start gap-x-6 gap-y-1 text-sm text-blue-200">
                                <span>Versi {APP_VERSION}</span>
                                <span>·</span>
                                <span>{APP_SIZE}</span>
                                <span>·</span>
                                <span>Diperbarui {LAST_UPDATED}</span>
                                <span>·</span>
                                <span>Android 7.0+</span>
                                <span>·</span>
                                <span className="flex items-center gap-1">
                                    <Shield size={13} /> Gratis
                                </span>
                            </div>
                        </div>
                    </motion.div>
                </div>
            </section>

            {/* ─── STATS STRIP ─────────────────────────────────────────── */}
            <section className="bg-white border-b border-[var(--border)]">
                <div className="max-w-6xl mx-auto px-4">
                    <div className="grid grid-cols-3 divide-x divide-[var(--border)]">
                        {[
                            { value: '5.000+', label: 'Pengguna Aktif' },
                            { value: '4.9★', label: 'Rating Pengguna' },
                            { value: '99.9%', label: 'Uptime Server' },
                        ].map((s) => (
                            <div key={s.label} className="py-6 text-center">
                                <div className="text-2xl font-extrabold text-[var(--primary)]">{s.value}</div>
                                <div className="text-sm text-[var(--muted-foreground)] mt-0.5">{s.label}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </section>

            {/* ─── DESCRIPTION ─────────────────────────────────────────── */}
            <section className="max-w-6xl mx-auto px-4 py-14 grid md:grid-cols-2 gap-12">
                <div>
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-4">Tentang Aplikasi</h2>
                    <p className="text-[var(--muted-foreground)] leading-relaxed mb-4">
                        <strong className="text-[var(--foreground)]">Cashiro</strong> adalah aplikasi kasir berbasis cloud yang dirancang khusus untuk UMKM Indonesia. Dengan antarmuka yang intuitif dan fitur lengkap, Cashiro membantu Anda mengelola transaksi, stok barang, laporan keuangan, dan banyak lagi — semuanya dalam satu genggaman.
                    </p>
                    <p className="text-[var(--muted-foreground)] leading-relaxed">
                        Data tersinkronisasi secara real-time ke cloud sehingga Anda bisa memantau toko dari mana saja. Cocok untuk warung, toko kelontong, minimarket, dan bisnis retail lainnya.
                    </p>
                </div>

                <div>
                    <h2 className="text-2xl font-bold text-[var(--foreground)] mb-4">Yang Bisa Anda Lakukan</h2>
                    <ul className="space-y-3">
                        {[
                            'Transaksi kasir cepat dengan scanner barcode',
                            'Manajemen stok & peringatan stok menipis',
                            'Laporan penjualan harian, mingguan, bulanan',
                            'Cetak struk thermal & barcode produk',
                            'Kelola banyak kasir dalam satu toko',
                            'Arus kas & laporan keuangan lengkap',
                            'Riwayat transaksi & refund mudah',
                        ].map((item) => (
                            <li key={item} className="flex items-start gap-2.5 text-[var(--muted-foreground)]">
                                <CheckCircle size={18} className="text-green-500 mt-0.5 shrink-0" />
                                {item}
                            </li>
                        ))}
                    </ul>
                </div>
            </section>

            {/* ─── INSTALL TUTORIAL ────────────────────────────────────── */}
            <section className="bg-gradient-to-b from-slate-50 to-blue-50/40 border-t border-[var(--border)] py-16">
                <div className="max-w-4xl mx-auto px-4">
                    {/* Section header */}
                    <div className="text-center mb-12">
                        <span className="inline-block px-3 py-1 rounded-full bg-blue-100 text-[var(--primary)] text-sm font-semibold mb-3">
                            📱 Panduan Instalasi
                        </span>
                        <h2 className="text-3xl font-extrabold text-[var(--foreground)]">Cara Instal Cashiro di Android</h2>
                        <p className="text-[var(--muted-foreground)] mt-2 max-w-xl mx-auto">
                            Karena APK ini diunduh langsung (bukan dari Play Store), ikuti langkah-langkah berikut agar instalasi berjalan lancar.
                        </p>
                    </div>

                    {/* Warning banner */}
                    <div className="flex items-start gap-3 bg-amber-50 border border-amber-200 rounded-2xl p-4 mb-10">
                        <AlertCircle size={20} className="text-amber-500 shrink-0 mt-0.5" />
                        <p className="text-amber-800 text-sm leading-relaxed">
                            <strong>Aman &amp; Resmi:</strong> File APK Cashiro bersumber dari server resmi kami. Proses izin "sumber tidak dikenal" hanya diperlukan untuk APK yang didistribusikan di luar Play Store dan tidak berbahaya.
                        </p>
                    </div>

                    {/* Steps */}
                    <div className="relative">
                        {/* Vertical line */}
                        <div className="absolute left-[39px] top-4 bottom-4 w-0.5 bg-gradient-to-b from-[var(--primary)] to-blue-200 hidden md:block" />

                        <div className="space-y-6">
                            {steps.map((step, idx) => (
                                <motion.div
                                    key={step.number}
                                    initial={{ opacity: 0, x: -20 }}
                                    whileInView={{ opacity: 1, x: 0 }}
                                    viewport={{ once: true }}
                                    transition={{ duration: 0.4, delay: idx * 0.08 }}
                                    className="flex gap-5 items-start"
                                >
                                    {/* Step icon circle */}
                                    <div className="shrink-0 z-10 w-20 h-20 rounded-2xl bg-[var(--primary)] text-white flex flex-col items-center justify-center shadow-lg">
                                        {step.icon}
                                        <span className="text-[10px] font-bold mt-1 opacity-70">{step.number}</span>
                                    </div>

                                    {/* Content */}
                                    <div className="flex-1 bg-white rounded-2xl border border-[var(--border)] p-5 shadow-sm hover:shadow-md transition-shadow">
                                        <h3 className="font-bold text-[var(--foreground)] text-lg mb-1">{step.title}</h3>
                                        <p className="text-[var(--muted-foreground)] text-sm leading-relaxed">{step.description}</p>
                                        {step.warning && (
                                            <div className="mt-3 flex items-start gap-2 text-xs text-amber-700 bg-amber-50 rounded-lg px-3 py-2">
                                                <AlertCircle size={13} className="shrink-0 mt-0.5" />
                                                {step.warning}
                                            </div>
                                        )}
                                    </div>
                                </motion.div>
                            ))}
                        </div>
                    </div>

                    {/* Bottom CTA */}
                    <div className="mt-14 text-center">
                        <p className="text-[var(--muted-foreground)] mb-5">Butuh bantuan? Hubungi tim support kami.</p>
                        <div className="flex flex-col sm:flex-row gap-3 justify-center">
                            <a
                                href={APK_URL}
                                download="Cashiro.apk"
                                className="inline-flex items-center justify-center gap-2 px-7 py-3.5 rounded-2xl bg-[var(--primary)] text-white font-semibold hover:opacity-90 hover:scale-105 active:scale-95 transition-all shadow-md"
                            >
                                <Download size={20} /> Download APK Sekarang
                            </a>
                            <a
                                href="https://wa.me/6285157578692"
                                target="_blank"
                                rel="noopener noreferrer"
                                className="inline-flex items-center justify-center gap-2 px-7 py-3.5 rounded-2xl border-2 border-[var(--primary)] text-[var(--primary)] font-semibold hover:bg-[var(--primary)] hover:text-white transition-all"
                            >
                                <ChevronRight size={20} /> Hubungi via WhatsApp
                            </a>
                        </div>
                    </div>
                </div>
            </section>

            {/* ─── FOOTER ──────────────────────────────────────────────── */}
            <footer className="bg-white border-t border-[var(--border)] py-8 text-center text-sm text-[var(--muted-foreground)]">
                <div className="flex items-center justify-center gap-2 mb-2">
                    <div className="w-6 h-6 rounded-md bg-[var(--primary)] flex items-center justify-center text-white">
                        <ShoppingBag size={14} />
                    </div>
                    <span className="font-semibold text-[var(--foreground)]">Cashiro</span>
                </div>
                <p>© {new Date().getFullYear()} Cashiro. Hak cipta dilindungi.</p>
                <div className="mt-2 flex items-center justify-center gap-4">
                    <Link href="/privacy-policy" className="hover:text-[var(--primary)] transition-colors">
                        Kebijakan Privasi
                    </Link>
                    <span>·</span>
                    <Link href="/" className="hover:text-[var(--primary)] transition-colors">
                        Kembali ke Beranda
                    </Link>
                </div>
            </footer>
        </div>
    );
}
