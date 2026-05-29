"use client";

import React from 'react';
import { Button } from './Button';
import { Check, Star } from 'lucide-react';

const pricingPlans = [
    {
        name: 'Lifetime Access',
        period: 'Sekali Bayar Selamanya',
        price: 'IDR 50.000',
        description: 'Akses penuh ke semua fitur Cashiro POS selamanya tanpa biaya bulanan atau tahunan.',
        features: ['Aplikasi Kasir Android', 'Laporan Laba Rugi Otomatis', 'Manajemen Stok & Kategori', 'Backup & Sinkronisasi Cloud', 'Manajemen Staf & Pelanggan', 'Support via WhatsApp'],
        isPopular: true,
        ctaLink: 'https://wa.me/62851?text=Halo+Admin%2C+saya+tertarik+untuk+berlangganan+Lisensi+Cashiro+Lifetime',
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
                        Miliki aplikasi kasir profesional dengan skema sekali bayar, tanpa biaya tambahan lainnya.
                    </p>
                </div>

                <div className="max-w-md mx-auto">
                    {pricingPlans.map((plan, index) => (
                        <div
                            key={index}
                            className="relative rounded-2xl p-8 transition-all duration-300 bg-white dark:bg-slate-800 ring-2 ring-[var(--primary)] shadow-xl z-10"
                        >
                            <div className="absolute top-0 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-[var(--accent)] text-white px-4 py-1 rounded-full text-sm font-semibold flex items-center gap-1">
                                <Star size={14} fill="white" /> Sekali Bayar
                            </div>

                            <div className="mb-6">
                                <h3 className="text-xl font-bold text-[var(--foreground)]">{plan.name}</h3>
                                <p className="text-sm text-[var(--muted-foreground)] mt-1">{plan.period}</p>
                            </div>

                            <div className="mb-6">
                                <span className="text-3xl font-bold text-[var(--primary)]">{plan.price}</span>
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
                                variant="primary"
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
