import React from 'react';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';

export default function PrivacyPolicy() {
    return (
        <main className="min-h-screen bg-[var(--background)]">
            <Navbar />
            <div className="pt-32 pb-20 max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
                <h1 className="text-3xl font-bold text-[var(--foreground)] mb-8">Kebijakan Privasi</h1>

                <div className="prose dark:prose-invert max-w-none text-[var(--muted-foreground)]">
                    <p className="mb-4">
                        Terakhir diperbarui: {new Date().toLocaleDateString('id-ID', { year: 'numeric', month: 'long', day: 'numeric' })}
                    </p>

                    <p className="mb-6">
                        Cashiro ("kami", "kita", atau "milik kami") mengoperasikan aplikasi mobile Cashiro dan website cashiro.web.id.
                        Halaman ini memberitahu Anda tentang kebijakan kami mengenai pengumpulan, penggunaan, dan pengungkapan Data Pribadi saat Anda menggunakan Layanan kami.
                    </p>

                    <h2 className="text-xl font-semibold text-[var(--foreground)] mt-8 mb-4">1. Pengumpulan dan Penggunaan Data</h2>
                    <p className="mb-4">
                        Kami mengumpulkan beberapa jenis informasi untuk berbagai tujuan guna menyediakan dan meningkatkan Layanan kami kepada Anda.
                    </p>

                    <h3 className="text-lg font-medium text-[var(--foreground)] mt-6 mb-2">Jenis Data yang Dikumpulkan</h3>
                    <ul className="list-disc pl-5 mb-4 space-y-2">
                        <li><strong>Data Pribadi:</strong> Saat menggunakan Layanan kami, kami mungkin meminta Anda untuk memberikan informasi pengenal pribadi tertentu, termasuk namun tidak terbatas pada: Alamat Email, Nama Depan dan Belakang, Nomor Telepon, dan Data Cookies.</li>
                        <li><strong>Data Transaksi:</strong> Kami merekam detail transaksi yang Anda lakukan melalui aplikasi untuk keperluan riwayat dan laporan bisnis Anda.</li>
                        <li><strong>Data Perangkat:</strong> Kami dapat mengumpulkan informasi tentang perangkat yang Anda gunakan untuk mengakses Layanan, seperti model perangkat keras, sistem operasi, dan pengenal unik perangkat.</li>
                    </ul>

                    <h2 className="text-xl font-semibold text-[var(--foreground)] mt-8 mb-4">2. Penggunaan Data</h2>
                    <p className="mb-4">Cashiro menggunakan data yang dikumpulkan untuk berbagai tujuan:</p>
                    <ul className="list-disc pl-5 mb-4 space-y-2">
                        <li>Untuk menyediakan dan memelihara Layanan kami</li>
                        <li>Untuk memberitahu Anda tentang perubahan pada Layanan kami</li>
                        <li>Untuk memungkinkan Anda berpartisipasi dalam fitur interaktif Layanan kami</li>
                        <li>Untuk memberikan dukungan pelanggan</li>
                        <li>Untuk memantau penggunaan Layanan</li>
                        <li>Untuk mendeteksi, mencegah, dan mengatasi masalah teknis</li>
                    </ul>

                    <h2 className="text-xl font-semibold text-[var(--foreground)] mt-8 mb-4">3. Keamanan Data</h2>
                    <p className="mb-6">
                        Keamanan data Anda penting bagi kami, namun ingat bahwa tidak ada metode transmisi melalui Internet atau metode penyimpanan elektronik yang 100% aman.
                        Meskipun kami berusaha menggunakan cara yang dapat diterima secara komersial untuk melindungi Data Pribadi Anda, kami tidak dapat menjamin keamanannya secara mutlak.
                    </p>

                    <h2 className="text-xl font-semibold text-[var(--foreground)] mt-8 mb-4">4. Hak Anda</h2>
                    <p className="mb-6">
                        Anda memiliki hak untuk mengakses, memperbarui, atau menghapus informasi yang kami miliki tentang Anda.
                        Jika Anda ingin menggunakan hak ini, silakan hubungi kami atau gunakan fitur "Hapus Akun" yang tersedia di aplikasi atau website kami.
                    </p>

                    <h2 className="text-xl font-semibold text-[var(--foreground)] mt-8 mb-4">5. Hubungi Kami</h2>
                    <p className="mb-4">
                        Jika Anda memiliki pertanyaan tentang Kebijakan Privasi ini, silakan hubungi kami:
                    </p>

                </div>
            </div>
            <Footer />
        </main>
    );
}
