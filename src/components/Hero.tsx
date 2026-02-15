"use client";

import React from 'react';
import { Button } from './Button';
import { motion } from 'framer-motion';
import { ArrowRight, Download, CheckCircle } from 'lucide-react';
import Image from 'next/image';

export const Hero = () => {
    return (
        <section className="relative pt-32 pb-20 lg:pt-48 lg:pb-32 overflow-hidden">
            {/* Background Decor */}
            <div className="absolute top-0 left-1/2 -translate-x-1/2 w-full h-full -z-10">
                <div className="absolute inset-0 bg-gradient-to-b from-blue-50 to-white dark:from-slate-900 dark:to-slate-950" />
                <div className="absolute top-0 left-1/2 -translate-x-1/2 w-[1000px] h-[600px] bg-blue-200/20 dark:bg-blue-900/20 rounded-full blur-3xl opacity-50" />
            </div>

            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 text-center">
                <motion.div
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.5 }}
                >
                    <span className="inline-block py-1 px-3 rounded-full bg-blue-100 dark:bg-blue-900/30 text-[var(--primary)] text-sm font-semibold mb-6">
                        🚀 Solusi #1 untuk UMKM Indonesia
                    </span>
                    <h1 className="text-4xl md:text-6xl lg:text-7xl font-bold tracking-tight text-[var(--foreground)] mb-6">
                        Kelola Stok & Jualan Online <br className="hidden md:block" />
                        <span className="text-transparent bg-clip-text bg-gradient-to-r from-[var(--primary)] to-blue-400">
                            Dalam Satu Aplikasi
                        </span>
                    </h1>
                    <p className="text-lg md:text-xl text-[var(--muted-foreground)] max-w-2xl mx-auto mb-10">
                        Aplikasi Kasir Cloud + Website Toko Online Instan. Pantau bisnis dari mana saja, kapan saja. Tanpa biaya tersembunyi.
                    </p>

                    <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
                        <Button size="lg" className="w-full sm:w-auto gap-2">
                            Daftar Sekarang <ArrowRight size={20} />
                        </Button>
                        <Button size="lg" variant="outline" className="w-full sm:w-auto gap-2">
                            <Download size={20} /> Download App
                        </Button>
                    </div>

                    <div className="mt-8 flex items-center justify-center gap-6 text-sm text-[var(--muted-foreground)]">
                        <div className="flex items-center gap-1">
                            <CheckCircle size={16} className="text-green-500" /> Gratis Website
                        </div>
                        <div className="flex items-center gap-1">
                            <CheckCircle size={16} className="text-green-500" /> Cloud Backup
                        </div>
                        <div className="flex items-center gap-1">
                            <CheckCircle size={16} className="text-green-500" /> Support 24/7
                        </div>
                    </div>
                </motion.div>

                {/* Dashboard Preview / Visual */}
                <motion.div
                    initial={{ opacity: 0, y: 40 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ duration: 0.8, delay: 0.2 }}
                    className="mt-16 mx-auto max-w-5xl"
                >
                    <div className="relative rounded-2xl border border-[var(--border)] bg-white dark:bg-slate-900 shadow-2xl overflow-hidden aspect-[16/9] group">
                        {/* 
                            USER INSTRUCTION: 
                            1. Masukan foto anda ke folder: public/images/
                            2. Beri nama file: dashboard.png
                        */}
                        <Image
                            src="/images/dashboard.png"
                            alt="Kiosly Dashboard Preview"
                            fill
                            className="object-cover object-top"
                            priority
                        />

                        {/* Overlay Gradient */}
                        <div className="absolute inset-0 bg-gradient-to-t from-white/20 to-transparent dark:from-black/20 pointer-events-none" />
                    </div>
                </motion.div>
            </div>
        </section>
    );
};
