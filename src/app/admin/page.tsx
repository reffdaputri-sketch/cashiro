"use client";

import React, { useState, useEffect } from 'react';
import { ArrowRight, Key, Shield, LogOut, CheckCircle, XCircle, Search, Store, Mail, PlusCircle, Copy, Check, AlertCircle, Wallet, RefreshCw, Clock, X, Smartphone, Wifi, WifiOff, QrCode, Users, TrendingUp, Link2, Edit2, Ban } from 'lucide-react';

export default function AdminDashboard() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loginError, setLoginError] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  // Dashboard Data
  const [licenses, setLicenses] = useState<any[]>([]);
  const [stores, setStores] = useState<any[]>([]);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState<'licenses' | 'stores' | 'withdrawals' | 'resellers'>('licenses');

  // Withdrawal state
  const [withdrawals, setWithdrawals] = useState<any[]>([]);
  const [withdrawalFilter, setWithdrawalFilter] = useState<'pending' | 'approved' | 'rejected'>('pending');
  const [withdrawalLoading, setWithdrawalLoading] = useState(false);
  const [rejectNote, setRejectNote] = useState<Record<string, string>>({});
  const [processingId, setProcessingId] = useState<string | null>(null);
  const [actionMessage, setActionMessage] = useState('');

  // Reseller state
  const [resellers, setResellers] = useState<any[]>([]);
  const [resellerLoading, setResellerLoading] = useState(false);
  const [resellerForm, setResellerForm] = useState({ name: '', slug: '', email: '', password: '', sell_price: '', base_price: '25000' });
  const [resellerFormError, setResellerFormError] = useState('');
  const [resellerFormSuccess, setResellerFormSuccess] = useState('');
  const [resellerWds, setResellerWds] = useState<any[]>([]);
  const [resellerWdFilter, setResellerWdFilter] = useState<'pending' | 'approved' | 'rejected'>('pending');
  const [resellerWdLoading, setResellerWdLoading] = useState(false);
  const [editReseller, setEditReseller] = useState<any | null>(null);
  const [editSellPrice, setEditSellPrice] = useState('');
  const [editBasePrice, setEditBasePrice] = useState('');
  const [editLoading, setEditLoading] = useState(false);
  const [copiedSlug, setCopiedSlug] = useState<string | null>(null);
  const [resellerWdRejectNote, setResellerWdRejectNote] = useState<Record<string, string>>({});
  const [resellerWdProcessingId, setResellerWdProcessingId] = useState<string | null>(null);

  // Manual generation form
  // WhatsApp Gateway state
  const [waStatus, setWaStatus] = useState<'disconnected' | 'connecting' | 'pairing' | 'connected'>('disconnected');
  const [waQR, setWaQR] = useState<string | null>(null);
  const [waLoading, setWaLoading] = useState(false);

  const [manualEmail, setManualEmail] = useState('');
  const [generatedKey, setGeneratedKey] = useState('');
  const [createError, setCreateError] = useState('');
  const [copiedKey, setCopiedKey] = useState(false);

  const fetchWAStatus = async () => {
    try {
      const res = await fetch('http://localhost:3001/status');
      const data = await res.json();
      setWaStatus(data.status);
      setWaQR(data.qr || null);
    } catch {
      setWaStatus('disconnected');
      setWaQR(null);
    }
  };

  const handleWALogout = async () => {
    setWaLoading(true);
    try {
      await fetch('http://localhost:3001/logout', { method: 'POST' });
      setWaStatus('disconnected');
      setWaQR(null);
      setTimeout(fetchWAStatus, 3000);
    } catch {
      // ignore
    } finally {
      setWaLoading(false);
    }
  };

  useEffect(() => {
    const token = localStorage.getItem('cashiro_admin_token');
    if (token === 'admin-authorized-token-cashiro') {
      setIsAuthenticated(true);
      fetchDashboardData();
      fetchWAStatus();
    }
  }, []);

  // Poll WA status every 5 seconds when authenticated
  useEffect(() => {
    if (!isAuthenticated) return;
    fetchWAStatus();
    const interval = setInterval(fetchWAStatus, 5000);
    return () => clearInterval(interval);
  }, [isAuthenticated]);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginError('');
    setIsLoading(true);

    try {
      const response = await fetch('/api/license/admin-login', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ username, password }),
      });

      const data = await response.json();
      if (response.ok && data.success) {
        localStorage.setItem('cashiro_admin_token', data.token);
        setIsAuthenticated(true);
        fetchDashboardData();
      } else {
        setLoginError(data.error || 'Login gagal');
      }
    } catch (err: any) {
      setLoginError('Koneksi server gagal');
    } finally {
      setIsLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem('cashiro_admin_token');
    setIsAuthenticated(false);
    setLicenses([]);
    setStores([]);
  };

  const fetchDashboardData = async () => {
    setIsLoading(true);
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const response = await fetch('/api/license/admin-manage', {
        headers: { 'Authorization': token },
      });
      const data = await response.json();
      if (response.ok) {
        setLicenses(data.licenses || []);
        setStores(data.stores || []);
      }
    } catch (err) {
      console.error('Failed to load dashboard data:', err);
    } finally {
      setIsLoading(false);
    }
  };

  const fetchResellers = async () => {
    setResellerLoading(true);
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch('/api/resellers', { headers: { Authorization: token } });
      const data = await res.json();
      if (res.ok) setResellers(data.resellers || []);
    } catch {}
    finally { setResellerLoading(false); }
  };

  const fetchResellerWithdrawals = async (status = resellerWdFilter) => {
    setResellerWdLoading(true);
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch(`/api/resellers/withdrawals/admin?status=${status}`, { headers: { Authorization: token } });
      const data = await res.json();
      if (res.ok) setResellerWds(data.requests || []);
    } catch {}
    finally { setResellerWdLoading(false); }
  };

  const fetchWithdrawals = async (status = withdrawalFilter) => {
    setWithdrawalLoading(true);
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch(`/api/withdrawals/referral/admin?status=${status}`, {
        headers: { Authorization: token },
      });
      const data = await res.json();
      if (res.ok) setWithdrawals(data.requests || []);
    } catch (err) {
      console.error('Failed to fetch withdrawals:', err);
    } finally {
      setWithdrawalLoading(false);
    }
  };

  const handleWithdrawalAction = async (id: string, action: 'approved' | 'rejected') => {
    setProcessingId(id);
    setActionMessage('');
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch('/api/withdrawals/referral/admin', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: JSON.stringify({ id, action, note: rejectNote[id] || '' }),
      });
      const data = await res.json();
      if (res.ok) {
        setActionMessage(data.message || 'Berhasil diproses');
        fetchWithdrawals(withdrawalFilter);
      } else {
        setActionMessage(data.error || 'Gagal memproses');
      }
    } catch {
      setActionMessage('Gagal terhubung ke server');
    } finally {
      setProcessingId(null);
    }
  };

  const handleGenerateLicense = async (e: React.FormEvent) => {
    e.preventDefault();
    setCreateError('');
    setGeneratedKey('');
    setIsLoading(true);

    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const response = await fetch('/api/license/admin-manage', {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          'Authorization': token 
        },
        body: JSON.stringify({ email: manualEmail }),
      });

      const data = await response.json();
      if (response.ok && data.success) {
        setGeneratedKey(data.license.key);
        setManualEmail('');
        fetchDashboardData(); // Refresh lists
      } else {
        setCreateError(data.error || 'Gagal menerbitkan lisensi');
      }
    } catch (err) {
      setCreateError('Gagal terhubung dengan server');
    } finally {
      setIsLoading(false);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(true);
    setTimeout(() => setCopiedKey(false), 2000);
  };

  const copyResellerLink = (slug: string) => {
    const link = `${window.location.origin}/beli?ref=${slug}`;
    navigator.clipboard.writeText(link);
    setCopiedSlug(slug);
    setTimeout(() => setCopiedSlug(null), 2000);
  };

  const handleAddReseller = async (e: React.FormEvent) => {
    e.preventDefault();
    setResellerFormError('');
    setResellerFormSuccess('');
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch('/api/resellers', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: JSON.stringify({
          name: resellerForm.name,
          slug: resellerForm.slug.toLowerCase().replace(/\s+/g, '-'),
          email: resellerForm.email,
          password: resellerForm.password,
          sell_price: Number(resellerForm.sell_price),
          base_price: Number(resellerForm.base_price),
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setResellerFormSuccess(`Reseller "${data.reseller.name}" berhasil ditambahkan!`);
      setResellerForm({ name: '', slug: '', email: '', password: '', sell_price: '', base_price: '25000' });
      fetchResellers();
    } catch (err: any) {
      setResellerFormError(err.message);
    }
  };

  const handleUpdateReseller = async () => {
    if (!editReseller) return;
    setEditLoading(true);
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch(`/api/resellers/${editReseller.slug}`, {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: JSON.stringify({ sell_price: Number(editSellPrice), base_price: Number(editBasePrice) }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error);
      setEditReseller(null);
      fetchResellers();
    } catch (err: any) {
      alert(err.message);
    } finally {
      setEditLoading(false);
    }
  };

  const handleToggleResellerActive = async (slug: string, current: boolean) => {
    const token = localStorage.getItem('cashiro_admin_token') || '';
    await fetch(`/api/resellers/${slug}`, {
      method: 'PATCH',
      headers: { 'Content-Type': 'application/json', Authorization: token },
      body: JSON.stringify({ is_active: !current }),
    });
    fetchResellers();
  };

  const handleResellerWdAction = async (id: string, action: 'approved' | 'rejected') => {
    setResellerWdProcessingId(id);
    const token = localStorage.getItem('cashiro_admin_token') || '';
    try {
      const res = await fetch('/api/resellers/withdrawals/admin', {
        method: 'PATCH',
        headers: { 'Content-Type': 'application/json', Authorization: token },
        body: JSON.stringify({ id, action, note: resellerWdRejectNote[id] || '' }),
      });
      const data = await res.json();
      if (res.ok) fetchResellerWithdrawals(resellerWdFilter);
      else alert(data.error);
    } catch {}
    finally { setResellerWdProcessingId(null); }
  };

  // Filters
  const filteredLicenses = licenses.filter(lic => 
    lic.key.toLowerCase().includes(searchQuery.toLowerCase()) ||
    lic.email.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const filteredStores = stores.filter(store => 
    store.store_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
    store.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
    (store.owner_name && store.owner_name.toLowerCase().includes(searchQuery.toLowerCase()))
  );

  if (!isAuthenticated) {
    return (
      <main className="min-h-screen bg-slate-900 flex items-center justify-center p-4">
        <div className="w-full max-w-md bg-slate-800 rounded-3xl border border-slate-700 shadow-2xl p-8 relative overflow-hidden">
          <div className="absolute top-0 right-0 w-48 h-48 bg-blue-500/10 rounded-full blur-3xl" />
          
          <div className="text-center mb-8">
            <div className="w-16 h-16 bg-blue-500/20 rounded-2xl flex items-center justify-center mx-auto mb-4 border border-blue-500/30">
              <Shield className="w-8 h-8 text-blue-400" />
            </div>
            <h1 className="text-2xl font-bold text-white mb-2">Cashiro Admin</h1>
            <p className="text-slate-400 text-sm">Masuk untuk memonitor pelanggan & lisensi</p>
          </div>

          {loginError && (
            <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-sm rounded-xl p-3 mb-6 text-center">
              {loginError}
            </div>
          )}

          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-slate-400 text-xs font-semibold uppercase mb-1">Username</label>
              <input
                type="text"
                required
                value={username}
                onChange={e => setUsername(e.target.value)}
                placeholder="Admin username"
                className="w-full px-4 py-3 bg-slate-950 border border-slate-700 rounded-xl text-white outline-none focus:ring-2 focus:ring-blue-500/50 transition-all text-sm"
              />
            </div>
            <div>
              <label className="block text-slate-400 text-xs font-semibold uppercase mb-1">Password</label>
              <input
                type="password"
                required
                value={password}
                onChange={e => setPassword(e.target.value)}
                placeholder="••••••••"
                className="w-full px-4 py-3 bg-slate-950 border border-slate-700 rounded-xl text-white outline-none focus:ring-2 focus:ring-blue-500/50 transition-all text-sm"
              />
            </div>

            <button
              type="submit"
              disabled={isLoading}
              className="w-full mt-2 py-3 bg-blue-600 hover:bg-blue-700 text-white font-bold rounded-xl shadow-lg shadow-blue-600/30 flex items-center justify-center gap-2 transition-all disabled:opacity-50 text-sm cursor-pointer"
            >
              {isLoading ? 'Sedang Verifikasi...' : 'Masuk Dashboard'} <ArrowRight size={18} />
            </button>
          </form>
        </div>
      </main>
    );
  }

  return (
    <main className="min-h-screen bg-slate-950 text-slate-100 font-sans">
      {/* Header */}
      <header className="border-b border-slate-800 bg-slate-900/50 backdrop-blur-md sticky top-0 z-40">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-9 h-9 bg-blue-600 rounded-xl flex items-center justify-center text-white font-bold shadow-md">
              C
            </div>
            <span className="font-bold text-lg text-white">Cashiro Control Panel</span>
          </div>

          <button
            onClick={handleLogout}
            className="flex items-center gap-2 text-sm text-slate-400 hover:text-red-400 font-medium px-4 py-2 rounded-xl hover:bg-slate-800/50 transition-all cursor-pointer"
          >
            <LogOut size={16} /> Keluar
          </button>
        </div>
      </header>

      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          
          {/* Left Column: Manual Generator */}
          <div className="space-y-6">

            {/* WhatsApp Gateway Panel */}
            <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-xl relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-green-500/10 rounded-full blur-2xl" />

              <div className="flex items-center justify-between mb-4">
                <h2 className="text-xl font-bold text-white flex items-center gap-2">
                  <Smartphone className="text-green-400" size={20} />
                  WhatsApp Gateway
                </h2>
                <button
                  onClick={fetchWAStatus}
                  className="p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition-all cursor-pointer"
                  title="Refresh Status"
                >
                  <RefreshCw size={14} />
                </button>
              </div>

              {/* Status Badge */}
              <div className="mb-4">
                {waStatus === 'connected' && (
                  <div className="flex items-center gap-2 bg-green-500/10 border border-green-500/30 text-green-400 rounded-xl px-4 py-2.5 text-sm font-semibold">
                    <span className="w-2 h-2 bg-green-400 rounded-full animate-pulse"></span>
                    <Wifi size={15} /> WhatsApp Terhubung!
                  </div>
                )}
                {waStatus === 'pairing' && (
                  <div className="flex items-center gap-2 bg-yellow-500/10 border border-yellow-500/30 text-yellow-400 rounded-xl px-4 py-2.5 text-sm font-semibold">
                    <QrCode size={15} /> Scan QR Code untuk Login
                  </div>
                )}
                {waStatus === 'connecting' && (
                  <div className="flex items-center gap-2 bg-blue-500/10 border border-blue-500/30 text-blue-400 rounded-xl px-4 py-2.5 text-sm font-semibold">
                    <RefreshCw size={15} className="animate-spin" /> Sedang Menghubungkan...
                  </div>
                )}
                {waStatus === 'disconnected' && (
                  <div className="flex items-center gap-2 bg-red-500/10 border border-red-500/30 text-red-400 rounded-xl px-4 py-2.5 text-sm font-semibold">
                    <WifiOff size={15} /> Tidak Terhubung
                  </div>
                )}
              </div>

              {/* QR Code Display */}
              {waQR && waStatus === 'pairing' && (
                <div className="bg-white rounded-2xl p-3 flex items-center justify-center mb-4 shadow-lg">
                  <img src={waQR} alt="WhatsApp QR Code" className="w-full max-w-[220px] h-auto" />
                </div>
              )}

              {waStatus === 'pairing' && !waQR && (
                <div className="bg-slate-950 border border-slate-700 rounded-2xl p-8 flex items-center justify-center mb-4 text-slate-500 text-sm">
                  <RefreshCw size={16} className="animate-spin mr-2" /> Memuat QR Code...
                </div>
              )}

              {/* WA Logout Button */}
              {waStatus === 'connected' && (
                <button
                  onClick={handleWALogout}
                  disabled={waLoading}
                  className="w-full py-2.5 bg-red-600/20 hover:bg-red-600/30 border border-red-500/30 text-red-400 font-semibold rounded-xl text-sm transition-all disabled:opacity-50 cursor-pointer flex items-center justify-center gap-2"
                >
                  {waLoading ? <RefreshCw size={14} className="animate-spin" /> : <LogOut size={14} />}
                  {waLoading ? 'Memutuskan...' : 'Logout WhatsApp'}
                </button>
              )}

              <p className="text-slate-600 text-[11px] mt-3 text-center">
                Server WA berjalan di port 3001
              </p>
            </div>
            <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-xl relative overflow-hidden">
              <div className="absolute top-0 right-0 w-32 h-32 bg-orange-500/10 rounded-full blur-2xl" />
              
              <h2 className="text-xl font-bold text-white mb-4 flex items-center gap-2">
                <PlusCircle className="text-orange-500" />
                Terbitkan Lisensi Manual
              </h2>
              <p className="text-sm text-slate-400 mb-6">
                Menerbitkan lisensi secara manual untuk pelanggan yang membayar via transfer langsung / tunai offline.
              </p>

              {createError && (
                <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-sm rounded-xl p-3 mb-4 text-center">
                  {createError}
                </div>
              )}

              <form onSubmit={handleGenerateLicense} className="space-y-4">
                <div>
                  <label className="block text-slate-400 text-xs font-semibold uppercase mb-1">Email Pelanggan</label>
                  <input
                    type="email"
                    required
                    value={manualEmail}
                    onChange={e => setManualEmail(e.target.value)}
                    placeholder="nama@email.com"
                    className="w-full px-4 py-3 bg-slate-950 border border-slate-800 rounded-xl text-white outline-none focus:ring-2 focus:ring-orange-500/50 transition-all text-sm"
                  />
                </div>

                <button
                  type="submit"
                  disabled={isLoading}
                  className="w-full py-3 bg-orange-600 hover:bg-orange-700 text-white font-bold rounded-xl shadow-lg shadow-orange-600/20 flex items-center justify-center gap-2 transition-all disabled:opacity-50 text-sm cursor-pointer"
                >
                  {isLoading ? 'Menerbitkan...' : 'Terbitkan Kode Lisensi'}
                </button>
              </form>

              {generatedKey && (
                <div className="mt-6 bg-slate-950 border border-orange-500/30 rounded-2xl p-4 relative">
                  <div className="text-slate-400 text-xs mb-1 font-semibold uppercase">Kode Lisensi Baru:</div>
                  <div className="flex items-center justify-between gap-3">
                    <span className="font-mono font-bold text-orange-400 text-lg tracking-wider">{generatedKey}</span>
                    <button
                      onClick={() => copyToClipboard(generatedKey)}
                      className="p-2 bg-slate-900 rounded-xl hover:bg-slate-800 text-slate-300 hover:text-white transition-all cursor-pointer"
                    >
                      {copiedKey ? <Check className="text-green-500" size={18} /> : <Copy size={18} />}
                    </button>
                  </div>
                  <p className="text-slate-500 text-[11px] mt-2">
                    *Salin kode ini dan berikan langsung kepada pelanggan Anda untuk registrasi aplikasi Cashiro.
                  </p>
                </div>
              )}
            </div>

            {/* Quick Stats */}
            <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-xl grid grid-cols-2 gap-4">
              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-4 text-center">
                <div className="text-slate-500 text-xs font-semibold mb-1 uppercase">Total Toko</div>
                <div className="text-3xl font-extrabold text-white">{stores.length}</div>
              </div>
              <div className="bg-slate-950 border border-slate-800 rounded-2xl p-4 text-center">
                <div className="text-slate-500 text-xs font-semibold mb-1 uppercase">Total Lisensi</div>
                <div className="text-3xl font-extrabold text-white">{licenses.length}</div>
              </div>
            </div>
          </div>

          {/* Right Column: Tabbed list of Data */}
          <div className="lg:col-span-2 space-y-6">
            <div className="bg-slate-900 border border-slate-800 rounded-3xl p-6 shadow-xl flex flex-col md:flex-row items-center justify-between gap-4">
              
              {/* Tabs */}
              <div className="flex bg-slate-950 p-1.5 rounded-2xl border border-slate-800 w-full md:w-auto flex-wrap gap-1">
                <button
                  onClick={() => setActiveTab('licenses')}
                  className={`flex-1 md:flex-none px-5 py-2.5 rounded-xl text-sm font-semibold transition-all cursor-pointer ${
                    activeTab === 'licenses'
                      ? 'bg-blue-600 text-white shadow-md'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  Daftar Lisensi
                </button>
                <button
                  onClick={() => setActiveTab('stores')}
                  className={`flex-1 md:flex-none px-5 py-2.5 rounded-xl text-sm font-semibold transition-all cursor-pointer ${
                    activeTab === 'stores'
                      ? 'bg-blue-600 text-white shadow-md'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  Daftar Toko
                </button>
                <button
                  onClick={() => { setActiveTab('withdrawals'); fetchWithdrawals('pending'); }}
                  className={`flex-1 md:flex-none px-5 py-2.5 rounded-xl text-sm font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
                    activeTab === 'withdrawals'
                      ? 'bg-emerald-600 text-white shadow-md'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  <Wallet size={14} /> Penarikan Referral
                </button>
                <button
                  onClick={() => { setActiveTab('resellers'); fetchResellers(); fetchResellerWithdrawals('pending'); }}
                  className={`flex-1 md:flex-none px-5 py-2.5 rounded-xl text-sm font-semibold transition-all cursor-pointer flex items-center gap-1.5 ${
                    activeTab === 'resellers'
                      ? 'bg-violet-600 text-white shadow-md'
                      : 'text-slate-400 hover:text-white'
                  }`}
                >
                  <Users size={14} /> Reseller
                </button>
              </div>

              {/* Search */}
              <div className="relative w-full md:w-72">
                <Search size={18} className="absolute left-3.5 top-1/2 -translate-y-1/2 text-slate-500" />
                <input
                  type="text"
                  placeholder="Cari email, lisensi, nama..."
                  value={searchQuery}
                  onChange={e => setSearchQuery(e.target.value)}
                  className="w-full pl-10 pr-4 py-2.5 bg-slate-950 border border-slate-800 rounded-xl text-white outline-none focus:ring-2 focus:ring-blue-500/50 transition-all text-sm"
                />
              </div>
            </div>

            {/* List */}
            <div className="bg-slate-900 border border-slate-800 rounded-3xl shadow-xl overflow-hidden min-h-[450px]">

              {/* Withdrawal Tab */}
              {activeTab === 'withdrawals' && (
                <div>
                  {/* Sub-filter */}
                  <div className="flex items-center gap-2 p-4 border-b border-slate-800 flex-wrap">
                    {(['pending', 'approved', 'rejected'] as const).map(s => (
                      <button
                        key={s}
                        onClick={() => { setWithdrawalFilter(s); fetchWithdrawals(s); }}
                        className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer border ${
                          withdrawalFilter === s
                            ? s === 'pending' ? 'bg-yellow-500/20 text-yellow-300 border-yellow-500/40'
                              : s === 'approved' ? 'bg-green-500/20 text-green-300 border-green-500/40'
                              : 'bg-red-500/20 text-red-300 border-red-500/40'
                            : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-white'
                        }`}
                      >
                        {s === 'pending' ? '⏳ Menunggu' : s === 'approved' ? '✅ Disetujui' : '❌ Ditolak'}
                      </button>
                    ))}
                    <button
                      onClick={() => fetchWithdrawals(withdrawalFilter)}
                      className="ml-auto p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition-all cursor-pointer"
                      title="Refresh"
                    >
                      <RefreshCw size={14} />
                    </button>
                  </div>

                  {actionMessage && (
                    <div className="mx-4 mt-4 bg-blue-500/10 border border-blue-500/30 text-blue-300 text-sm rounded-xl px-4 py-3 flex items-center justify-between">
                      <span>{actionMessage}</span>
                      <button onClick={() => setActionMessage('')} className="cursor-pointer"><X size={14} /></button>
                    </div>
                  )}

                  {withdrawalLoading ? (
                    <div className="flex items-center justify-center p-16 text-slate-400">
                      <RefreshCw className="animate-spin mr-2" size={18} /> Memuat data...
                    </div>
                  ) : withdrawals.length === 0 ? (
                    <div className="text-center p-16 text-slate-500 text-sm">
                      Tidak ada permintaan penarikan dengan status ini
                    </div>
                  ) : (
                    <div className="overflow-x-auto">
                      <table className="w-full text-left border-collapse text-sm">
                        <thead>
                          <tr className="border-b border-slate-800 bg-slate-950 text-slate-400 text-xs font-semibold uppercase">
                            <th className="p-4 pl-6">Toko</th>
                            <th className="p-4">Jumlah</th>
                            <th className="p-4">Info Rekening</th>
                            <th className="p-4">Tanggal</th>
                            {withdrawalFilter === 'pending' && <th className="p-4 pr-6">Aksi</th>}
                            {withdrawalFilter !== 'pending' && <th className="p-4 pr-6">Catatan</th>}
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-800">
                          {withdrawals.map((w: any) => (
                            <tr key={w.id} className="hover:bg-slate-800/30 transition-all">
                              <td className="p-4 pl-6">
                                <div className="font-bold text-white">{w.stores?.store_name || '-'}</div>
                                <div className="text-slate-400 text-xs">{w.stores?.owner_name || ''}</div>
                                <div className="text-slate-500 text-[11px]">{w.stores?.email || ''}</div>
                              </td>
                              <td className="p-4">
                                <span className="font-bold text-emerald-400 text-base">
                                  Rp {Number(w.amount).toLocaleString('id-ID')}
                                </span>
                              </td>
                              <td className="p-4">
                                {w.stores?.bank_name ? (
                                  <div>
                                    <div className="text-white font-semibold">{w.stores.bank_name}</div>
                                    <div className="text-slate-300 font-mono text-sm">{w.stores.bank_account}</div>
                                    <div className="text-slate-400 text-xs">{w.stores.bank_account_name}</div>
                                  </div>
                                ) : (
                                  <span className="text-slate-500 text-xs italic">Rekening belum diisi</span>
                                )}
                              </td>
                              <td className="p-4 text-slate-400 text-xs">
                                {new Date(w.created_at).toLocaleString('id-ID', {
                                  day: 'numeric', month: 'short', year: 'numeric',
                                  hour: '2-digit', minute: '2-digit'
                                })}
                              </td>
                              {withdrawalFilter === 'pending' ? (
                                <td className="p-4 pr-6">
                                  <div className="flex flex-col gap-2">
                                    <input
                                      type="text"
                                      placeholder="Catatan penolakan (opsional)"
                                      value={rejectNote[w.id] || ''}
                                      onChange={e => setRejectNote(prev => ({ ...prev, [w.id]: e.target.value }))}
                                      className="w-full px-3 py-1.5 bg-slate-950 border border-slate-700 rounded-lg text-xs text-white outline-none focus:ring-1 focus:ring-blue-500/50"
                                    />
                                    <div className="flex gap-2">
                                      <button
                                        onClick={() => handleWithdrawalAction(w.id, 'approved')}
                                        disabled={processingId === w.id}
                                        className="flex-1 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg transition-all disabled:opacity-50 cursor-pointer flex items-center justify-center gap-1"
                                      >
                                        <CheckCircle size={12} /> Setujui
                                      </button>
                                      <button
                                        onClick={() => handleWithdrawalAction(w.id, 'rejected')}
                                        disabled={processingId === w.id}
                                        className="flex-1 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-lg transition-all disabled:opacity-50 cursor-pointer flex items-center justify-center gap-1"
                                      >
                                        <XCircle size={12} /> Tolak
                                      </button>
                                    </div>
                                  </div>
                                </td>
                              ) : (
                                <td className="p-4 pr-6 text-slate-400 text-xs">
                                  {w.note || '-'}
                                </td>
                              )}
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}

              {activeTab === 'licenses' ? (
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950 text-slate-400 text-xs font-semibold uppercase">
                        <th className="p-4 pl-6">Kode Lisensi</th>
                        <th className="p-4">Email Pembelian</th>
                        <th className="p-4">Status Penggunaan</th>
                        <th className="p-4 pr-6">Terbit Pada</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800">
                      {filteredLicenses.length === 0 ? (
                        <tr>
                          <td colSpan={4} className="text-center p-12 text-slate-500 text-sm">
                            Tidak ada data lisensi ditemukan
                          </td>
                        </tr>
                      ) : (
                        filteredLicenses.map((lic, i) => (
                          <tr key={i} className="hover:bg-slate-800/30 transition-all text-sm">
                            <td className="p-4 pl-6 font-mono font-bold text-white">{lic.key}</td>
                            <td className="p-4 text-slate-300">
                              <span className="flex items-center gap-1.5">
                                <Mail size={14} className="text-slate-500" />
                                {lic.email}
                              </span>
                            </td>
                            <td className="p-4">
                              {lic.is_used ? (
                                <span className="inline-flex items-center gap-1 bg-green-500/10 text-green-400 px-3 py-1 rounded-full text-xs font-semibold border border-green-500/20">
                                  <CheckCircle size={12} /> Sudah Aktif
                                </span>
                              ) : (
                                <span className="inline-flex items-center gap-1 bg-yellow-500/10 text-yellow-400 px-3 py-1 rounded-full text-xs font-semibold border border-yellow-500/20">
                                  <AlertCircle size={12} /> Belum Digunakan
                                </span>
                              )}
                            </td>
                            <td className="p-4 pr-6 text-slate-400 text-xs">
                              {new Date(lic.created_at).toLocaleString('id-ID', {
                                day: 'numeric',
                                month: 'short',
                                year: 'numeric',
                                hour: '2-digit',
                                minute: '2-digit'
                              })}
                            </td>
                          </tr>
                        ))
                      )}
                    </tbody>
                  </table>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse">
                    <thead>
                      <tr className="border-b border-slate-800 bg-slate-950 text-slate-400 text-xs font-semibold uppercase">
                        <th className="p-4 pl-6">Nama Toko</th>
                        <th className="p-4">Pemilik & Kontak</th>
                        <th className="p-4">Lisensi Aktif</th>
                        <th className="p-4 text-emerald-400">Saldo Referral</th>
                        <th className="p-4 pr-6">Bergabung</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-800">
                      {filteredStores.length === 0 ? (
                        <tr>
                          <td colSpan={5} className="text-center p-12 text-slate-500 text-sm">
                            Tidak ada data toko terdaftar
                          </td>
                        </tr>
                      ) : (
                        filteredStores.map((store, i) => {
                          const sellerObj = Array.isArray(store.sellers) ? store.sellers[0] : store.sellers;
                          const referralBalance = sellerObj?.balance ? Number(sellerObj.balance) : 0;
                          return (
                            <tr key={i} className="hover:bg-slate-800/30 transition-all text-sm">
                              <td className="p-4 pl-6">
                                <div className="font-bold text-white flex items-center gap-1.5">
                                  <Store size={15} className="text-blue-500" />
                                  {store.store_name}
                                </div>
                                <div className="text-slate-500 text-[11px] mt-0.5">{store.address || 'Alamat tidak diisi'}</div>
                              </td>
                              <td className="p-4">
                                <div className="text-slate-300 font-medium">{store.owner_name || '-'}</div>
                                <div className="text-slate-400 text-xs mt-0.5">{store.phone || store.email}</div>
                              </td>
                              <td className="p-4 font-mono font-bold text-blue-400">{store.license_key}</td>
                              <td className="p-4">
                                <span className="font-bold text-emerald-400">
                                  Rp {referralBalance.toLocaleString('id-ID')}
                                </span>
                                {sellerObj?.slug && (
                                  <div className="text-[10px] text-slate-500 font-mono mt-0.5">
                                    slug: {sellerObj.slug}
                                  </div>
                                )}
                              </td>
                              <td className="p-4 pr-6 text-slate-400 text-xs">
                                {new Date(store.created_at).toLocaleString('id-ID', {
                                  day: 'numeric',
                                  month: 'short',
                                  year: 'numeric'
                                })}
                              </td>
                            </tr>
                          );
                        })
                      )}
                    </tbody>
                  </table>
                </div>
              )}

              {/* === RESELLER TAB === */}
              {activeTab === 'resellers' && (
                <div className="p-5 space-y-6">

                  {/* Edit Harga Modal */}
                  {editReseller && (
                    <div className="fixed inset-0 bg-black/60 backdrop-blur-sm flex items-center justify-center z-50 p-4">
                      <div className="bg-slate-900 border border-slate-700 rounded-3xl p-6 w-full max-w-sm shadow-2xl">
                        <h3 className="text-white font-bold text-lg mb-1">Edit Harga Reseller</h3>
                        <p className="text-slate-400 text-sm mb-5">{editReseller.name} · @{editReseller.slug}</p>
                        <div className="space-y-3">
                          <div>
                            <label className="block text-slate-400 text-xs font-semibold uppercase mb-1">Harga Jual (Rp)</label>
                            <input type="number" value={editSellPrice} onChange={e => setEditSellPrice(e.target.value)}
                              className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-2.5 text-white outline-none focus:border-violet-500 text-sm"
                            />
                          </div>
                          <div>
                            <label className="block text-slate-400 text-xs font-semibold uppercase mb-1">Harga Dasar (Rp)</label>
                            <input type="number" value={editBasePrice} onChange={e => setEditBasePrice(e.target.value)}
                              className="w-full bg-slate-950 border border-slate-700 rounded-xl px-4 py-2.5 text-white outline-none focus:border-violet-500 text-sm"
                            />
                          </div>
                          <div className="bg-violet-500/10 border border-violet-500/30 rounded-xl px-4 py-2 text-sm">
                            <span className="text-slate-400">Komisi reseller: </span>
                            <span className="text-violet-300 font-bold">
                              Rp {(Number(editSellPrice || 0) - Number(editBasePrice || 0)).toLocaleString('id-ID')} / lisensi
                            </span>
                          </div>
                        </div>
                        <div className="flex gap-3 mt-5">
                          <button onClick={() => setEditReseller(null)} className="flex-1 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-300 font-semibold rounded-xl text-sm transition-all cursor-pointer">
                            Batal
                          </button>
                          <button onClick={handleUpdateReseller} disabled={editLoading} className="flex-1 py-2.5 bg-violet-600 hover:bg-violet-700 text-white font-bold rounded-xl text-sm transition-all disabled:opacity-50 cursor-pointer">
                            {editLoading ? 'Menyimpan...' : 'Simpan'}
                          </button>
                        </div>
                      </div>
                    </div>
                  )}

                  {/* Form Tambah Reseller */}
                  <div className="bg-slate-950 border border-violet-500/20 rounded-2xl p-5">
                    <h3 className="text-white font-bold text-base mb-4 flex items-center gap-2">
                      <PlusCircle className="text-violet-400" size={18} /> Tambah Reseller Baru
                    </h3>
                    {resellerFormError && (
                      <div className="bg-red-500/10 border border-red-500/30 text-red-400 text-xs rounded-xl px-4 py-2.5 mb-4">⚠️ {resellerFormError}</div>
                    )}
                    {resellerFormSuccess && (
                      <div className="bg-green-500/10 border border-green-500/30 text-green-400 text-xs rounded-xl px-4 py-2.5 mb-4">✅ {resellerFormSuccess}</div>
                    )}
                    <form onSubmit={handleAddReseller} className="grid grid-cols-2 gap-3">
                      <div className="col-span-2 md:col-span-1">
                        <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Nama Reseller</label>
                        <input required value={resellerForm.name}
                          onChange={e => {
                            const n = e.target.value;
                            setResellerForm(p => ({ ...p, name: n, slug: n.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '') }));
                          }}
                          placeholder="Budi Santoso"
                          className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-violet-500 focus:ring-1 focus:ring-violet-500/20"
                        />
                      </div>
                      <div className="col-span-2 md:col-span-1">
                        <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Slug (Link ID)</label>
                        <input required value={resellerForm.slug}
                          onChange={e => setResellerForm(p => ({ ...p, slug: e.target.value.toLowerCase().replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, '') }))}
                          placeholder="budi-santoso"
                          className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-violet-500 font-mono"
                        />
                      </div>
                      <div className="col-span-2 md:col-span-1">
                        <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Email Login</label>
                        <input required type="email" value={resellerForm.email}
                          onChange={e => setResellerForm(p => ({ ...p, email: e.target.value }))}
                          placeholder="budi@email.com"
                          className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-violet-500"
                        />
                      </div>
                      <div className="col-span-2 md:col-span-1">
                        <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Password</label>
                        <input required type="password" value={resellerForm.password}
                          onChange={e => setResellerForm(p => ({ ...p, password: e.target.value }))}
                          placeholder="Min 8 karakter"
                          className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-violet-500"
                        />
                      </div>
                      <div>
                        <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Harga Jual (Rp)</label>
                        <input required type="number" value={resellerForm.sell_price}
                          onChange={e => setResellerForm(p => ({ ...p, sell_price: e.target.value }))}
                          placeholder="50000"
                          className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-violet-500"
                        />
                      </div>
                      <div>
                        <label className="block text-slate-400 text-[11px] font-semibold uppercase mb-1">Harga Dasar (Rp)</label>
                        <input required type="number" value={resellerForm.base_price}
                          onChange={e => setResellerForm(p => ({ ...p, base_price: e.target.value }))}
                          placeholder="25000"
                          className="w-full bg-slate-900 border border-slate-700 rounded-xl px-3 py-2.5 text-white text-sm outline-none focus:border-violet-500"
                        />
                      </div>
                      {resellerForm.sell_price && resellerForm.base_price && (
                        <div className="col-span-2 bg-violet-500/10 border border-violet-500/30 rounded-xl px-4 py-2 text-sm">
                          <span className="text-slate-400">Komisi per penjualan: </span>
                          <span className="text-violet-300 font-bold">
                            Rp {(Number(resellerForm.sell_price) - Number(resellerForm.base_price)).toLocaleString('id-ID')}
                          </span>
                        </div>
                      )}
                      <button type="submit" className="col-span-2 py-2.5 bg-violet-600 hover:bg-violet-700 text-white font-bold rounded-xl text-sm transition-all cursor-pointer flex items-center justify-center gap-2">
                        <PlusCircle size={16} /> Tambah Reseller
                      </button>
                    </form>
                  </div>

                  {/* Daftar Reseller */}
                  <div>
                    <h3 className="text-white font-bold text-base mb-3 flex items-center gap-2">
                      <Users className="text-violet-400" size={16} /> Daftar Reseller ({resellers.length})
                    </h3>
                    {resellerLoading ? (
                      <div className="text-center py-8 text-slate-400 text-sm flex items-center justify-center gap-2">
                        <RefreshCw size={16} className="animate-spin" /> Memuat...
                      </div>
                    ) : resellers.length === 0 ? (
                      <div className="text-center py-8 text-slate-500 text-sm">Belum ada reseller</div>
                    ) : (
                      <div className="space-y-3">
                        {resellers.map((r: any) => {
                          const comm = Number(r.sell_price) - Number(r.base_price);
                          return (
                            <div key={r.id} className={`bg-slate-950 border rounded-2xl p-4 ${r.is_active ? 'border-slate-800' : 'border-red-900/40 opacity-60'}`}>
                              <div className="flex items-start justify-between mb-3">
                                <div>
                                  <div className="flex items-center gap-2">
                                    <span className="text-white font-bold">{r.name}</span>
                                    {!r.is_active && <span className="text-[10px] font-bold text-red-400 bg-red-500/10 border border-red-500/30 px-2 py-0.5 rounded-full">Nonaktif</span>}
                                  </div>
                                  <p className="text-slate-500 text-xs">{r.email}</p>
                                </div>
                                <div className="flex gap-2 ml-3">
                                  <button
                                    onClick={() => { setEditReseller(r); setEditSellPrice(r.sell_price); setEditBasePrice(r.base_price); }}
                                    className="p-2 bg-slate-800 hover:bg-violet-600/30 hover:text-violet-400 text-slate-400 rounded-xl transition-all cursor-pointer"
                                    title="Edit Harga"
                                  >
                                    <Edit2 size={14} />
                                  </button>
                                  <button
                                    onClick={() => handleToggleResellerActive(r.slug, r.is_active)}
                                    className={`p-2 rounded-xl transition-all cursor-pointer ${r.is_active ? 'bg-slate-800 hover:bg-red-600/20 hover:text-red-400 text-slate-400' : 'bg-green-600/20 text-green-400 hover:bg-green-600/30'}`}
                                    title={r.is_active ? 'Nonaktifkan' : 'Aktifkan'}
                                  >
                                    <Ban size={14} />
                                  </button>
                                </div>
                              </div>
                              <div className="grid grid-cols-2 md:grid-cols-4 gap-2 mb-3">
                                <div className="bg-slate-900 rounded-xl px-3 py-2 text-center">
                                  <p className="text-slate-500 text-[10px] uppercase font-semibold">Terjual</p>
                                  <p className="text-white font-bold text-lg">{r.total_sales}</p>
                                </div>
                                <div className="bg-slate-900 rounded-xl px-3 py-2 text-center">
                                  <p className="text-slate-500 text-[10px] uppercase font-semibold">Saldo</p>
                                  <p className="text-amber-400 font-bold text-sm">Rp {Number(r.balance).toLocaleString('id-ID')}</p>
                                </div>
                                <div className="bg-slate-900 rounded-xl px-3 py-2 text-center">
                                  <p className="text-slate-500 text-[10px] uppercase font-semibold">Total Komisi</p>
                                  <p className="text-emerald-400 font-bold text-sm">Rp {Number(r.total_earned).toLocaleString('id-ID')}</p>
                                </div>
                                <div className="bg-slate-900 rounded-xl px-3 py-2 text-center">
                                  <p className="text-slate-500 text-[10px] uppercase font-semibold">Komisi/Lisensi</p>
                                  <p className="text-violet-400 font-bold text-sm">Rp {comm.toLocaleString('id-ID')}</p>
                                </div>
                              </div>
                              <div className="flex items-center gap-2">
                                <div className="flex-1 bg-slate-900 rounded-xl px-3 py-2 text-xs text-slate-400 font-mono truncate">
                                  /beli?ref={r.slug} · Jual Rp {Number(r.sell_price).toLocaleString('id-ID')} · Dasar Rp {Number(r.base_price).toLocaleString('id-ID')}
                                </div>
                                <button
                                  onClick={() => copyResellerLink(r.slug)}
                                  className="p-2 bg-blue-600/20 hover:bg-blue-600/30 text-blue-400 rounded-xl transition-all cursor-pointer shrink-0"
                                  title="Salin Link"
                                >
                                  {copiedSlug === r.slug ? <Check size={14} /> : <Link2 size={14} />}
                                </button>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>

                  {/* Withdrawal Reseller */}
                  <div>
                    <h3 className="text-white font-bold text-base mb-3 flex items-center gap-2">
                      <Wallet className="text-emerald-400" size={16} /> Penarikan Komisi Reseller
                    </h3>
                    <div className="flex items-center gap-2 mb-3 flex-wrap">
                      {(['pending', 'approved', 'rejected'] as const).map(s => (
                        <button
                          key={s}
                          onClick={() => { setResellerWdFilter(s); fetchResellerWithdrawals(s); }}
                          className={`px-4 py-1.5 rounded-full text-xs font-bold transition-all cursor-pointer border ${
                            resellerWdFilter === s
                              ? s === 'pending' ? 'bg-yellow-500/20 text-yellow-300 border-yellow-500/40'
                                : s === 'approved' ? 'bg-green-500/20 text-green-300 border-green-500/40'
                                : 'bg-red-500/20 text-red-300 border-red-500/40'
                              : 'bg-slate-800 text-slate-400 border-slate-700 hover:text-white'
                          }`}
                        >
                          {s === 'pending' ? '⏳ Menunggu' : s === 'approved' ? '✅ Disetujui' : '❌ Ditolak'}
                        </button>
                      ))}
                      <button onClick={() => fetchResellerWithdrawals(resellerWdFilter)} className="ml-auto p-2 rounded-xl bg-slate-800 hover:bg-slate-700 text-slate-400 hover:text-white transition-all cursor-pointer">
                        <RefreshCw size={13} />
                      </button>
                    </div>

                    {resellerWdLoading ? (
                      <div className="text-center py-8 text-slate-400 text-sm flex items-center justify-center gap-2"><RefreshCw size={16} className="animate-spin" /> Memuat...</div>
                    ) : resellerWds.length === 0 ? (
                      <div className="text-center py-8 text-slate-500 text-sm">Tidak ada permintaan</div>
                    ) : (
                      <div className="space-y-3">
                        {resellerWds.map((w: any) => (
                          <div key={w.id} className="bg-slate-950 border border-slate-800 rounded-2xl p-4">
                            <div className="flex items-start justify-between mb-2">
                              <div>
                                <p className="text-white font-bold">{w.resellers?.name || '-'}</p>
                                <p className="text-slate-500 text-xs">{w.resellers?.email}</p>
                              </div>
                              <span className="text-emerald-400 font-black text-lg">Rp {Number(w.amount).toLocaleString('id-ID')}</span>
                            </div>
                            <div className="text-slate-400 text-xs mb-2">
                              🏦 {w.bank_name} · {w.bank_account} · {w.bank_holder}
                            </div>
                            <p className="text-slate-600 text-[11px] mb-3">
                              {new Date(w.created_at).toLocaleString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' })}
                            </p>
                            {resellerWdFilter === 'pending' && (
                              <div className="flex flex-col gap-2">
                                <input
                                  type="text"
                                  placeholder="Catatan penolakan (opsional)"
                                  value={resellerWdRejectNote[w.id] || ''}
                                  onChange={e => setResellerWdRejectNote(prev => ({ ...prev, [w.id]: e.target.value }))}
                                  className="w-full px-3 py-1.5 bg-slate-900 border border-slate-700 rounded-lg text-xs text-white outline-none focus:ring-1 focus:ring-violet-500/50"
                                />
                                <div className="flex gap-2">
                                  <button
                                    onClick={() => handleResellerWdAction(w.id, 'approved')}
                                    disabled={resellerWdProcessingId === w.id}
                                    className="flex-1 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-lg transition-all disabled:opacity-50 cursor-pointer flex items-center justify-center gap-1"
                                  >
                                    <CheckCircle size={12} /> Setujui
                                  </button>
                                  <button
                                    onClick={() => handleResellerWdAction(w.id, 'rejected')}
                                    disabled={resellerWdProcessingId === w.id}
                                    className="flex-1 py-1.5 bg-red-600 hover:bg-red-700 text-white text-xs font-bold rounded-lg transition-all disabled:opacity-50 cursor-pointer flex items-center justify-center gap-1"
                                  >
                                    <XCircle size={12} /> Tolak
                                  </button>
                                </div>
                              </div>
                            )}
                            {resellerWdFilter !== 'pending' && w.note && (
                              <p className="text-slate-500 text-xs italic">Catatan: {w.note}</p>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                </div>
              )}

            </div>
          </div>
        </div>
      </div>
    </main>
  );
}

