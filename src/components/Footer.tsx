import React from 'react';
import Link from 'next/link';

export const Footer = () => {
    return (
        <footer className="bg-slate-50 dark:bg-slate-950 pt-16 pb-8 border-t border-[var(--border)]">
            <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-12 mb-12">
                    {/* Brand */}
                    <div>
                        <h3 className="text-2xl font-bold text-[var(--primary)] mb-4">Cashiro</h3>
                        <p className="text-sm text-[var(--muted-foreground)] leading-relaxed">
                            Solusi kasir pintar terintegrasi cloud untuk membantu UMKM Indonesia naik kelas.
                        </p>
                    </div>

                    {/* Links 1 */}
                    <div>
                        <h4 className="font-semibold text-[var(--foreground)] mb-4">Produk</h4>
                        <ul className="space-y-2 text-sm text-[var(--muted-foreground)]">
                            <li><Link href="#features" className="hover:text-[var(--primary)]">Sistem Kasir</Link></li>
                            <li><Link href="#pricing" className="hover:text-[var(--primary)]">Harga Paket</Link></li>
                            <li><Link href="/download" className="hover:text-[var(--primary)]">Download App</Link></li>
                        </ul>
                    </div>

                    {/* Links 2 */}
                    <div>
                        <h4 className="font-semibold text-[var(--foreground)] mb-4">Dukungan</h4>
                        <ul className="space-y-2 text-sm text-[var(--muted-foreground)]">
                            <li><Link href="/help" className="hover:text-[var(--primary)]">Pusat Bantuan</Link></li>
                            <li><Link href="/guide" className="hover:text-[var(--primary)]">Panduan Penggunaan</Link></li>
                            <li><Link href="/privacy-policy" className="hover:text-[var(--primary)]">Kebijakan Privasi</Link></li>
                            <li><Link href="/delete-account" className="hover:text-[var(--primary)]">Hapus Akun</Link></li>
                        </ul>
                    </div>

                    {/* Contact */}
                    <div>
                        <h4 className="font-semibold text-[var(--foreground)] mb-4">Hubungi Kami</h4>
                        <p className="text-sm text-[var(--muted-foreground)] mb-2">
                            Punya pertanyaan? Tim kami siap membantu Anda 24/7.
                        </p>
                        <a href="https://wa.me/6285157578692" className="text-sm font-medium text-[var(--primary)] hover:underline">
                            Chat via WhatsApp
                        </a>
                    </div>
                </div>

                <div className="pt-8 border-t border-[var(--border)] text-center text-sm text-[var(--muted-foreground)]">
                    <p>&copy; {new Date().getFullYear()} Cashiro. All rights reserved.</p>
                </div>
            </div>
        </footer>
    );
};
