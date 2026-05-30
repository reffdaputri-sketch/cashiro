'use client';

import { useState } from 'react';
import Image from 'next/image';
import Link from 'next/link';
import { Navbar } from '@/components/Navbar';
import { Footer } from '@/components/Footer';
import {
  Store,
  Mail,
  Phone,
  ShieldCheck,
  CheckCircle2,
  ArrowRight,
  Cloud,
  BarChart3,
  Users,
  RefreshCw,
  Globe,
  Gift,
  Lock,
  Headphones,
  Star,
} from 'lucide-react';
import { motion } from 'framer-motion';

const features = [
  {
    icon: Store,
    title: 'Kasir Modern & Cepat',
    desc: 'Transaksi penjualan lebih cepat dengan antarmuka yang mudah dipahami.',
    color: 'bg-blue-50 text-blue-600',
  },
  {
    icon: Cloud,
    title: 'Offline + Cloud Sync',
    desc: 'Tetap bisa beroperasi tanpa internet. Data sync otomatis saat online.',
    color: 'bg-indigo-50 text-indigo-600',
  },
  {
    icon: BarChart3,
    title: 'Laporan Lengkap',
    desc: 'Laporan laba rugi, stok, dan penjualan tersedia secara real-time.',
    color: 'bg-orange-50 text-orange-600',
  },
  {
    icon: Globe,
    title: 'Toko Online Instan',
    desc: 'Produk kasir Anda langsung tampil di halaman toko online Cashiro.',
    color: 'bg-green-50 text-green-600',
  },
  {
    icon: Users,
    title: 'Manajemen Pelanggan',
    desc: 'Simpan data pelanggan dan riwayat transaksi dengan mudah.',
    color: 'bg-purple-50 text-purple-600',
  },
  {
    icon: Gift,
    title: 'Program Referral',
    desc: 'Ajak teman pakai Cashiro dan dapatkan reward menarik secara otomatis.',
    color: 'bg-pink-50 text-pink-600',
  },
];

const testimonials = [
  {
    name: 'Siti Rahma',
    store: 'Toko Berkah Jaya',
    text: 'Cashiro sangat membantu usaha saya! Laporan keuangan jadi lebih rapi dan mudah dipantau kapan saja.',
    rating: 5,
  },
  {
    name: 'Ahmad Fauzi',
    store: 'Warung Pak Fauzi',
    text: 'Harga sangat terjangkau, tapi fiturnya lengkap. Satu kali bayar, seumur hidup pakai!',
    rating: 5,
  },
  {
    name: 'Dewi Anggraini',
    store: 'Butik Dewi Fashion',
    text: 'Sinkronisasi otomatis ke cloud bikin saya tenang. Data tidak pernah hilang meskipun HP rusak.',
    rating: 5,
  },
];

