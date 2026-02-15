"use client";

import React from 'react';
import { motion } from 'framer-motion';
import { Globe, Smartphone, BarChart3, Scan, Printer, Users } from 'lucide-react';

const features = [
    {
        icon: <Globe className="w-6 h-6 text-blue-600" />,
        title: 'Website Toko Online',
        description: 'Dapatkan website toko online eksklusif dengan nama brand Anda. Terintegrasi langsung dengan stok kasir.',
    },
    {
        icon: <Smartphone className="w-6 h-6 text-green-600" />,
        title: 'Aplikasi Kasir Cloud',
        description: 'Akses data penjualan real-time dari mana saja. Sinkronisasi otomatis di semua perangkat.',
    },
    {
        icon: <BarChart3 className="w-6 h-6 text-purple-600" />,
        title: 'Laporan Lengkap',
        description: 'Pantau performa bisnis dengan laporan laba rugi otomatis dan analisis penjualan mendalam.',
    },
    {
        icon: <Scan className="w-6 h-6 text-orange-600" />,
        title: 'Scanner Barcode',
        description: 'Percepat transaksi kasir dengan dukungan scanner barcode yang akurat.',
    },
    {
        icon: <Printer className="w-6 h-6 text-red-600" />,
        title: 'Cetak Struk',
        description: 'Dukungan printer thermal via Bluetooth untuk cetak struk profesional.',
    },
    {
        icon: <Users className="w-6 h-6 text-teal-600" />,
        title: 'Manajemen Pelanggan',
        description: 'Kelola data pelanggan dan riwayat transaksi untuk meningkatkan loyalitas.',
    },
];

export const Features = () => {
    return (
        <section id="features" className="py-20 bg-[var(--secondary)]">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-16">
                    <h2 className="text-3xl font-bold text-[var(--foreground)] mb-4">Fitur Lengkap untuk Bisnis Modern</h2>
                    <p className="text-[var(--muted-foreground)] max-w-2xl mx-auto">
                        Semua yang Anda butuhkan untuk mengelola dan mengembangkan bisnis, dari manajemen stok hingga penjualan online.
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
                    {features.map((feature, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, y: 20 }}
                            whileInView={{ opacity: 1, y: 0 }}
                            transition={{ duration: 0.5, delay: index * 0.1 }}
                            viewport={{ once: true }}
                            className="bg-[var(--card)] p-6 rounded-2xl shadow-sm hover:shadow-md transition-shadow border border-[var(--border)]"
                        >
                            <div className="w-12 h-12 bg-gray-50 dark:bg-slate-800 rounded-xl flex items-center justify-center mb-4">
                                {feature.icon}
                            </div>
                            <h3 className="text-xl font-semibold text-[var(--foreground)] mb-2">{feature.title}</h3>
                            <p className="text-[var(--muted-foreground)] leading-relaxed">{feature.description}</p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    );
};
