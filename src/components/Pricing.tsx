"use client";

import React from 'react';
import { Button } from './Button';
import { Check, Star } from 'lucide-react';

const pricingPlans = [
    {
        name: 'Basic',
        period: 'Bulanan',
        price: 'IDR 50.000',
        description: 'Cocok untuk usaha rintisan yang ingin go digital.',
        features: ['Aplikasi Kasir Android', 'Website Toko Online Basic', 'Laporan Penjualan Standar', 'Support via WhatsApp'],
        ctaLink: 'https://wa.me/62851?text=Halo+Admin%2C+saya+tertarik+untuk+berlangganan+Paket+Basic+%28Bulanan%29',
    },
    {
        name: 'Pro',
        period: '1 Tahun',
        price: 'IDR 450.000',
        description: 'Pilihan terbaik untuk UMKM yang sedang berkembang pesat.',
        features: ['Semua Fitur Basic', 'Website Toko Online Premium', 'Laporan Laba Rugi Otomatis', 'Manajemen Stok Multi-Gudang', 'Prioritas Support'],
        isPopular: true,
        ctaLink: 'https://wa.me/62851?text=Halo+Admin%2C+saya+tertarik+untuk+berlangganan+Paket+Pro+%281+Tahun%29',
    },
    {
        name: 'Enterprise',
        period: '2 Tahun',
        price: 'IDR 800.000',
        description: 'Solusi jangka panjang paling hemat untuk bisnis mapan.',
        features: ['Semua Fitur Pro', 'Konsultasi Bisnis Eksklusif', 'Custom Domain (Coming Soon)', 'Backup Data Prioritas', 'Training Penggunaan Gratis'],
        ctaLink: 'https://wa.me/62851?text=Halo+Admin%2C+saya+tertarik+untuk+berlangganan+Paket+Enterprise+%282+Tahun%29',
    },
];

export const Pricing = () => {
    return (
        <section id="pricing" className="py-20 relative overflow-hidden">
            <div className="absolute inset-0 bg-gradient-to-b from-white to-blue-50 dark:from-slate-950 dark:to-slate-900 -z-10" />

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="text-center mb-16">
                    <h2 className="text-3xl font-bold text-[var(--foreground)] mb-4">Investasi Terjangkau</h2>
                    <p className="text-[var(--muted-foreground)]">
                        Pilih paket yang sesuai dengan kebutuhan dan skala bisnis Anda.
                    </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                    {pricingPlans.map((plan, index) => (
                        <div
                            key={index}
                            className={`relative rounded-2xl p-8 transition-all duration-300 ${plan.isPopular
                                    ? 'bg-white dark:bg-slate-800 ring-2 ring-[var(--primary)] shadow-xl scale-105 z-10'
                                    : 'bg-white/50 dark:bg-slate-900/50 border border-[var(--border)] hover:shadow-lg'
                                }`}
                        >
                            {plan.isPopular && (
                                <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-[var(--accent)] text-white px-4 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                                    <Star size={14} fill="white" /> Paling Laris
                                </div>
                            )}

                            <div className="mb-6">
                                <h3 className="text-xl font-bold text-[var(--foreground)]">{plan.name}</h3>
                                <p className="text-sm text-[var(--muted-foreground)] mt-1">{plan.period}</p>
                            </div>

                            <div className="mb-6">
                                <span className="text-3xl font-bold text-[var(--primary)]">{plan.price}</span>
                                {/* <span className="text-sm text-[var(--muted-foreground)]">/{plan.period === 'Bulanan' ? 'bulan' : 'thn'}</span> */}
                            </div>

                            <p className="text-sm text-[var(--muted-foreground)] mb-8 min-h-[40px]">
                                {plan.description}
                            </p>

                            <div className="space-y-4 mb-8">
                                {plan.features.map((feature, i) => (
                                    <div key={i} className="flex items-start gap-3 text-sm text-[var(--foreground)]">
                                        <Check size={18} className="text-green-500 shrink-0 mt-0.5" />
                                        <span>{feature}</span>
                                    </div>
                                ))}
                            </div>

                            <Button
                                variant={plan.isPopular ? 'primary' : 'outline'}
                                className="w-full"
                                onClick={() => window.open(plan.ctaLink, '_blank')}
                            >
                                Pilih Paket Ini
                            </Button>
                        </div>
                    ))}
                </div>
            </div>
        </section>
    );
};
