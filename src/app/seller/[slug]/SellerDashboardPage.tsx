'use client';

import { useState, useEffect, useCallback } from 'react';

interface Store {
  store_name: string;
  owner_name: string;
  phone: string;
  address: string;
}

interface SellerSession {
  seller_id: number;
  slug: string;
  balance: number;
  store: Store;
}

interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
  image_url: string;
  is_active: boolean;
}

interface Order {
  id: number;
  customer_name: string;
  customer_phone: string;
  items: any[];
  total_amount: number;
  payment_method: string;
  status: string;
  created_at: string;
}

function formatRupiah(n: number) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(n);
}

function formatDate(d: string) {
  return new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

export default function SellerDashboardPage({ slug }: { slug: string }) {
  const [session, setSession] = useState<SellerSession | null>(null);
  const [tab, setTab] = useState<'products' | 'orders' | 'link'>('products');
  const [products, setProducts] = useState<Product[]>([]);
  const [orders, setOrders] = useState<Order[]>([]);
  const [loading, setLoading] = useState(false);

  // Login form
  const [email, setEmail] = useState('');
  const [licenseKey, setLicenseKey] = useState('');
  const [loginError, setLoginError] = useState('');
  const [loginLoading, setLoginLoading] = useState(false);

  // Product form
  const [showProductForm, setShowProductForm] = useState(false);
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [pName, setPName] = useState('');
  const [pDesc, setPDesc] = useState('');
  const [pPrice, setPPrice] = useState('');
  const [pStock, setPStock] = useState('');
  const [pImage, setPImage] = useState('');
  const [productError, setProductError] = useState('');
  const [productLoading, setProductLoading] = useState(false);

  const [copied, setCopied] = useState(false);

  // Restore session dari localStorage
  useEffect(() => {
    const saved = localStorage.getItem(`seller_session_${slug}`);
    if (saved) {
      try {
        const parsed = JSON.parse(saved);
        setSession(parsed);
      } catch {}
    }
  }, [slug]);

  const fetchProducts = useCallback(async () => {
    const res = await fetch(`/api/sellers/${slug}/products`);
    const data = await res.json();
    setProducts(data.products || []);
  }, [slug]);

  const fetchOrders = useCallback(async () => {
    const res = await fetch(`/api/sellers/${slug}/orders`);
    const data = await res.json();
    setOrders(data.orders || []);
  }, [slug]);

  useEffect(() => {
    if (session) {
      fetchProducts();
      fetchOrders();
    }
  }, [session, fetchProducts, fetchOrders]);

  // Login
  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoginLoading(true);
    setLoginError('');
    try {
      const res = await fetch(`/api/sellers/${slug}/login`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ email, license_key: licenseKey }),
      });
      const data = await res.json();
      if (!res.ok) { setLoginError(data.error); return; }
      localStorage.setItem(`seller_session_${slug}`, JSON.stringify(data));
      setSession(data);
    } catch (e: any) {
      setLoginError(e.message);
    } finally {
      setLoginLoading(false);
    }
  };

  const handleLogout = () => {
    localStorage.removeItem(`seller_session_${slug}`);
    setSession(null);
  };

  // Simpan Produk
  const openAddProduct = () => {
    setEditProduct(null);
    setPName(''); setPDesc(''); setPPrice(''); setPStock(''); setPImage('');
    setProductError('');
    setShowProductForm(true);
  };

  const openEditProduct = (p: Product) => {
    setEditProduct(p);
    setPName(p.name); setPDesc(p.description); setPPrice(String(p.price)); setPStock(String(p.stock)); setPImage(p.image_url);
    setProductError('');
    setShowProductForm(true);
  };

  const handleSaveProduct = async () => {
    if (!pName || !pPrice) { setProductError('Nama dan harga wajib diisi'); return; }
    setProductLoading(true);
    setProductError('');
    try {
      if (editProduct) {
        // Update
        await fetch(`/api/sellers/${slug}/products`, {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            store_id: session?.seller_id,
            product_id: editProduct.id,
            name: pName, description: pDesc,
            price: Number(pPrice), stock: Number(pStock), image_url: pImage,
          }),
        });
      } else {
        // Tambah baru
        await fetch(`/api/sellers/${slug}/products`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            store_id: session?.seller_id,
            name: pName, description: pDesc,
            price: Number(pPrice), stock: Number(pStock), image_url: pImage,
          }),
        });
      }
      setShowProductForm(false);
      fetchProducts();
    } catch (e: any) {
      setProductError(e.message);
    } finally {
      setProductLoading(false);
    }
  };

  const handleToggleProduct = async (p: Product) => {
    await fetch(`/api/sellers/${slug}/products`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ store_id: session?.seller_id, product_id: p.id, is_active: !p.is_active }),
    });
    fetchProducts();
  };

  const storeUrl = typeof window !== 'undefined' ? `${window.location.origin}/store/${slug}` : `/store/${slug}`;

  const copyLink = () => {
    navigator.clipboard.writeText(storeUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  // === LOGIN PAGE ===
  if (!session) {
    return (
      <div className="auth-root">
        <div className="auth-card">
          <div className="auth-logo">🏪</div>
          <h1 className="auth-title">Dashboard Seller</h1>
          <p className="auth-subtitle">Login untuk kelola toko online <strong>{slug}</strong></p>
          <form onSubmit={handleLogin} className="auth-form">
            <input className="auth-input" type="email" placeholder="Email terdaftar" value={email} onChange={e => setEmail(e.target.value)} required />
            <input className="auth-input" type="text" placeholder="Kode Lisensi" value={licenseKey} onChange={e => setLicenseKey(e.target.value)} required />
            {loginError && <p className="auth-error">⚠️ {loginError}</p>}
            <button className="auth-btn" type="submit" disabled={loginLoading}>
              {loginLoading ? 'Memverifikasi...' : 'Masuk ke Dashboard →'}
            </button>
          </form>
          <a href={`/store/${slug}`} className="auth-link">← Lihat halaman toko</a>
        </div>
        <style>{authStyles}</style>
      </div>
    );
  }

  // === DASHBOARD ===
  const pendingOrders = orders.filter(o => o.status === 'pending').length;
  const totalRevenue = orders.filter(o => o.status === 'paid').reduce((s, o) => s + o.total_amount, 0);

  return (
    <div className="dash-root">
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-logo">
          <span className="sidebar-icon">🏪</span>
          <div>
            <div className="sidebar-store-name">{session.store.store_name}</div>
            <div className="sidebar-slug">/{slug}</div>
          </div>
        </div>
        <nav className="sidebar-nav">
          {[
            { key: 'products', label: '📦 Produk', badge: products.length },
            { key: 'orders', label: '🛒 Pesanan', badge: pendingOrders > 0 ? pendingOrders : null },
            { key: 'link', label: '🔗 Link Toko', badge: null },
          ].map(item => (
            <button key={item.key} className={`sidebar-item ${tab === item.key ? 'active' : ''}`} onClick={() => setTab(item.key as any)}>
              <span>{item.label}</span>
              {item.badge !== null && <span className="sidebar-badge">{item.badge}</span>}
            </button>
          ))}
        </nav>
        <div className="sidebar-balance">
          <div className="balance-label">💰 Saldo</div>
          <div className="balance-amount">{formatRupiah(session.balance)}</div>
        </div>
        <button className="sidebar-logout" onClick={handleLogout}>🚪 Keluar</button>
      </aside>

      {/* Main */}
      <main className="dash-main">
        {/* Stats */}
        <div className="stats-row">
          <div className="stat-card">
            <div className="stat-label">Total Produk</div>
            <div className="stat-value">{products.length}</div>
          </div>
          <div className="stat-card">
            <div className="stat-label">Pesanan Masuk</div>
            <div className="stat-value">{orders.length}</div>
          </div>
          <div className="stat-card">
            <div className="stat-label">Pending</div>
            <div className="stat-value warn">{pendingOrders}</div>
          </div>
          <div className="stat-card">
            <div className="stat-label">Pendapatan</div>
            <div className="stat-value green">{formatRupiah(totalRevenue)}</div>
          </div>
        </div>

        {/* PRODUK TAB */}
        {tab === 'products' && (
          <section className="section">
            <div className="section-header">
              <h2 className="section-title">📦 Daftar Produk</h2>
              <button className="primary-btn" onClick={openAddProduct}>+ Tambah Produk</button>
            </div>
            {products.length === 0 ? (
              <div className="empty">
                <span>📦</span>
                <p>Belum ada produk. Tambahkan produk pertama Anda!</p>
                <button className="primary-btn" onClick={openAddProduct}>+ Tambah Produk</button>
              </div>
            ) : (
              <div className="product-table-wrap">
                <table className="product-table">
                  <thead>
                    <tr>
                      <th>Produk</th><th>Harga</th><th>Stok</th><th>Status</th><th>Aksi</th>
                    </tr>
                  </thead>
                  <tbody>
                    {products.map(p => (
                      <tr key={p.id} className={!p.is_active ? 'inactive-row' : ''}>
                        <td>
                          <div className="product-cell">
                            {p.image_url ? <img src={p.image_url} className="product-thumb" alt={p.name} /> : <div className="product-thumb-empty">🛍️</div>}
                            <div>
                              <div className="product-cell-name">{p.name}</div>
                              {p.description && <div className="product-cell-desc">{p.description}</div>}
                            </div>
                          </div>
                        </td>
                        <td className="price-cell">{formatRupiah(p.price)}</td>
                        <td>
                          <span className={`stock-pill ${p.stock === 0 ? 'out' : p.stock <= 5 ? 'low' : 'in'}`}>
                            {p.stock === 0 ? 'Habis' : `${p.stock} pcs`}
                          </span>
                        </td>
                        <td>
                          <button className={`toggle-btn ${p.is_active ? 'active' : ''}`} onClick={() => handleToggleProduct(p)}>
                            {p.is_active ? '✅ Aktif' : '❌ Nonaktif'}
                          </button>
                        </td>
                        <td>
                          <button className="edit-btn" onClick={() => openEditProduct(p)}>✏️ Edit</button>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </section>
        )}

        {/* ORDERS TAB */}
        {tab === 'orders' && (
          <section className="section">
            <div className="section-header">
              <h2 className="section-title">🛒 Daftar Pesanan</h2>
              <button className="secondary-btn" onClick={fetchOrders}>🔄 Refresh</button>
            </div>
            {orders.length === 0 ? (
              <div className="empty"><span>🛒</span><p>Belum ada pesanan masuk</p></div>
            ) : (
              <div className="order-list">
                {orders.map(o => (
                  <div key={o.id} className="order-card">
                    <div className="order-card-top">
                      <div>
                        <div className="order-id">#{o.id} · {o.customer_name || 'Anonim'}</div>
                        {o.customer_phone && <div className="order-phone">📱 {o.customer_phone}</div>}
                        <div className="order-date">🕐 {formatDate(o.created_at)}</div>
                      </div>
                      <div className="order-right">
                        <div className="order-total">{formatRupiah(o.total_amount)}</div>
                        <span className={`status-pill ${o.status}`}>{o.status === 'paid' ? '✅ Lunas' : o.status === 'pending' ? '⏳ Pending' : '❌ Batal'}</span>
                        <span className="payment-pill">{o.payment_method === 'qris' ? '📱 QRIS' : '💵 Manual'}</span>
                      </div>
                    </div>
                    <div className="order-items">
                      {Array.isArray(o.items) && o.items.map((item: any, i: number) => (
                        <span key={i} className="order-item-chip">{item.name} ×{item.qty}</span>
                      ))}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </section>
        )}

        {/* LINK TAB */}
        {tab === 'link' && (
          <section className="section">
            <h2 className="section-title">🔗 Link Toko Online Anda</h2>
            <p className="link-desc">Bagikan link ini ke pelanggan agar mereka bisa melihat dan memesan produk Anda secara online.</p>
            <div className="link-box">
              <span className="link-url">{storeUrl}</span>
              <button className="copy-btn" onClick={copyLink}>{copied ? '✅ Disalin!' : '📋 Salin'}</button>
            </div>
            <div className="link-actions">
              <a href={`/store/${slug}`} target="_blank" rel="noopener noreferrer" className="primary-btn">🌐 Buka Toko →</a>
            </div>
            <div className="share-tips">
              <h3>💡 Tips Bagikan Link</h3>
              <ul>
                <li>📱 <strong>WhatsApp:</strong> Copy link di atas lalu kirim ke grup atau kontak pelanggan</li>
                <li>📸 <strong>Instagram:</strong> Tambahkan link di bio Instagram Anda</li>
                <li>🗣️ <strong>Word of mouth:</strong> Ceritakan ke pelanggan bahwa Anda sudah punya toko online!</li>
              </ul>
            </div>
          </section>
        )}
      </main>

      {/* Modal Produk */}
      {showProductForm && (
        <div className="modal-overlay" onClick={e => { if ((e.target as any).classList.contains('modal-overlay')) setShowProductForm(false); }}>
          <div className="modal">
            <div className="modal-header">
              <span>{editProduct ? '✏️ Edit Produk' : '➕ Tambah Produk'}</span>
              <button className="modal-close" onClick={() => setShowProductForm(false)}>✕</button>
            </div>
            <div className="modal-body">
              <label className="form-label">Nama Produk *</label>
              <input className="form-input" value={pName} onChange={e => setPName(e.target.value)} placeholder="Nama produk" />
              <label className="form-label">Deskripsi</label>
              <textarea className="form-input" value={pDesc} onChange={e => setPDesc(e.target.value)} placeholder="Deskripsi singkat produk" rows={2} />
              <div className="form-row">
                <div className="form-col">
                  <label className="form-label">Harga (Rp) *</label>
                  <input className="form-input" type="number" value={pPrice} onChange={e => setPPrice(e.target.value)} placeholder="0" />
                </div>
                <div className="form-col">
                  <label className="form-label">Stok</label>
                  <input className="form-input" type="number" value={pStock} onChange={e => setPStock(e.target.value)} placeholder="0" />
                </div>
              </div>
              <label className="form-label">URL Gambar (opsional)</label>
              <input className="form-input" value={pImage} onChange={e => setPImage(e.target.value)} placeholder="https://..." />
              {pImage && <img src={pImage} alt="preview" className="img-preview" onError={e => (e.currentTarget.style.display = 'none')} />}
              {productError && <p className="form-error">⚠️ {productError}</p>}
            </div>
            <div className="modal-footer">
              <button className="secondary-btn" onClick={() => setShowProductForm(false)}>Batal</button>
              <button className="primary-btn" onClick={handleSaveProduct} disabled={productLoading}>
                {productLoading ? 'Menyimpan...' : editProduct ? 'Simpan Perubahan' : 'Tambah Produk'}
              </button>
            </div>
          </div>
        </div>
      )}

      <style>{dashStyles}</style>
    </div>
  );
}

const authStyles = `
  @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  .auth-root { min-height: 100vh; display: flex; align-items: center; justify-content: center; background: linear-gradient(135deg, #006d77 0%, #004d55 100%); font-family: 'Outfit', sans-serif; padding: 20px; }
  .auth-card { background: white; border-radius: 24px; padding: 40px; width: 100%; max-width: 420px; box-shadow: 0 20px 60px rgba(0,0,0,0.2); }
  .auth-logo { font-size: 56px; text-align: center; margin-bottom: 16px; }
  .auth-title { font-size: 26px; font-weight: 800; text-align: center; color: #1a1a2e; }
  .auth-subtitle { font-size: 14px; color: #666; text-align: center; margin: 8px 0 28px; line-height: 1.5; }
  .auth-form { display: flex; flex-direction: column; gap: 14px; }
  .auth-input { padding: 13px 16px; border: 2px solid #e8e8f0; border-radius: 14px; font-size: 15px; font-family: inherit; outline: none; transition: border 0.2s; }
  .auth-input:focus { border-color: #006d77; }
  .auth-error { background: #fef2f2; color: #dc2626; padding: 10px 14px; border-radius: 10px; font-size: 13px; }
  .auth-btn { background: #006d77; color: white; border: none; border-radius: 14px; padding: 14px; font-size: 16px; font-weight: 700; cursor: pointer; font-family: inherit; transition: background 0.2s; }
  .auth-btn:hover:not(:disabled) { background: #004d55; }
  .auth-btn:disabled { opacity: 0.6; }
  .auth-link { display: block; text-align: center; margin-top: 20px; color: #006d77; text-decoration: none; font-size: 14px; }
`;

const dashStyles = `
  @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap');
  * { box-sizing: border-box; margin: 0; padding: 0; }
  .dash-root { display: flex; min-height: 100vh; font-family: 'Outfit', sans-serif; background: #f8f9ff; }

  /* Sidebar */
  .sidebar { width: 240px; background: linear-gradient(180deg, #006d77 0%, #004d55 100%); color: white; display: flex; flex-direction: column; padding: 24px 16px; gap: 8px; position: sticky; top: 0; height: 100vh; }
  .sidebar-logo { display: flex; align-items: center; gap: 10px; padding: 8px 8px 20px; border-bottom: 1px solid rgba(255,255,255,0.15); margin-bottom: 8px; }
  .sidebar-icon { font-size: 30px; }
  .sidebar-store-name { font-size: 14px; font-weight: 700; line-height: 1.2; }
  .sidebar-slug { font-size: 11px; opacity: 0.6; }
  .sidebar-nav { display: flex; flex-direction: column; gap: 4px; flex: 1; }
  .sidebar-item { display: flex; align-items: center; justify-content: space-between; padding: 12px 14px; border-radius: 12px; background: none; border: none; color: rgba(255,255,255,0.7); font-size: 14px; font-weight: 500; cursor: pointer; font-family: inherit; transition: all 0.2s; text-align: left; }
  .sidebar-item:hover, .sidebar-item.active { background: rgba(255,255,255,0.15); color: white; }
  .sidebar-badge { background: #ffb703; color: #1a1a2e; border-radius: 20px; padding: 2px 8px; font-size: 11px; font-weight: 700; }
  .sidebar-balance { background: rgba(255,255,255,0.1); border-radius: 14px; padding: 14px; margin-top: auto; }
  .balance-label { font-size: 11px; opacity: 0.7; margin-bottom: 4px; }
  .balance-amount { font-size: 18px; font-weight: 700; }
  .sidebar-logout { background: rgba(255,255,255,0.1); border: none; color: rgba(255,255,255,0.8); padding: 10px; border-radius: 10px; cursor: pointer; font-family: inherit; font-size: 13px; transition: background 0.2s; margin-top: 8px; }
  .sidebar-logout:hover { background: rgba(255,0,0,0.3); }

  /* Main */
  .dash-main { flex: 1; padding: 28px; overflow-y: auto; }
  .stats-row { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 24px; }
  .stat-card { background: white; border-radius: 18px; padding: 20px; box-shadow: 0 2px 12px rgba(0,0,0,0.05); border: 1px solid #f0f0f8; }
  .stat-label { font-size: 12px; color: #888; margin-bottom: 8px; font-weight: 500; }
  .stat-value { font-size: 26px; font-weight: 800; color: #1a1a2e; }
  .stat-value.warn { color: #f59e0b; }
  .stat-value.green { color: #006d77; }

  /* Section */
  .section { background: white; border-radius: 20px; padding: 24px; box-shadow: 0 2px 12px rgba(0,0,0,0.05); border: 1px solid #f0f0f8; }
  .section-header { display: flex; align-items: center; justify-content: space-between; margin-bottom: 20px; }
  .section-title { font-size: 18px; font-weight: 700; }
  .empty { text-align: center; padding: 60px 20px; color: #aaa; display: flex; flex-direction: column; align-items: center; gap: 12px; }
  .empty span { font-size: 56px; }
  .empty p { font-size: 15px; }

  /* Table */
  .product-table-wrap { overflow-x: auto; }
  .product-table { width: 100%; border-collapse: collapse; }
  .product-table th { text-align: left; padding: 10px 14px; font-size: 12px; color: #888; border-bottom: 1px solid #f0f0f8; font-weight: 600; }
  .product-table td { padding: 12px 14px; border-bottom: 1px solid #f8f8ff; vertical-align: middle; }
  .inactive-row td { opacity: 0.5; }
  .product-cell { display: flex; align-items: center; gap: 12px; }
  .product-thumb { width: 44px; height: 44px; border-radius: 10px; object-fit: cover; }
  .product-thumb-empty { width: 44px; height: 44px; border-radius: 10px; background: #f0f4ff; display: flex; align-items: center; justify-content: center; font-size: 22px; }
  .product-cell-name { font-weight: 600; font-size: 14px; }
  .product-cell-desc { font-size: 12px; color: #888; margin-top: 2px; }
  .price-cell { font-weight: 700; color: #006d77; }
  .stock-pill { padding: 4px 10px; border-radius: 20px; font-size: 12px; font-weight: 600; }
  .stock-pill.in { background: #d1fae5; color: #065f46; }
  .stock-pill.low { background: #fef3c7; color: #92400e; }
  .stock-pill.out { background: #fee2e2; color: #991b1b; }
  .toggle-btn { border: none; background: none; cursor: pointer; font-size: 13px; font-family: inherit; padding: 6px 10px; border-radius: 8px; font-weight: 600; }
  .toggle-btn.active { background: #d1fae5; color: #065f46; }
  .edit-btn { background: #f0f4ff; border: none; padding: 6px 12px; border-radius: 8px; cursor: pointer; font-size: 13px; font-family: inherit; font-weight: 600; }

  /* Orders */
  .order-list { display: flex; flex-direction: column; gap: 12px; }
  .order-card { background: #f8f9ff; border-radius: 16px; padding: 16px; border: 1px solid #eeeeff; }
  .order-card-top { display: flex; justify-content: space-between; align-items: flex-start; margin-bottom: 10px; }
  .order-id { font-weight: 700; font-size: 15px; }
  .order-phone, .order-date { font-size: 12px; color: #888; margin-top: 3px; }
  .order-right { text-align: right; display: flex; flex-direction: column; gap: 6px; align-items: flex-end; }
  .order-total { font-weight: 800; font-size: 16px; color: #006d77; }
  .status-pill { padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
  .status-pill.paid { background: #d1fae5; color: #065f46; }
  .status-pill.pending { background: #fef3c7; color: #92400e; }
  .status-pill.cancelled { background: #fee2e2; color: #991b1b; }
  .payment-pill { background: #e0e8ff; color: #3730a3; padding: 3px 8px; border-radius: 20px; font-size: 11px; font-weight: 600; }
  .order-items { display: flex; flex-wrap: wrap; gap: 6px; }
  .order-item-chip { background: white; border: 1px solid #e0e0f0; border-radius: 20px; padding: 3px 10px; font-size: 12px; color: #555; }

  /* Link tab */
  .link-desc { color: #666; font-size: 14px; margin-bottom: 20px; line-height: 1.6; }
  .link-box { display: flex; align-items: center; gap: 12px; background: #f0f4ff; border-radius: 14px; padding: 16px; border: 2px solid #e0e8ff; margin-bottom: 16px; }
  .link-url { flex: 1; font-size: 14px; color: #006d77; font-weight: 600; word-break: break-all; }
  .copy-btn { background: #006d77; color: white; border: none; padding: 10px 18px; border-radius: 10px; cursor: pointer; font-size: 13px; font-weight: 700; font-family: inherit; white-space: nowrap; }
  .link-actions { margin-bottom: 24px; }
  .share-tips { background: #fffbeb; border: 1px solid #fde68a; border-radius: 16px; padding: 20px; }
  .share-tips h3 { font-size: 16px; font-weight: 700; margin-bottom: 12px; color: #92400e; }
  .share-tips ul { list-style: none; display: flex; flex-direction: column; gap: 10px; }
  .share-tips li { font-size: 14px; color: #78350f; line-height: 1.5; }

  /* Buttons */
  .primary-btn { background: #006d77; color: white; border: none; border-radius: 12px; padding: 11px 20px; font-size: 14px; font-weight: 700; cursor: pointer; font-family: inherit; transition: background 0.2s; text-decoration: none; display: inline-block; }
  .primary-btn:hover { background: #004d55; }
  .secondary-btn { background: #f0f0f8; color: #444; border: none; border-radius: 12px; padding: 11px 20px; font-size: 14px; font-weight: 600; cursor: pointer; font-family: inherit; }
  .secondary-btn:hover { background: #e0e0f0; }

  /* Modal */
  .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 200; display: flex; align-items: center; justify-content: center; padding: 20px; backdrop-filter: blur(4px); }
  .modal { background: white; border-radius: 24px; width: 100%; max-width: 500px; box-shadow: 0 20px 60px rgba(0,0,0,0.2); }
  .modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px; border-bottom: 1px solid #f0f0f8; font-size: 17px; font-weight: 700; }
  .modal-close { background: #f0f0f8; border: none; width: 32px; height: 32px; border-radius: 50%; cursor: pointer; font-size: 16px; }
  .modal-body { padding: 24px; display: flex; flex-direction: column; gap: 12px; max-height: 60vh; overflow-y: auto; }
  .modal-footer { padding: 16px 24px; border-top: 1px solid #f0f0f8; display: flex; gap: 10px; justify-content: flex-end; }
  .form-label { font-size: 13px; font-weight: 600; color: #555; }
  .form-input { padding: 11px 14px; border: 1.5px solid #e0e0f0; border-radius: 12px; font-size: 14px; font-family: inherit; outline: none; width: 100%; resize: none; transition: border 0.2s; }
  .form-input:focus { border-color: #006d77; }
  .form-row { display: flex; gap: 12px; }
  .form-col { flex: 1; display: flex; flex-direction: column; gap: 6px; }
  .form-error { color: #dc2626; font-size: 13px; background: #fef2f2; padding: 10px; border-radius: 10px; }
  .img-preview { width: 100%; max-height: 150px; object-fit: cover; border-radius: 12px; border: 1px solid #e0e0f0; }

  @media (max-width: 768px) {
    .dash-root { flex-direction: column; }
    .sidebar { width: 100%; height: auto; flex-direction: row; flex-wrap: wrap; padding: 16px; position: static; }
    .sidebar-nav { flex-direction: row; }
    .stats-row { grid-template-columns: repeat(2, 1fr); }
    .dash-main { padding: 16px; }
  }
`;
