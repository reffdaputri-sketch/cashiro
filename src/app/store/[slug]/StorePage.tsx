'use client';

import { useState, useEffect, useRef } from 'react';
import { CartProvider, useCart } from '@/lib/cart-context';
import CartDrawer from './CartDrawer';

interface Product {
  id: number;
  name: string;
  description: string;
  price: number;
  stock: number;
  weight: number;
  image_url: string;
  category: string;
}

interface SellerData {
  seller: {
    slug: string;
    store_name: string;
    owner_name: string;
    phone: string;
    address: string;
    city_id: number | null;
    bank_name: string;
    bank_account: string;
    bank_account_name: string;
    qris_payload: string | null;
    banners: string[];
    is_local_courier_active: boolean;
    local_courier_fee: number;
  };
  products: Product[];
}

function formatRupiah(num: number) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(num);
}

function BannerSlider({ banners }: { banners: string[] }) {
  const [current, setCurrent] = useState(0);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  useEffect(() => {
    if (banners.length <= 1) return;
    timerRef.current = setInterval(() => {
      setCurrent(prev => (prev + 1) % banners.length);
    }, 3500);
    return () => { if (timerRef.current) clearInterval(timerRef.current); };
  }, [banners.length]);

  if (banners.length === 0) return null;

  return (
    <div className="banner-slider">
      <div className="banner-track" style={{ transform: `translateX(-${current * 100}%)` }}>
        {banners.map((url, i) => (
          <div key={i} className="banner-slide">
            <img src={url} alt={`Banner ${i + 1}`} className="banner-img" />
          </div>
        ))}
      </div>
      {banners.length > 1 && (
        <div className="banner-dots">
          {banners.map((_, i) => (
            <button
              key={i}
              className={`banner-dot ${i === current ? 'active' : ''}`}
              onClick={() => setCurrent(i)}
            />
          ))}
        </div>
      )}
    </div>
  );
}

function ProductCard({ product }: { product: Product }) {
  const { addItem, items } = useCart();
  const cartItem = items.find(i => i.product_id === product.id);
  const inCart = cartItem?.qty || 0;
  const outOfStock = product.stock <= 0;

  return (
    <div className="product-card">
      <div className="product-image-wrap">
        {product.image_url ? (
          <img src={product.image_url} alt={product.name} className="product-image" />
        ) : (
          <div className="product-image-placeholder">
            <span>🛍️</span>
          </div>
        )}
        <span className={`stock-badge ${outOfStock ? 'out' : product.stock <= 5 ? 'low' : 'in'}`}>
          {outOfStock ? 'Habis' : `Sisa ${product.stock}`}
        </span>
      </div>
      <div className="product-info">
        <h3 className="product-name">{product.name}</h3>
        {product.category && <p className="product-category">{product.category}</p>}
        {product.description && <p className="product-desc">{product.description}</p>}
        <div className="product-footer">
          <span className="product-price">{formatRupiah(product.price)}</span>
          <button
            disabled={outOfStock}
            onClick={() => addItem({ product_id: product.id, name: product.name, price: product.price, stock: product.stock, weight: product.weight, image_url: product.image_url })}
            className={`add-btn ${outOfStock ? 'disabled' : inCart > 0 ? 'in-cart' : ''}`}
          >
            {outOfStock ? 'Habis' : inCart > 0 ? `+${inCart} 🛒` : '+ Keranjang'}
          </button>
        </div>
      </div>
    </div>
  );
}

