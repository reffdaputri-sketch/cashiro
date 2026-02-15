"use client";

import React from 'react';
import { motion } from 'framer-motion';

const stats = [
    { label: 'Bisnis Terdaftar', value: '5,000+' },
    { label: 'Transaksi Bulanan', value: '1M+' },
    { label: 'Rating App Store', value: '4.8/5' },
    { label: 'Kota Dijangkau', value: '100+' },
];

export const Stats = () => {
    return (
        <section className="py-12 bg-[var(--primary)] text-[var(--primary-foreground)]">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="grid grid-cols-2 md:grid-cols-4 gap-8 text-center divide-x divide-blue-400/30">
                    {stats.map((stat, index) => (
                        <motion.div
                            key={index}
                            initial={{ opacity: 0, scale: 0.9 }}
                            whileInView={{ opacity: 1, scale: 1 }}
                            transition={{ duration: 0.5, delay: index * 0.1 }}
                            viewport={{ once: true }}
                            className="p-4"
                        >
                            <h3 className="text-4xl font-bold mb-2">{stat.value}</h3>
                            <p className="text-blue-100 font-medium">{stat.label}</p>
                        </motion.div>
                    ))}
                </div>
            </div>
        </section>
    );
};