export default function BeliPage() {
  const [storeName, setStoreName] = useState('');
  const [email, setEmail] = useState('');
  const [waNumber, setWaNumber] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState(false);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsLoading(true);
    setError('');

    try {
      const res = await fetch('/api/license/buy', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, store_name: storeName, wa_number: waNumber }),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error || 'Gagal memproses pembayaran');

      setSuccess(true);

      try {
        localStorage.setItem(
          `pending_order_${data.order_id}`,
          JSON.stringify({ email, store_name: storeName, wa_number: waNumber })
        );
      } catch (e) {
        console.error('Failed to save pending order info:', e);
      }

      window.location.href = data.payment_url;
    } catch (err: any) {
      setError(err.message);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-white text-slate-800">
      <Navbar />

      {/* ─── HERO: Promo Banner ─── */}
      <section className="pt-20 bg-gradient-to-br from-blue-50 via-white to-indigo-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-16 md:py-20">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            {/* Left – Text */}
            <motion.div initial={{ opacity: 0, x: -24 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.5 }}>
              <span className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-100 text-blue-700 text-sm font-semibold mb-5">
                <ShieldCheck className="w-4 h-4" /> Lisensi Seumur Hidup
              </span>
              <h1 className="text-4xl md:text-5xl font-bold text-slate-900 leading-tight mb-5">
                Kelola Toko Lebih{' '}
                <span className="text-transparent bg-clip-text bg-gradient-to-r from-blue-600 to-indigo-500">
                  Cerdas
                </span>{' '}
                dengan Cashiro
              </h1>
              <p className="text-lg text-slate-500 mb-8 leading-relaxed">
                Aplikasi kasir cloud terlengkap untuk UMKM Indonesia. Offline tetap jalan, auto sync
                ke cloud, plus toko online langsung siap pakai.
              </p>

              {/* Highlights */}
              <div className="grid grid-cols-2 gap-3 mb-8">
                {[
                  'Offline + Cloud Sync',
                  'Toko Online Gratis',
                  'Laporan Laba Rugi',
                  'Program Referral',
                  'Manajemen Stok',
                  'Support WhatsApp',
                ].map((item) => (
                  <div key={item} className="flex items-center gap-2 text-slate-700 text-sm">
                    <CheckCircle2 className="w-4 h-4 text-green-500 shrink-0" />
                    {item}
                  </div>
                ))}
              </div>

              {/* Price Badge */}
              <div className="inline-flex items-center gap-4 bg-white border-2 border-blue-200 rounded-2xl px-6 py-4 shadow-md shadow-blue-100">
                <div>
                  <p className="text-xs text-slate-400 font-medium uppercase tracking-wider">Harga Lisensi</p>
                  <p className="text-4xl font-black text-blue-600">Rp 25.000</p>
                  <p className="text-xs text-slate-500">Sekali bayar • Selamanya</p>
                </div>
                <div className="h-14 w-px bg-slate-200" />
                <div className="text-center">
                  <p className="text-xs text-slate-400 font-medium">Sudah dipercaya</p>
                  <p className="text-2xl font-bold text-slate-800">500+</p>
                  <p className="text-xs text-slate-400">pemilik toko</p>
                </div>
              </div>
            </motion.div>

            {/* Right – Promo Image */}
            <motion.div
              initial={{ opacity: 0, x: 24 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ duration: 0.5, delay: 0.1 }}
              className="relative"
            >
              <div className="relative rounded-3xl overflow-hidden shadow-2xl shadow-blue-200/50 border border-blue-100">
                <Image
                  src="/images/cashiro-promo.jpg"
                  alt="Cashiro – Bukan Cuma Kasir Offline, Fitur Mewah Harga Tetap Murah"
                  width={600}
                  height={600}
                  className="w-full h-auto object-cover"
                  priority
                />
              </div>
              {/* Floating badge */}
              <div className="absolute -bottom-4 -left-4 bg-white rounded-2xl px-4 py-3 shadow-lg border border-slate-100 flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-green-100 flex items-center justify-center">
                  <CheckCircle2 className="w-4 h-4 text-green-600" />
                </div>
                <div>
                  <p className="text-xs text-slate-400">Keamanan Data</p>
                  <p className="text-xs font-bold text-slate-700">Aman di Cloud</p>
                </div>
              </div>
            </motion.div>
          </div>
        </div>
      </section>

      {/* ─── FEATURES ─── */}
      <section className="py-20 bg-white">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-14">
            <h2 className="text-3xl font-bold text-slate-900 mb-3">
              Semua yang Anda Butuhkan, dalam Satu Aplikasi
            </h2>
            <p className="text-slate-500 max-w-2xl mx-auto">
              Cashiro hadir dengan fitur-fitur premium yang biasanya hanya ada di aplikasi kasir mahal.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
            {features.map((f, i) => (
              <motion.div
                key={f.title}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.08 }}
                className="group bg-white border border-slate-100 rounded-2xl p-6 hover:shadow-lg hover:shadow-slate-100 hover:border-blue-100 transition-all duration-300"
              >
                <div className={`w-12 h-12 rounded-xl flex items-center justify-center mb-4 ${f.color}`}>
                  <f.icon className="w-6 h-6" />
                </div>
                <h3 className="font-semibold text-slate-800 mb-2">{f.title}</h3>
                <p className="text-sm text-slate-500 leading-relaxed">{f.desc}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── TESTIMONIALS ─── */}
      <section className="py-20 bg-gradient-to-br from-blue-50 to-indigo-50">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="text-center mb-12">
            <h2 className="text-3xl font-bold text-slate-900 mb-3">Apa Kata Mereka?</h2>
            <p className="text-slate-500">Bergabunglah dengan ratusan pemilik toko yang sudah merasakan manfaatnya.</p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            {testimonials.map((t, i) => (
              <motion.div
                key={t.name}
                initial={{ opacity: 0, y: 20 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ delay: i * 0.1 }}
                className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100"
              >
                <div className="flex gap-1 mb-3">
                  {[...Array(t.rating)].map((_, j) => (
                    <Star key={j} className="w-4 h-4 fill-amber-400 text-amber-400" />
                  ))}
                </div>
                <p className="text-slate-600 text-sm leading-relaxed mb-4">"{t.text}"</p>
                <div>
                  <p className="font-semibold text-slate-800 text-sm">{t.name}</p>
                  <p className="text-xs text-slate-400">{t.store}</p>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* ─── PURCHASE FORM ─── */}
      <section id="beli-sekarang" className="py-20 bg-white">
        <div className="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start">

            {/* Left – Why Buy */}
            <motion.div initial={{ opacity: 0, x: -20 }} whileInView={{ opacity: 1, x: 0 }} viewport={{ once: true }}>
              <h2 className="text-3xl font-bold text-slate-900 mb-4">
                Mulai Pakai Cashiro Sekarang
              </h2>
              <p className="text-slate-500 mb-8 leading-relaxed">
                Hanya dengan <strong className="text-slate-800">Rp 25.000</strong> sekali bayar, dapatkan
                akses seumur hidup ke seluruh fitur Cashiro. Kode lisensi dikirim otomatis ke WhatsApp Anda.
              </p>

              <div className="space-y-4">
                {[
                  { icon: RefreshCw, text: 'Lisensi & link APK langsung dikirim ke WhatsApp Anda', color: 'text-blue-600 bg-blue-50' },
                  { icon: Lock, text: 'Pembayaran aman via Duitku (QRIS, Transfer, dll)', color: 'text-green-600 bg-green-50' },
                  { icon: ShieldCheck, text: 'Tidak perlu berlangganan — bayar sekali, pakai selamanya', color: 'text-orange-600 bg-orange-50' },
                  { icon: Headphones, text: 'Support responsif via WhatsApp 24/7', color: 'text-purple-600 bg-purple-50' },
                ].map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <div className={`w-9 h-9 rounded-xl flex items-center justify-center shrink-0 ${item.color}`}>
                      <item.icon className="w-4 h-4" />
                    </div>
                    <p className="text-slate-600 text-sm leading-relaxed pt-1">{item.text}</p>
                  </div>
                ))}
              </div>

              {/* Trust Badges */}
              <div className="mt-10 pt-8 border-t border-slate-100 grid grid-cols-3 gap-4 text-center">
                {[
                  { label: 'Pengguna Aktif', val: '500+' },
                  { label: 'Rating', val: '⭐ 4.9' },
                  { label: 'Support', val: '24/7' },
                ].map((b) => (
                  <div key={b.label}>
                    <p className="text-xl font-bold text-blue-600">{b.val}</p>
                    <p className="text-xs text-slate-400 mt-1">{b.label}</p>
                  </div>
                ))}
              </div>
            </motion.div>

            {/* Right – Form */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true }}
            >
              <div className="bg-white border-2 border-slate-100 rounded-3xl p-8 shadow-xl shadow-slate-100 relative overflow-hidden">
                {/* Top accent */}
                <div className="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-blue-500 via-indigo-500 to-blue-600 rounded-t-3xl" />

                <div className="text-center mb-7">
                  <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-semibold mb-3">
                    <ShieldCheck className="w-3.5 h-3.5" /> Pembayaran Aman & Terenkripsi
                  </div>
                  <h3 className="text-2xl font-bold text-slate-900">Beli Lisensi Cashiro</h3>
                  <p className="text-slate-400 text-sm mt-1">Isi data di bawah untuk melanjutkan pembayaran</p>
                </div>

                {/* Price tag */}
                <div className="bg-gradient-to-r from-blue-600 to-indigo-600 rounded-2xl p-4 mb-6 text-center text-white">
                  <p className="text-xs font-medium opacity-80 mb-1">Harga Lisensi Seumur Hidup</p>
                  <p className="text-4xl font-black tracking-tight">Rp 25.000</p>
                  <p className="text-xs opacity-70 mt-1">Sekali bayar · Tidak ada biaya bulanan</p>
                </div>

                {error && (
                  <div className="bg-red-50 border border-red-200 text-red-600 p-4 rounded-xl mb-5 text-sm flex items-start gap-2">
                    <span className="shrink-0">⚠️</span>
                    <span>{error}</span>
                  </div>
                )}

                {success ? (
                  <div className="text-center py-8">
                    <div className="w-16 h-16 bg-blue-50 rounded-full flex items-center justify-center mx-auto mb-4">
                      <RefreshCw className="w-7 h-7 text-blue-500 animate-spin" />
                    </div>
                    <h4 className="text-lg font-bold text-slate-800 mb-1">Mengarahkan ke Pembayaran...</h4>
                    <p className="text-sm text-slate-400">Selesaikan pembayaran di halaman Duitku yang terbuka.</p>
                  </div>
                ) : (
                  <form onSubmit={handleSubmit} className="space-y-4">
                    {/* Store Name */}
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1.5">Nama Toko</label>
                      <div className="relative">
                        <Store className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                        <input
                          type="text"
                          required
                          value={storeName}
                          onChange={(e) => setStoreName(e.target.value)}
                          placeholder="Contoh: Toko Berkah"
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all"
                        />
                      </div>
                    </div>

                    {/* Email */}
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1.5">Email</label>
                      <div className="relative">
                        <Mail className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                        <input
                          type="email"
                          required
                          value={email}
                          onChange={(e) => setEmail(e.target.value)}
                          placeholder="email@anda.com"
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all"
                        />
                      </div>
                    </div>

                    {/* WhatsApp */}
                    <div>
                      <label className="block text-sm font-medium text-slate-700 mb-1.5">
                        No. WhatsApp
                        <span className="ml-1 text-xs font-normal text-slate-400">(format: 08xxx atau 628xxx)</span>
                      </label>
                      <div className="relative">
                        <Phone className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
                        <input
                          type="tel"
                          required
                          value={waNumber}
                          onChange={(e) => setWaNumber(e.target.value)}
                          placeholder="08123456789"
                          className="w-full bg-slate-50 border border-slate-200 rounded-xl py-3 pl-10 pr-4 text-slate-800 placeholder:text-slate-400 focus:outline-none focus:border-blue-400 focus:ring-2 focus:ring-blue-100 transition-all"
                        />
                      </div>
                      <p className="text-xs text-slate-400 mt-1.5">
                        ✉️ Kode lisensi & link download APK dikirim ke nomor ini setelah pembayaran.
                      </p>
                    </div>

                    <button
                      type="submit"
                      id="btn-beli-lisensi"
                      disabled={isLoading}
                      className="w-full mt-2 flex items-center justify-center gap-2 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 active:scale-[0.98] text-white font-semibold py-4 rounded-xl shadow-lg shadow-blue-200 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                    >
                      {isLoading ? (
                        <>
                          <RefreshCw className="w-4 h-4 animate-spin" /> Memproses...
                        </>
                      ) : (
                        <>
                          Bayar Sekarang – Rp 25.000 <ArrowRight className="w-4 h-4" />
                        </>
                      )}
                    </button>
                  </form>
                )}
              </div>

              {/* Mini trust badges below form */}
              <div className="mt-4 flex items-center justify-center gap-6 text-xs text-slate-400">
                <span className="flex items-center gap-1"><Lock className="w-3 h-3" /> SSL Aman</span>
                <span className="flex items-center gap-1"><ShieldCheck className="w-3 h-3" /> Duitku Verified</span>
                <span className="flex items-center gap-1"><RefreshCw className="w-3 h-3" /> Refund Policy</span>
              </div>
            </motion.div>

          </div>
        </div>
      </section>

      <Footer />
    </main>
  );
}