function StoreContent({ data, slug }: { data: SellerData; slug: string }) {
  const { count, total } = useCart();
  const [cartOpen, setCartOpen] = useState(false);
  const [search, setSearch] = useState('');
  const [activeCategory, setActiveCategory] = useState('Semua');

  // Build unique category list from products
  const categories = ['Semua', ...Array.from(new Set(
    data.products.map(p => p.category || p.description).filter(c => c && c.trim() !== '')
  ))];

  const filtered = data.products.filter(p => {
    const matchSearch = p.name.toLowerCase().includes(search.toLowerCase());
    const prodCat = p.category || p.description;
    const matchCat = activeCategory === 'Semua' || prodCat === activeCategory;
    return matchSearch && matchCat;
  });

  return (
    <div className="store-root">
      {/* Hero / Header */}
      <header className="store-header">
        <div className="store-header-inner">
          <div className="store-logo-wrap">
            <div className="store-logo">{data.seller.store_name.charAt(0).toUpperCase()}</div>
            <div>
              <h1 className="store-name">{data.seller.store_name}</h1>
              <p className="store-meta">
                {data.seller.owner_name && <span>👤 {data.seller.owner_name}</span>}
                {data.seller.address && <span> · 📍 {data.seller.address}</span>}
              </p>
            </div>
          </div>
          <button className="cart-fab" onClick={() => setCartOpen(true)}>
            🛒
            {count > 0 && <span className="cart-badge">{count}</span>}
          </button>
        </div>
      </header>

      {/* Banner Slider */}
      <BannerSlider banners={data.seller.banners || []} />

      {/* Search */}
      <div className="search-wrap">
        <input
          type="text"
          placeholder="🔍 Cari produk..."
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="search-input"
        />
      </div>

      {/* Category Chips */}
      {categories.length > 1 && (
        <div className="category-wrap">
          {categories.map(cat => (
            <button
              key={cat}
              className={`cat-chip ${activeCategory === cat ? 'active' : ''}`}
              onClick={() => setActiveCategory(cat)}
            >
              {cat}
            </button>
          ))}
        </div>
      )}

      {/* Products Grid */}
      <main className="products-section">
        {filtered.length === 0 ? (
          <div className="empty-state">
            <span>📦</span>
            <p>{search ? 'Produk tidak ditemukan' : 'Belum ada produk tersedia'}</p>
          </div>
        ) : (
          <div className="products-grid">
            {filtered.map(product => (
              <ProductCard key={product.id} product={product} />
            ))}
          </div>
        )}
      </main>

      {/* Sticky Cart Bar */}
      {count > 0 && (
        <div className="sticky-cart" onClick={() => setCartOpen(true)}>
          <span>🛒 {count} item</span>
          <span className="sticky-cart-total">{formatRupiah(total)}</span>
          <span className="sticky-cart-btn">Lihat Keranjang →</span>
        </div>
      )}

      {/* Cart Drawer */}
      {cartOpen && <CartDrawer slug={slug} onClose={() => setCartOpen(false)} storeCityId={data.seller.city_id} bankName={data.seller.bank_name} bankAccount={data.seller.bank_account} bankAccountName={data.seller.bank_account_name} qrisPayload={data.seller.qris_payload} isLocalCourierActive={data.seller.is_local_courier_active} localCourierFee={data.seller.local_courier_fee} />}

      {/* Mobile Bottom Navigation */}
      <div className="mobile-bottom-nav">
        <button className="bottom-nav-item" onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}>
          <span className="bottom-nav-icon">🏠</span>
          <span className="bottom-nav-label">Home</span>
        </button>
        <button className="bottom-nav-item" onClick={() => setCartOpen(true)}>
          <div className="bottom-nav-icon-wrap">
            <span className="bottom-nav-icon">🛒</span>
            {count > 0 && <span className="bottom-nav-badge">{count}</span>}
          </div>
          <span className="bottom-nav-label">Keranjang</span>
        </button>
        <a href={`https://wa.me/${data.seller.phone.replace(/^0/, '62')}`} target="_blank" rel="noreferrer" className="bottom-nav-item">
          <span className="bottom-nav-icon">💬</span>
          <span className="bottom-nav-label">WA Seller</span>
        </a>
      </div>

      <style>{`
        * { box-sizing: border-box; margin: 0; padding: 0; }
        @import url('https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap');
        .store-root { font-family: 'Outfit', sans-serif; min-height: 100vh; background: #f8f9ff; color: #1a1a2e; }

        /* Header */
        .store-header { background: linear-gradient(135deg, #006d77 0%, #004d55 100%); color: white; padding: 0; box-shadow: 0 4px 20px rgba(0,109,119,0.3); }
        .store-header-inner { max-width: 1200px; margin: 0 auto; padding: 20px 24px; display: flex; align-items: center; justify-content: space-between; }
        .store-logo-wrap { display: flex; align-items: center; gap: 16px; }
        .store-logo { width: 56px; height: 56px; border-radius: 16px; background: rgba(255,255,255,0.2); display: flex; align-items: center; justify-content: center; font-size: 28px; font-weight: 800; backdrop-filter: blur(8px); border: 2px solid rgba(255,255,255,0.3); }
        .store-name { font-size: 22px; font-weight: 700; }
        .store-meta { font-size: 13px; opacity: 0.8; margin-top: 2px; }
        .cart-fab { position: relative; background: rgba(255,255,255,0.15); border: 2px solid rgba(255,255,255,0.3); color: white; border-radius: 16px; padding: 10px 16px; font-size: 20px; cursor: pointer; backdrop-filter: blur(8px); transition: all 0.2s; }
        .cart-fab:hover { background: rgba(255,255,255,0.25); transform: scale(1.05); }
        .cart-badge { position: absolute; top: -6px; right: -6px; background: #ffb703; color: #1a1a2e; border-radius: 50%; width: 20px; height: 20px; font-size: 11px; font-weight: 700; display: flex; align-items: center; justify-content: center; }

        /* Banner Slider */
        .banner-slider { position: relative; overflow: hidden; max-width: 1200px; margin: 20px auto 0; border-radius: 20px; aspect-ratio: 16/5; padding: 0 24px; box-sizing: border-box; background: transparent; }
        .banner-track { display: flex; width: 100%; height: 100%; transition: transform 0.5s ease; }
        .banner-slide { min-width: 100%; height: 100%; }
        .banner-img { width: 100%; height: 100%; object-fit: cover; }
        .banner-dots { position: absolute; bottom: 10px; left: 50%; transform: translateX(-50%); display: flex; gap: 6px; }
        .banner-dot { width: 8px; height: 8px; border-radius: 50%; background: rgba(255,255,255,0.5); border: none; cursor: pointer; transition: all 0.2s; padding: 0; }
        .banner-dot.active { background: white; width: 22px; border-radius: 4px; }

        /* Category Chips */
        .category-wrap { max-width: 1200px; margin: 16px auto 0; padding: 0 24px; display: flex; gap: 8px; overflow-x: auto; scrollbar-width: none; }
        .category-wrap::-webkit-scrollbar { display: none; }
        .cat-chip { padding: 8px 18px; border-radius: 20px; border: 2px solid #e8e8f0; background: white; font-size: 13px; font-weight: 600; cursor: pointer; transition: all 0.2s; white-space: nowrap; font-family: inherit; color: #666; }
        .cat-chip:hover { border-color: #006d77; color: #006d77; }
        .cat-chip.active { background: #006d77; color: white; border-color: #006d77; }

        /* Search */
        .search-wrap { max-width: 1200px; margin: 0 auto; padding: 20px 24px 0; }
        .search-input { width: 100%; padding: 14px 20px; border-radius: 16px; border: 2px solid #e8e8f0; font-size: 15px; font-family: inherit; outline: none; transition: border 0.2s, box-shadow 0.2s; background: white; }
        .search-input:focus { border-color: #006d77; box-shadow: 0 0 0 4px rgba(0,109,119,0.1); }

        /* Products */
        .products-section { max-width: 1200px; margin: 0 auto; padding: 20px 24px 120px; }
        .products-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 18px; }

        /* Product Card */
        .product-card { background: white; border-radius: 20px; overflow: hidden; box-shadow: 0 2px 12px rgba(0,0,0,0.06); transition: transform 0.2s, box-shadow 0.2s; border: 1px solid #f0f0f8; }
        .product-card:hover { transform: translateY(-4px); box-shadow: 0 8px 28px rgba(0,109,119,0.15); }
        .product-image-wrap { position: relative; aspect-ratio: 1; overflow: hidden; background: #f0f4ff; }
        .product-image { width: 100%; height: 100%; object-fit: cover; }
        .product-image-placeholder { width: 100%; height: 100%; display: flex; align-items: center; justify-content: center; font-size: 48px; }
        .stock-badge { position: absolute; top: 10px; right: 10px; padding: 4px 10px; border-radius: 20px; font-size: 11px; font-weight: 600; }
        .stock-badge.in { background: #d1fae5; color: #065f46; }
        .stock-badge.low { background: #fef3c7; color: #92400e; }
        .stock-badge.out { background: #fee2e2; color: #991b1b; }
        .product-info { padding: 14px; }
        .product-name { font-size: 14px; font-weight: 600; margin-bottom: 4px; line-height: 1.3; }
        .product-category { font-size: 11px; color: #888; margin-bottom: 6px; text-transform: capitalize; }
        .product-desc { font-size: 12px; color: #666; margin-bottom: 10px; line-height: 1.4; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
        .product-footer { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 8px; }
        .product-price { font-size: 15px; font-weight: 700; color: #006d77; }
        .add-btn { padding: 7px 14px; border-radius: 12px; border: none; font-size: 12px; font-weight: 600; cursor: pointer; transition: all 0.2s; font-family: inherit; background: #006d77; color: white; }
        .add-btn:hover:not(.disabled) { background: #004d55; transform: scale(1.05); }
        .add-btn.in-cart { background: #ffb703; color: #1a1a2e; }
        .add-btn.disabled { background: #e0e0e0; color: #999; cursor: not-allowed; }

        /* Sticky cart */
        .sticky-cart { position: fixed; bottom: 24px; left: 50%; transform: translateX(-50%); background: #006d77; color: white; padding: 16px 24px; border-radius: 20px; display: flex; align-items: center; gap: 16px; cursor: pointer; box-shadow: 0 8px 32px rgba(0,109,119,0.4); z-index: 100; font-family: inherit; min-width: 320px; transition: transform 0.2s; }
        .sticky-cart:hover { transform: translateX(-50%) translateY(-2px); }
        .sticky-cart-total { font-weight: 700; flex: 1; text-align: center; }
        .sticky-cart-btn { background: #ffb703; color: #1a1a2e; padding: 6px 14px; border-radius: 12px; font-size: 13px; font-weight: 700; white-space: nowrap; }

        /* Empty */
        .empty-state { text-align: center; padding: 80px 20px; color: #999; }
        .empty-state span { font-size: 60px; display: block; margin-bottom: 16px; }
        .empty-state p { font-size: 16px; }

        /* Mobile Bottom Nav (hidden on desktop) */
        .mobile-bottom-nav { display: none; }

        @media (max-width: 600px) {
          .products-grid { grid-template-columns: repeat(2, 1fr); gap: 12px; }
          .store-header-inner { padding: 16px; }
          .store-name { font-size: 18px; }
          .sticky-cart { min-width: unset; width: calc(100% - 32px); bottom: 84px; }
          .products-section { padding-bottom: 160px; }

          /* Bottom Nav */
          .mobile-bottom-nav {
            display: flex;
            position: fixed;
            bottom: 0;
            left: 0;
            right: 0;
            background: white;
            box-shadow: 0 -4px 20px rgba(0,0,0,0.06);
            z-index: 1000;
            padding-bottom: env(safe-area-inset-bottom);
            border-top: 1px solid #f0f0f8;
          }
          .bottom-nav-item {
            flex: 1;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            padding: 12px 0;
            background: none;
            border: none;
            color: #666;
            text-decoration: none;
            cursor: pointer;
            transition: color 0.2s;
          }
          .bottom-nav-item:hover, .bottom-nav-item:active { color: #006d77; }
          .bottom-nav-icon-wrap { position: relative; display: flex; align-items: center; justify-content: center; }
          .bottom-nav-icon { font-size: 22px; margin-bottom: 4px; display: block; }
          .bottom-nav-label { font-size: 11px; font-weight: 600; font-family: inherit; }
          .bottom-nav-badge {
            position: absolute;
            top: -4px;
            right: -8px;
            background: #ef4444;
            color: white;
            font-size: 10px;
            font-weight: 700;
            min-width: 16px;
            height: 16px;
            padding: 0 4px;
            border-radius: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
          }
        }
      `}</style>
    </div>
  );
}

export default function StorePage({ data, slug }: { data: SellerData; slug: string }) {
  return (
    <CartProvider>
      <StoreContent data={data} slug={slug} />
    </CartProvider>
  );
}
