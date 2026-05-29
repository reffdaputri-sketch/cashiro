"use client";

import React, { useState } from 'react';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import { Button } from '@/components/Button';
import { Trash2, AlertTriangle, CheckCircle, Send, Mail } from 'lucide-react';

export default function DeleteAccount() {
    const [formData, setFormData] = useState({
        name: '',
        identifier: '',
        reason: ''
    });

    const handleSubmit = (e: React.FormEvent) => {
        e.preventDefault();

        const subject = `Permohonan Hapus Akun Cashiro - ${formData.name}` ;
        const body = `Halo Admin Cashiro,

Saya ingin mengajukan permohonan penghapusan akun secara permanen.

Berikut data akun saya:
Nama Lengkap: ${formData.name}
Email/No. HP: ${formData.identifier}

Alasan Penghapusan:
${formData.reason}

Saya mengerti bahwa tindakan ini akan menghapus seluruh data saya secara permanen dan tidak dapat dibatalkan.

Terima kasih.`;

        const mailtoLink = `mailto:admin@cashiro.biz.id?subject=${encodeURIComponent(subject)}&body=${encodeURIComponent(body)}` ;
        window.location.href = mailtoLink;
    };

    const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => {
        setFormData({
            ...formData,
            [e.target.name]: e.target.value
        });
    };

    return (
        <main className="min-h-screen bg-[var(--background)]">
            <Navbar />
            <div className="pt-32 pb-20 max-w-3xl mx-auto px-4 sm:px-6 lg:px-8">

                <div className="bg-red-50 dark:bg-red-900/10 border border-red-200 dark:border-red-900 rounded-2xl p-8 mb-8 text-center">
                    <div className="w-16 h-16 bg-red-100 dark:bg-red-900/30 rounded-full flex items-center justify-center mx-auto mb-4">
                        <Trash2 className="w-8 h-8 text-red-600 dark:text-red-400" />
                    </div>
                    <h1 className="text-3xl font-bold text-[var(--foreground)] mb-2">Permintaan Hapus Akun</h1>
                    <p className="text-[var(--muted-foreground)]">
                        Isi formulir di bawah ini untuk mengajukan penghapusan akun secara resmi ke admin kami.
                    </p>
                </div>

                <div className="grid md:grid-cols-2 gap-8">
                    <div className="prose dark:prose-invert max-w-none text-[var(--muted-foreground)]">
                        <div className="bg-[var(--card)] border border-[var(--border)] rounded-xl p-6 shadow-sm h-full">
                            <h2 className="text-lg font-semibold text-[var(--foreground)] flex items-center gap-2 mb-4">
                                <AlertTriangle className="w-5 h-5 text-orange-500" />
                                Konsekuensi Penghapusan
                            </h2>
                            <ul className="space-y-3 text-sm">
                                <li className="flex items-start gap-2">
                                    <CheckCircle className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
                                    <span>Semua data profil (Nama, Email, No HP) dihapus permanen.</span>
                                </li>
                                <li className="flex items-start gap-2">
                                    <CheckCircle className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
                                    <span>Riwayat transaksi dan laporan bisnis hilang.</span>
                                </li>
                                <li className="flex items-start gap-2">
                                    <CheckCircle className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
                                    <span>Website toko online tidak dapat diakses lagi.</span>
                                </li>
                                <li className="flex items-start gap-2">
                                    <CheckCircle className="w-4 h-4 text-red-500 mt-0.5 shrink-0" />
                                    <span>Tindakan ini <strong>tidak dapat dibatalkan</strong>.</span>
                                </li>
                            </ul>
                        </div>
                    </div>

                    <div className="bg-[var(--card)] border border-[var(--border)] rounded-xl p-6 shadow-sm">
                        <h2 className="text-lg font-semibold text-[var(--foreground)] mb-6 flex items-center gap-2">
                            <Mail className="w-5 h-5 text-[var(--primary)]" />
                            Formulir Pengajuan
                        </h2>

                        <form onSubmit={handleSubmit} className="space-y-4">
                            <div>
                                <label className="block text-sm font-medium text-[var(--foreground)] mb-1">
                                    Nama Lengkap
                                </label>
                                <input
                                    type="text"
                                    name="name"
                                    required
                                    value={formData.name}
                                    onChange={handleChange}
                                    className="w-full px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-[var(--foreground)] focus:ring-2 focus:ring-[var(--primary)] outline-none"
                                    placeholder="Contoh: Budi Santoso"
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-[var(--foreground)] mb-1">
                                    Email / Nomor HP Terdaftar
                                </label>
                                <input
                                    type="text"
                                    name="identifier"
                                    required
                                    value={formData.identifier}
                                    onChange={handleChange}
                                    className="w-full px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-[var(--foreground)] focus:ring-2 focus:ring-[var(--primary)] outline-none"
                                    placeholder="Contoh: budi@gmail.com / 08123..."
                                />
                            </div>

                            <div>
                                <label className="block text-sm font-medium text-[var(--foreground)] mb-1">
                                    Alasan Penghapusan
                                </label>
                                <textarea
                                    name="reason"
                                    required
                                    value={formData.reason}
                                    onChange={handleChange}
                                    rows={3}
                                    className="w-full px-3 py-2 rounded-lg border border-[var(--border)] bg-[var(--background)] text-[var(--foreground)] focus:ring-2 focus:ring-[var(--primary)] outline-none"
                                    placeholder="Mengapa Anda ingin menghapus akun?"
                                />
                            </div>

                            <Button type="submit" variant="primary" className="w-full bg-red-600 hover:bg-red-700 shadow-red-500/30 gap-2">
                                <Send size={16} />
                                Kirim Permohonan
                            </Button>
                            <p className="text-xs text-center text-[var(--muted-foreground)] mt-2">
                                Akan membuka aplikasi email Anda
                            </p>
                        </form>
                    </div>
                </div>
            </div>
            <Footer />
        </main>
    );
}
