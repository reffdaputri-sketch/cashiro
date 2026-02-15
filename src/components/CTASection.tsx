"use client";

import React from 'react';
import { Button } from './Button';
import { ArrowRight } from 'lucide-react';

export const CTASection = () => {
    return (
        <section className="py-20 bg-[var(--primary)] text-white relative overflow-hidden">
            {/* Background Patterns */}
            <div className="absolute top-0 left-0 w-64 h-64 bg-white/10 rounded-full blur-3xl -translate-x-1/2 -translate-y-1/2" />
            <div className="absolute bottom-0 right-0 w-96 h-96 bg-white/10 rounded-full blur-3xl translate-x-1/2 translate-y-1/2" />

            <div className="max-w-4xl mx-auto px-4 text-center relative z-10">
                <h2 className="text-3xl md:text-5xl font-bold mb-6">
                    Siap Meningkatkan Omzet Bisnis Anda?
                </h2>
                <p className="text-blue-100 text-lg mb-8 max-w-2xl mx-auto">
                    Gabung dengan 5.000+ UMKM lainnya yang telah beralih ke Kiosly. Buat website toko online Anda sekarang, gratis!
                </p>
                <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                    <Button size="lg" className="bg-white text-[var(--primary)] hover:bg-gray-100 w-full sm:w-auto">
                        Mulai Sekarang Gratis
                    </Button>
                    <Button size="lg" variant="outline" className="border-white text-white hover:bg-white/10 w-full sm:w-auto gap-2">
                        Konsultasi via WhatsApp <ArrowRight size={18} />
                    </Button>
                </div>
            </div>
        </section>
    );
};
