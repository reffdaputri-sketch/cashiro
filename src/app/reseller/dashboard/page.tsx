'use client';

import { useState, useEffect, useCallback } from 'react';
import { useRouter } from 'next/navigation';
import {
  LogOut, TrendingUp, Wallet, ShoppingBag, Copy, Check,
  Clock, CheckCircle, XCircle, RefreshCw, ExternalLink,
  ChevronRight, BanknoteIcon, AlertCircle
} from 'lucide-react';

interface ResellerInfo {
  id: number;
  name: string;
  slug: string;
  email: string;
  sell_price: number;
  base_price: number;
  balance: number;
  total_sales: number;
  total_earned: number;
}

interface Sale {
  id: number;
  order_id: string;
  buyer_email: string;
  buyer_store_name: string;
  sale_price: number;
  commission: number;
  can_withdraw_at: string;
  created_at: string;
}

interface Withdrawal {
  id: number;
  amount: number;
  bank_name: string;
  bank_account: string;
  bank_holder: string;
  status: string;
  note: string;
  created_at: string;
}

export default function ResellerDashboard() {
  const router = useRouter();
  const [reseller, setReseller] = useState<ResellerInfo | null>(null);
  const [sales, setSales] = useState<Sale[]>([]);
  const [withdrawals, setWithdrawals] = useState<Withdrawal[]>([]);
  const [withdrawableAmount, setWithdrawableAmount] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [activeTab, setActiveTab] = useState<'overview' | 'sales' | 'withdraw'>('overview');
  const [copied, setCopied] = useState(false);

  // Withdrawal form
  const [bankName, setBankName] = useState('');
  const [bankAccount, setBankAccount] = useState('');
  const [bankHolder, setBankHolder] = useState('');
  const [withdrawAmount, setWithdrawAmount] = useState('');
  const [wdLoading, setWdLoading] = useState(false);
  const [wdMsg, setWdMsg] = useState('');
  const [wdError, setWdError] = useState('');

  const fetchDashboard = useCallback(async () => {
    const token = localStorage.getItem('reseller_token') || '';
    const info = localStorage.getItem('reseller_info');
    if (!token || !info) {
      router.push('/reseller/login');
      return;
    }

    const parsed = JSON.parse(info);

    try {
      const res = await fetch(
        `/api/reseller/dashboard?id=${parsed.id}&email=${encodeURIComponent(parsed.email)}`,
        { headers: { Authorization: token } }
      );

      if (res.status === 401) {
        router.push('/reseller/login');
        return;
      }

      const data = await res.json();
      setReseller(data.reseller);
      setSales(data.sales || []);
      setWithdrawals(data.withdrawals || []);
      setWithdrawableAmount(data.withdrawable_amount || 0);
    } catch {
      router.push('/reseller/login');
    } finally {
      setIsLoading(false);
    }
  }, [router]);

  useEffect(() => {
    fetchDashboard();
  }, [fetchDashboard]);

  const handleLogout = () => {
    localStorage.removeItem('reseller_token');
    localStorage.removeItem('reseller_info');
    router.push('/reseller/login');
  };

  const checkoutLink = reseller
    ? `${typeof window !== 'undefined' ? window.location.origin : ''}/beli?ref=${reseller.slug}`
    : '';

  const copyLink = () => {
    navigator.clipboard.writeText(checkoutLink);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleWithdraw = async (e: React.FormEvent) => {
    e.preventDefault();
    setWdError('');
    setWdMsg('');

    if (!bankName || !bankAccount || !bankHolder) {
      setWdError('Isi semua informasi rekening terlebih dahulu');
      return;
    }

    const amount = Number(withdrawAmount);
    if (!amount || amount < 10000) {
      setWdError('Minimum penarikan Rp 10.000');
      return;
    }

    if (amount > withdrawableAmount) {
      setWdError(`Maksimal yang bisa ditarik: Rp ${withdrawableAmount.toLocaleString('id-ID')}`);
      return;
    }

    setWdLoading(true);
    const token = localStorage.getItem('reseller_token') || '';
    const info = JSON.parse(localStorage.getItem('reseller_info') || '{}');

    try {
      const res = await fetch('/api/reseller/withdraw', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: JSON.stringify({
          reseller_id: info.id,
          email: info.email,
          bank_name: bankName,
          bank_account: bankAccount,
          bank_holder: bankHolder,
          amount,
        }),
      });

      const data = await res.json();
      if (!res.ok) throw new Error(data.error);

      setWdMsg(data.message || 'Permintaan penarikan berhasil dikirim!');
      setWithdrawAmount('');
      await fetchDashboard();
    } catch (err: any) {
      setWdError(err.message);
    } finally {
      setWdLoading(false);
    }
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-slate-950 flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-12 h-12 border-2 border-blue-500 border-t-transparent rounded-full animate-spin" />
          <p className="text-slate-400 text-sm">Memuat dashboard...</p>
        </div>
      </div>
    );
  }

  if (!reseller) return null;

  const commission = Number(reseller.sell_price) - Number(reseller.base_price);
  const hasPendingWd = withdrawals.some(w => w.status === 'pending');

  return (
    <main className="min-h-screen bg-slate-950 text-white pb-20">
      {/* Header */}
      <header className="bg-slate-900/80 backdrop-blur-md border-b border-slate-800 sticky top-0 z-30 px-4 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-xl flex items-center justify-center font-black text-lg shadow-md">
            C
          </div>
          <div>
            <p className="font-bold text-white text-sm leading-none">{reseller.name}</p>
            <p className="text-slate-500 text-xs">Reseller · @{reseller.slug}</p>
          </div>
        </div>
        <button
          onClick={handleLogout}
          className="flex items-center gap-1.5 text-slate-400 hover:text-red-400 transition-colors text-xs font-medium cursor-pointer"
        >
          <LogOut size={14} /> Keluar
        </button>
      </header>

      {/* Stats Cards */}
      <div className="px-4 pt-5 pb-3 grid grid-cols-2 gap-3">
        <div className="bg-gradient-to-br from-blue-600 to-blue-700 rounded-2xl p-4 shadow-lg shadow-blue-900/30">
          <p className="text-blue-200 text-xs font-medium mb-1">Total Terjual</p>
          <p className="text-3xl font-black">{reseller.total_sales}</p>
          <p className="text-blue-300 text-xs mt-1">lisensi</p>
        </div>
        <div className="bg-gradient-to-br from-emerald-600 to-emerald-700 rounded-2xl p-4 shadow-lg shadow-emerald-900/30">
          <p className="text-emerald-200 text-xs font-medium mb-1">Total Komisi</p>
          <p className="text-xl font-black leading-tight">
            Rp {Number(reseller.total_earned).toLocaleString('id-ID')}
          </p>
          <p className="text-emerald-300 text-xs mt-1">sepanjang waktu</p>
        </div>
        <div className="bg-slate-800 border border-slate-700 rounded-2xl p-4">
          <p className="text-slate-400 text-xs font-medium mb-1">Saldo Siap Tarik</p>
          <p className="text-xl font-black text-amber-400 leading-tight">
            Rp {withdrawableAmount.toLocaleString('id-ID')}
          </p>
          <p className="text-slate-500 text-xs mt-1">sudah settlement</p>
        </div>
        <div className="bg-slate-800 border border-slate-700 rounded-2xl p-4">
          <p className="text-slate-400 text-xs font-medium mb-1">Komisi / Lisensi</p>
          <p className="text-xl font-black text-indigo-400 leading-tight">
            Rp {commission.toLocaleString('id-ID')}
          </p>
          <p className="text-slate-500 text-xs mt-1">harga jual Rp {Number(reseller.sell_price).toLocaleString('id-ID')}</p>
        </div>
      </div>

      {/* Link Checkout */}
      <div className="px-4 mb-4">
        <div className="bg-slate-900 border border-slate-700 rounded-2xl p-4">
          <p className="text-slate-400 text-xs font-semibold uppercase tracking-wider mb-2 flex items-center gap-1.5">
            <ExternalLink size={12} /> Link Checkout Kamu
          </p>
          <div className="flex items-center gap-2">
            <div className="flex-1 bg-slate-950 rounded-xl px-3 py-2.5 text-xs text-slate-300 font-mono truncate border border-slate-800">
              /beli?ref={reseller.slug}
            </div>
            <button
              onClick={copyLink}
              className="px-3 py-2.5 bg-blue-600 hover:bg-blue-700 rounded-xl text-white text-xs font-bold transition-all flex items-center gap-1 cursor-pointer shrink-0"
            >
              {copied ? <Check size={14} /> : <Copy size={14} />}
              {copied ? 'Disalin!' : 'Salin'}
            </button>
          </div>
          <p className="text-slate-600 text-[11px] mt-2">
            Bagikan link ini ke calon pembeli. Komisi langsung masuk setelah pembayaran sukses.
          </p>
        </div>
      </div>

      {/* Tabs */}
      <div className="px-4 mb-4">
        <div className="flex bg-slate-900 border border-slate-800 rounded-2xl p-1.5 gap-1">
          {(['overview', 'sales', 'withdraw'] as const).map(tab => (
            <button
              key={tab}
              onClick={() => setActiveTab(tab)}
              className={`flex-1 py-2 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                activeTab === tab
                  ? 'bg-blue-600 text-white shadow-md'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              {tab === 'overview' ? '📊 Overview' : tab === 'sales' ? '🛒 Penjualan' : '💸 Tarik'}
            </button>
          ))}
        </div>
      </div>

      {/* Tab Content */}
      <div className="px-4">

        {/* Overview Tab */}
        {activeTab === 'overview' && (
          <div className="space-y-3">
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <h3 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                <TrendingUp size={16} className="text-blue-400" /> Info Harga
              </h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Harga jual ke pembeli</span>
                  <span className="font-bold text-white">Rp {Number(reseller.sell_price).toLocaleString('id-ID')}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-slate-400">Harga dasar</span>
                  <span className="font-bold text-slate-300">Rp {Number(reseller.base_price).toLocaleString('id-ID')}</span>
                </div>
                <div className="border-t border-slate-800 pt-2 flex justify-between items-center">
                  <span className="text-emerald-400 font-semibold">Komisi kamu per penjualan</span>
                  <span className="font-black text-emerald-400">Rp {commission.toLocaleString('id-ID')}</span>
                </div>
              </div>
            </div>

            {/* Withdrawal info */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <h3 className="text-sm font-bold text-white mb-3 flex items-center gap-2">
                <Clock size={16} className="text-amber-400" /> Jadwal Penarikan
              </h3>
              <p className="text-slate-400 text-xs leading-relaxed">
                Komisi dari setiap penjualan bisa ditarik <strong className="text-white">1 hari (24 jam)</strong> setelah transaksi selesai.
                Ini untuk memastikan pembayaran sudah final dan tidak ada refund.
              </p>
              {withdrawableAmount > 0 && (
                <div className="mt-3 bg-emerald-500/10 border border-emerald-500/30 rounded-xl px-3 py-2.5 flex items-center gap-2">
                  <CheckCircle size={14} className="text-emerald-400 shrink-0" />
                  <p className="text-emerald-400 text-xs font-semibold">
                    Rp {withdrawableAmount.toLocaleString('id-ID')} siap ditarik sekarang!
                  </p>
                </div>
              )}
            </div>

            {/* Recent sales */}
            <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
              <h3 className="text-sm font-bold text-white mb-3 flex items-center gap-2 justify-between">
                <span className="flex items-center gap-2"><ShoppingBag size={16} className="text-indigo-400" /> Penjualan Terbaru</span>
                <button onClick={() => setActiveTab('sales')} className="text-blue-400 text-xs flex items-center gap-0.5 cursor-pointer">
                  Lihat semua <ChevronRight size={12} />
                </button>
              </h3>
              {sales.slice(0, 3).length === 0 ? (
                <p className="text-slate-500 text-xs text-center py-4">Belum ada penjualan</p>
              ) : (
                <div className="space-y-2">
                  {sales.slice(0, 3).map(s => (
                    <div key={s.id} className="flex items-center justify-between py-2 border-b border-slate-800 last:border-0">
                      <div>
                        <p className="text-white text-xs font-semibold">{s.buyer_store_name || s.buyer_email}</p>
                        <p className="text-slate-500 text-[11px]">
                          {new Date(s.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                        </p>
                      </div>
                      <span className="text-emerald-400 text-sm font-bold">+Rp {Number(s.commission).toLocaleString('id-ID')}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </div>
        )}

        {/* Sales Tab */}
        {activeTab === 'sales' && (
          <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
            <div className="px-4 py-3 border-b border-slate-800">
              <h3 className="text-sm font-bold text-white">Riwayat Penjualan ({sales.length})</h3>
            </div>
            {sales.length === 0 ? (
              <div className="text-center py-12 text-slate-500 text-sm">
                <ShoppingBag size={32} className="mx-auto mb-3 opacity-30" />
                Belum ada penjualan
              </div>
            ) : (
              <div className="divide-y divide-slate-800">
                {sales.map(s => {
                  const canWithdraw = new Date(s.can_withdraw_at) <= new Date();
                  return (
                    <div key={s.id} className="px-4 py-3">
                      <div className="flex items-start justify-between mb-1">
                        <div className="flex-1">
                          <p className="text-white text-sm font-semibold">{s.buyer_store_name || '-'}</p>
                          <p className="text-slate-500 text-xs">{s.buyer_email}</p>
                        </div>
                        <div className="text-right ml-3">
                          <p className="text-emerald-400 font-bold text-sm">+Rp {Number(s.commission).toLocaleString('id-ID')}</p>
                          <p className="text-slate-500 text-[11px]">dari Rp {Number(s.sale_price).toLocaleString('id-ID')}</p>
                        </div>
                      </div>
                      <div className="flex items-center justify-between">
                        <p className="text-slate-600 text-[11px]">
                          {new Date(s.created_at).toLocaleString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                        </p>
                        {canWithdraw ? (
                          <span className="text-[10px] font-semibold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full">✓ Siap tarik</span>
                        ) : (
                          <span className="text-[10px] font-semibold text-amber-400 bg-amber-500/10 px-2 py-0.5 rounded-full">
                            ⏳ {new Date(s.can_withdraw_at).toLocaleString('id-ID', { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' })}
                          </span>
                        )}
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        )}

        {/* Withdraw Tab */}
        {activeTab === 'withdraw' && (
          <div className="space-y-4">
            {/* Saldo info */}
            <div className="bg-gradient-to-br from-amber-600/20 to-amber-700/10 border border-amber-500/30 rounded-2xl p-4">
              <p className="text-amber-300 text-xs font-semibold uppercase tracking-wider mb-1">Saldo Siap Ditarik</p>
              <p className="text-3xl font-black text-white">Rp {withdrawableAmount.toLocaleString('id-ID')}</p>
              {Number(reseller.balance) > withdrawableAmount && (
                <p className="text-amber-500 text-xs mt-1">
                  Rp {(Number(reseller.balance) - withdrawableAmount).toLocaleString('id-ID')} masih dalam masa settlement
                </p>
              )}
            </div>

            {hasPendingWd && (
              <div className="bg-blue-500/10 border border-blue-500/30 rounded-2xl p-3 flex items-center gap-2">
                <AlertCircle size={14} className="text-blue-400 shrink-0" />
                <p className="text-blue-300 text-xs">Ada permintaan penarikan yang sedang diproses admin.</p>
              </div>
            )}

            {/* Form */}
            {!hasPendingWd && withdrawableAmount >= 10000 && (
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-4">
                <h3 className="text-sm font-bold text-white mb-4 flex items-center gap-2">
                  <BanknoteIcon size={16} className="text-emerald-400" /> Request Penarikan
                </h3>

                {wdMsg && (
                  <div className="bg-emerald-500/10 border border-emerald-500/30 text-emerald-400 text-xs rounded-xl p-3 mb-4 flex items-center gap-2">
                    <CheckCircle size={14} /> {wdMsg}
                  </div>
                )}
                {wdError && (
                  <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-xs rounded-xl p-3 mb-4">
                    ⚠️ {wdError}
                  </div>
                )}

                <form onSubmit={handleWithdraw} className="space-y-3">
                  <div>
                    <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Nama Bank</label>
                    <input
                      type="text"
                      required
                      value={bankName}
                      onChange={e => setBankName(e.target.value)}
                      placeholder="Contoh: BCA / Mandiri / BRI"
                      className="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500/20 transition-all placeholder:text-slate-600"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Nomor Rekening</label>
                    <input
                      type="text"
                      required
                      value={bankAccount}
                      onChange={e => setBankAccount(e.target.value)}
                      placeholder="1234567890"
                      className="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500/20 transition-all placeholder:text-slate-600 font-mono"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Nama Pemilik Rekening</label>
                    <input
                      type="text"
                      required
                      value={bankHolder}
                      onChange={e => setBankHolder(e.target.value)}
                      placeholder="Nama sesuai rekening"
                      className="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500/20 transition-all placeholder:text-slate-600"
                    />
                  </div>
                  <div>
                    <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">
                      Jumlah Tarik (Rp)
                    </label>
                    <input
                      type="number"
                      required
                      min={10000}
                      max={withdrawableAmount}
                      value={withdrawAmount}
                      onChange={e => setWithdrawAmount(e.target.value)}
                      placeholder={`Maks. ${withdrawableAmount.toLocaleString('id-ID')}`}
                      className="w-full bg-slate-950 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500/20 transition-all placeholder:text-slate-600"
                    />
                    <p className="text-slate-600 text-[11px] mt-1">Minimum penarikan Rp 10.000</p>
                  </div>
                  <button
                    type="submit"
                    disabled={wdLoading}
                    className="w-full py-3 bg-emerald-600 hover:bg-emerald-700 text-white font-bold rounded-xl transition-all disabled:opacity-50 flex items-center justify-center gap-2 text-sm cursor-pointer mt-2 active:scale-[0.98]"
                  >
                    {wdLoading ? <RefreshCw size={15} className="animate-spin" /> : <BanknoteIcon size={15} />}
                    {wdLoading ? 'Memproses...' : 'Kirim Permintaan Penarikan'}
                  </button>
                </form>
              </div>
            )}

            {withdrawableAmount < 10000 && !hasPendingWd && (
              <div className="bg-slate-900 border border-slate-800 rounded-2xl p-6 text-center">
                <Clock size={32} className="mx-auto mb-3 text-slate-600" />
                <p className="text-slate-400 text-sm">Saldo belum mencukupi untuk ditarik</p>
                <p className="text-slate-600 text-xs mt-1">Minimum penarikan Rp 10.000</p>
              </div>
            )}

            {/* Riwayat Withdrawal */}
            {withdrawals.length > 0 && (
              <div className="bg-slate-900 border border-slate-800 rounded-2xl overflow-hidden">
                <div className="px-4 py-3 border-b border-slate-800">
                  <h3 className="text-sm font-bold text-white">Riwayat Penarikan</h3>
                </div>
                <div className="divide-y divide-slate-800">
                  {withdrawals.map(w => (
                    <div key={w.id} className="px-4 py-3 flex items-center justify-between">
                      <div>
                        <p className="text-white text-sm font-bold">Rp {Number(w.amount).toLocaleString('id-ID')}</p>
                        <p className="text-slate-500 text-xs">{w.bank_name} · {w.bank_account}</p>
                        <p className="text-slate-600 text-[11px]">
                          {new Date(w.created_at).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' })}
                        </p>
                      </div>
                      <div className="ml-3">
                        {w.status === 'pending' && (
                          <span className="text-[11px] font-bold text-yellow-400 bg-yellow-500/10 border border-yellow-500/30 px-2.5 py-1 rounded-full">⏳ Diproses</span>
                        )}
                        {w.status === 'approved' && (
                          <span className="text-[11px] font-bold text-emerald-400 bg-emerald-500/10 border border-emerald-500/30 px-2.5 py-1 rounded-full">✅ Cair</span>
                        )}
                        {w.status === 'rejected' && (
                          <div className="text-right">
                            <span className="text-[11px] font-bold text-red-400 bg-red-500/10 border border-red-500/30 px-2.5 py-1 rounded-full">❌ Ditolak</span>
                            {w.note && <p className="text-red-400/70 text-[10px] mt-1">{w.note}</p>}
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        )}
      </div>
    </main>
  );
}
