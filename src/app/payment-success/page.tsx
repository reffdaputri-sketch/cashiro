'use client';

import { useEffect, useState, useRef } from 'react';
import { useSearchParams } from 'next/navigation';
import { CheckCircle2, Copy, Check, XCircle, Loader2, MessageCircle, Download } from 'lucide-react';
import { Suspense } from 'react';

function PaymentSuccessContent() {
  const searchParams = useSearchParams();
  const merchantOrderId = searchParams.get('merchantOrderId');
  const resultCode = searchParams.get('resultCode');

  const [status, setStatus] = useState<'loading' | 'success' | 'failed' | 'error'>('loading');
  const [licenseKey, setLicenseKey] = useState('');
  const [storeName, setStoreName] = useState('');
  const [waNumber, setWaNumber] = useState('');
  const [errorMsg, setErrorMsg] = useState('');
  const [copied, setCopied] = useState(false);
  const hasCalled = useRef(false);

  useEffect(() => {
    if (hasCalled.current) return;
    hasCalled.current = true;

    if (resultCode !== '00' || !merchantOrderId) {
      setStatus('failed');
      return;
    }

    const verify = async () => {
      try {
        let pendingInfo: any = {};
        try {
          const stored = localStorage.getItem(`pending_order_${merchantOrderId}`);
          if (stored) {
            pendingInfo = JSON.parse(stored);
            localStorage.removeItem(`pending_order_${merchantOrderId}`);
          }
        } catch (e) {
          console.error('Failed to read pending order info:', e);
        }

        const res = await fetch('/api/license/verify-payment', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            merchantOrderId,
            email: pendingInfo.email,
            store_name: pendingInfo.store_name,
            wa_number: pendingInfo.wa_number
          }),
        });
        const data = await res.json();

        if (!res.ok) {
          setErrorMsg(data.error || 'Verifikasi gagal');
          setStatus('error');
          return;
        }

        setLicenseKey(data.license_key);
        setStoreName(data.store_name || '');
        setWaNumber(data.wa_number || '');
        setStatus('success');
      } catch (e: any) {
        setErrorMsg(e.message);
        setStatus('error');
      }
    };

    verify();
  }, [merchantOrderId, resultCode]);

  const copyKey = () => {
    navigator.clipboard.writeText(licenseKey);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <main className="min-h-screen bg-[#0F172A] flex items-center justify-center p-6">
      {/* Background blobs */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-1/4 left-1/4 w-[500px] h-[500px] bg-teal-500/8 rounded-full blur-[120px]" />
        <div className="absolute bottom-1/4 right-1/4 w-[400px] h-[400px] bg-blue-500/8 rounded-full blur-[100px]" />
      </div>

      <div className="relative z-10 w-full max-w-md">

        {/* LOADING */}
        {status === 'loading' && (
          <div className="bg-slate-800/60 backdrop-blur-xl border border-slate-700/50 rounded-3xl p-10 shadow-2xl text-center">
            <div className="w-20 h-20 bg-blue-500/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <Loader2 className="w-10 h-10 text-blue-400 animate-spin" />
            </div>
            <h1 className="text-2xl font-bold text-white mb-2">Memverifikasi Pembayaran</h1>
            <p className="text-slate-400 text-sm">Mohon tunggu, sedang mengkonfirmasi transaksi Anda...</p>
          </div>
        )}

        {/* SUCCESS */}
        {status === 'success' && (
          <div className="bg-slate-800/60 backdrop-blur-xl border border-slate-700/50 rounded-3xl p-8 shadow-2xl">
            {/* Icon */}
            <div className="text-center mb-6">
              <div className="w-20 h-20 bg-teal-500/15 rounded-full flex items-center justify-center mx-auto mb-4 ring-4 ring-teal-500/20">
                <CheckCircle2 className="w-10 h-10 text-teal-400" />
              </div>
              <h1 className="text-2xl font-bold text-white mb-1">Pembayaran Berhasil! 🎉</h1>
              {storeName && (
                <p className="text-slate-400 text-sm">Toko: <span className="text-slate-200 font-medium">{storeName}</span></p>
              )}
            </div>

            {/* License Key Card */}
            <div className="bg-slate-900/80 border border-teal-500/20 rounded-2xl p-5 mb-5">
              <p className="text-xs font-semibold text-slate-500 uppercase mb-2 tracking-wider">Kode Lisensi Anda</p>
              <div className="flex items-center justify-between gap-3">
                <span className="font-mono text-xl font-bold text-teal-400 tracking-widest">{licenseKey}</span>
                <button
                  onClick={copyKey}
                  className="flex-shrink-0 p-2.5 bg-slate-800 hover:bg-slate-700 rounded-xl text-slate-400 hover:text-white transition-all cursor-pointer"
                >
                  {copied ? <Check className="w-4 h-4 text-green-400" /> : <Copy className="w-4 h-4" />}
                </button>
              </div>
              {copied && <p className="text-xs text-green-400 mt-2">✓ Disalin ke clipboard!</p>}
            </div>

            {/* WA Notification Info */}
            {waNumber && (
              <div className="flex items-start gap-3 bg-green-500/5 border border-green-500/20 rounded-xl p-4 mb-5">
                <MessageCircle className="w-5 h-5 text-green-400 shrink-0 mt-0.5" />
                <p className="text-sm text-slate-300">
                  Kode lisensi & link download sudah dikirim ke WhatsApp{' '}
                  <span className="text-green-400 font-medium">{waNumber}</span>
                </p>
              </div>
            )}

            {/* Steps */}
            <div className="space-y-3 mb-6">
              <p className="text-sm font-semibold text-slate-300">Langkah selanjutnya:</p>
              {[
                'Download aplikasi Cashiro via link di WhatsApp',
                'Buka aplikasi & pilih "Daftar Toko"',
                'Masukkan kode lisensi di atas untuk aktivasi',
              ].map((step, i) => (
                <div key={i} className="flex items-start gap-3 text-sm text-slate-400">
                  <span className="w-5 h-5 bg-teal-500/20 text-teal-400 rounded-full flex items-center justify-center text-xs font-bold shrink-0">
                    {i + 1}
                  </span>
                  {step}
                </div>
              ))}
            </div>

            <a
              href="/"
              className="block w-full text-center py-3 bg-gradient-to-r from-teal-500 to-blue-600 hover:from-teal-400 hover:to-blue-500 text-white font-semibold rounded-xl transition-all"
            >
              Kembali ke Beranda
            </a>
          </div>
        )}

        {/* FAILED (resultCode bukan 00) */}
        {status === 'failed' && (
          <div className="bg-slate-800/60 backdrop-blur-xl border border-slate-700/50 rounded-3xl p-10 shadow-2xl text-center">
            <div className="w-20 h-20 bg-red-500/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <XCircle className="w-10 h-10 text-red-400" />
            </div>
            <h1 className="text-2xl font-bold text-white mb-2">Pembayaran Dibatalkan</h1>
            <p className="text-slate-400 text-sm mb-6">Transaksi tidak diselesaikan atau dibatalkan. Anda dapat mencoba kembali.</p>
            <a
              href="/beli"
              className="inline-block px-6 py-3 bg-slate-700 hover:bg-slate-600 text-white font-semibold rounded-xl transition-all"
            >
              Coba Lagi
            </a>
          </div>
        )}

        {/* ERROR (verifikasi gagal) */}
        {status === 'error' && (
          <div className="bg-slate-800/60 backdrop-blur-xl border border-slate-700/50 rounded-3xl p-10 shadow-2xl text-center">
            <div className="w-20 h-20 bg-orange-500/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <XCircle className="w-10 h-10 text-orange-400" />
            </div>
            <h1 className="text-2xl font-bold text-white mb-2">Verifikasi Gagal</h1>
            <p className="text-slate-400 text-sm mb-2">{errorMsg || 'Terjadi kesalahan saat memverifikasi pembayaran.'}</p>
            <p className="text-slate-500 text-xs mb-6">
              Order ID: <span className="font-mono text-slate-400">{merchantOrderId}</span>
            </p>
            <p className="text-slate-400 text-sm mb-4">
              Jika Anda yakin sudah membayar, hubungi kami dengan menyebutkan Order ID di atas.
            </p>
            <a
              href="/beli"
              className="inline-block px-6 py-3 bg-slate-700 hover:bg-slate-600 text-white font-semibold rounded-xl transition-all"
            >
              Kembali
            </a>
          </div>
        )}

      </div>
    </main>
  );
}

export default function PaymentSuccessPage() {
  return (
    <Suspense fallback={
      <main className="min-h-screen bg-[#0F172A] flex items-center justify-center">
        <Loader2 className="w-8 h-8 text-teal-400 animate-spin" />
      </main>
    }>
      <PaymentSuccessContent />
    </Suspense>
  );
}
