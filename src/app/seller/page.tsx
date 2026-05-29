'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

export default function SellerLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [licenseKey, setLicenseKey] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError('');

    try {
      const res = await fetch('/api/sellers/auth', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, license_key: licenseKey }),
      });

      const data = await res.json();
      if (!res.ok) { setError(data.error); return; }

      // Simpan session ke localStorage
      localStorage.setItem(`seller_session_${data.slug}`, JSON.stringify(data));

      // Redirect ke dashboard seller
      router.push(`/seller/${data.slug}`);
    } catch (e: any) {
      setError('Koneksi gagal, coba lagi');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="root">
      <div className="card">
        <div className="logo">🏪</div>
        <h1 className="title">Masuk ke Toko Online</h1>
        <p className="subtitle">Login dengan email dan kode lisensi Cashiro Anda</p>

        <form onSubmit={handleLogin} className="form">
          <div className="field">
            <label className="label">Email</label>
            <input
              className="input"
              type="email"
              placeholder="email@toko.com"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
            />
          </div>
          <div className="field">
            <label className="label">Kode Lisensi</label>
            <input
              className="input"
              type="text"
              placeholder="Contoh: ABCD-1234-EFGH"
              value={licenseKey}
              onChange={e => setLicenseKey(e.target.value)}
              required
            />
          </div>

          {error && (
            <div className="error-box">
              ⚠️ {error}
            </div>
          )}

          <button className="btn" type="submit" disabled={loading}>
            {loading ? (
              <span className="spinner-wrap">
                <span className="spinner" /> Memverifikasi...
              </span>
            ) : (
              'Masuk ke Dashboard →'
            )}
          </button>
        </form>

        <div className="divider" />

        <div className="info-box">
          <div className="info-title">ℹ️ Kode lisensi bisa ditemukan di</div>
          <ul className="info-list">
            <li>📱 Aplikasi Cashiro → Menu → Info Toko</li>
            <li>📧 Email konfirmasi pembelian lisensi</li>
          </ul>
        </div>
      </div>

      <style>{`
        @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap');
        * { box-sizing: border-box; margin: 0; padding: 0; }
        .root {
          min-height: 100vh;
          display: flex;
          align-items: center;
          justify-content: center;
          background: linear-gradient(135deg, #006d77 0%, #004d55 60%, #1a1a2e 100%);
          font-family: 'Outfit', sans-serif;
          padding: 20px;
        }
        .card {
          background: white;
          border-radius: 28px;
          padding: 44px 40px;
          width: 100%;
          max-width: 440px;
          box-shadow: 0 24px 80px rgba(0,0,0,0.25);
        }
        .logo { font-size: 58px; text-align: center; margin-bottom: 18px; }
        .title { font-size: 26px; font-weight: 800; text-align: center; color: #1a1a2e; }
        .subtitle { font-size: 14px; color: #888; text-align: center; margin: 8px 0 32px; line-height: 1.5; }

        .form { display: flex; flex-direction: column; gap: 18px; }
        .field { display: flex; flex-direction: column; gap: 6px; }
        .label { font-size: 13px; font-weight: 600; color: #444; }
        .input {
          padding: 14px 16px;
          border: 2px solid #e8e8f0;
          border-radius: 14px;
          font-size: 15px;
          font-family: inherit;
          outline: none;
          transition: border 0.2s, box-shadow 0.2s;
          color: #1a1a2e;
        }
        .input:focus { border-color: #006d77; box-shadow: 0 0 0 4px rgba(0,109,119,0.1); }

        .error-box {
          background: #fef2f2;
          color: #dc2626;
          padding: 12px 16px;
          border-radius: 12px;
          font-size: 14px;
          border: 1px solid #fecaca;
        }

        .btn {
          background: linear-gradient(135deg, #006d77, #004d55);
          color: white;
          border: none;
          border-radius: 14px;
          padding: 15px;
          font-size: 16px;
          font-weight: 700;
          cursor: pointer;
          font-family: inherit;
          transition: opacity 0.2s, transform 0.2s;
          margin-top: 4px;
        }
        .btn:hover:not(:disabled) { opacity: 0.9; transform: translateY(-1px); }
        .btn:disabled { opacity: 0.6; cursor: not-allowed; }
        .spinner-wrap { display: flex; align-items: center; justify-content: center; gap: 10px; }
        .spinner {
          width: 18px; height: 18px;
          border: 2px solid rgba(255,255,255,0.3);
          border-top-color: white;
          border-radius: 50%;
          animation: spin 0.7s linear infinite;
          display: inline-block;
        }
        @keyframes spin { to { transform: rotate(360deg); } }

        .divider { height: 1px; background: #f0f0f8; margin: 28px 0; }

        .info-box {
          background: #f0f9ff;
          border: 1px solid #bae6fd;
          border-radius: 14px;
          padding: 16px;
        }
        .info-title { font-size: 13px; font-weight: 700; color: #0369a1; margin-bottom: 10px; }
        .info-list { list-style: none; display: flex; flex-direction: column; gap: 8px; }
        .info-list li { font-size: 13px; color: #0c4a6e; line-height: 1.4; }

        @media (max-width: 480px) {
          .card { padding: 32px 24px; }
          .title { font-size: 22px; }
        }
      `}</style>
    </div>
  );
}
