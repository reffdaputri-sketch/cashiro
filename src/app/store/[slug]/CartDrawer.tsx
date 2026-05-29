'use client';

import { useState, useEffect } from 'react';
import { useCart } from '@/lib/cart-context';

interface CartDrawerProps {
  slug: string;
  onClose: () => void;
  storeCityId: number | null;
}

function formatRupiah(num: number) {
  return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(num);
}

export default function CartDrawer({ slug, onClose, storeCityId }: CartDrawerProps) {
  const { items, removeItem, updateQty, clearCart, total, count } = useCart();
  const [step, setStep] = useState<'cart' | 'checkout' | 'success' | 'qris'>('cart');
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [address, setAddress] = useState('');
  const [notes, setNotes] = useState('');
  const [paymentMethod, setPaymentMethod] = useState<'manual' | 'qris'>('manual');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [qrisUrl, setQrisUrl] = useState('');
  const [orderId, setOrderId] = useState<number | null>(null);
  const [waLink, setWaLink] = useState('');

  // Shipping State
  const [provinces, setProvinces] = useState<any[]>([]);
  const [cities, setCities] = useState<any[]>([]);
  const [districts, setDistricts] = useState<any[]>([]);
  const [selectedProvinceId, setSelectedProvinceId] = useState('');
  const [selectedCityId, setSelectedCityId] = useState('');
  const [selectedDistrictId, setSelectedDistrictId] = useState('');
  const [couriers, setCouriers] = useState<any[]>([]);
  const [selectedCourier, setSelectedCourier] = useState('');
  const [shippingCost, setShippingCost] = useState(0);
  const [courierName, setCourierName] = useState('');
  const [loadingLocation, setLoadingLocation] = useState(false);
  const [loadingShipping, setLoadingShipping] = useState(false);

  const totalWeight = items.reduce((sum, item) => sum + (item.weight || 0) * item.qty, 0);

  console.log('CartDrawer values:', { storeCityId, totalWeight, selectedDistrictId, step });

  useEffect(() => {
    if (step === 'checkout') {
      fetchProvinces();
    }
  }, [step]);

  const fetchProvinces = async () => {
    setLoadingLocation(true);
    try {
      const res = await fetch('/api/rajaongkir/location?type=province');
      const data = await res.json();
      if (res.ok) setProvinces(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingLocation(false);
    }
  };

  const fetchCities = async (provId: string) => {
    setLoadingLocation(true);
    try {
      const res = await fetch(`/api/rajaongkir/location?type=city&province=${provId}`);
      const data = await res.json();
      if (res.ok) setCities(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingLocation(false);
    }
  };

  const fetchDistricts = async (cityId: string) => {
    setLoadingLocation(true);
    try {
      const res = await fetch(`/api/rajaongkir/location?type=district&city=${cityId}`);
      const data = await res.json();
      if (res.ok) setDistricts(data);
    } catch (e) {
      console.error(e);
    } finally {
      setLoadingLocation(false);
    }
  };

  const calculateShipping = async (districtId: string, courierCode: string) => {
    if (!storeCityId || !districtId || !courierCode || totalWeight <= 0) return;
    setLoadingShipping(true);
    setError('');
    try {
      const res = await fetch('/api/rajaongkir/cost', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          origin: storeCityId,
          destination: districtId,
          weight: totalWeight < 1000 ? 1000 : totalWeight, // minimum 1kg
          courier: courierCode,
        }),
      });
      const data = await res.json();
      if (res.ok && data.length > 0 && data[0].costs.length > 0) {
        setCouriers(data[0].costs);
      } else {
        setError('Kurir tidak tersedia untuk rute ini.');
        setCouriers([]);
        setShippingCost(0);
        setCourierName('');
      }
    } catch (e: any) {
      setError('Gagal menghitung ongkos kirim');
    } finally {
      setLoadingShipping(false);
    }
  };

  const handleOrder = async () => {
    if (!name.trim()) {
      setError('Nama Pemesan wajib diisi.');
      return;
    }
    if (!phone.trim()) {
      setError('No. WhatsApp wajib diisi.');
      return;
    }
    if (!selectedProvinceId) {
      setError('Silakan pilih Provinsi.');
      return;
    }
    if (!selectedCityId) {
      setError('Silakan pilih Kota / Kabupaten.');
      return;
    }
    if (!selectedDistrictId) {
      setError('Silakan pilih Kecamatan.');
      return;
    }
    if (!address.trim()) {
      setError('Alamat Lengkap wajib diisi.');
      return;
    }
    if (storeCityId && totalWeight > 0 && shippingCost === 0) {
      setError('Silakan pilih kurir dan layanan pengiriman.');
      return;
    }

    setLoading(true);
    setError('');
    try {
      const prov = provinces.find(p => p.province_id === selectedProvinceId)?.province || '';
      const city = cities.find(c => c.city_id === selectedCityId)?.city_name || '';
      const cityType = cities.find(c => c.city_id === selectedCityId)?.type || '';
      const dist = districts.find(d => d.district_id === selectedDistrictId)?.district_name || '';
      
      const fullAddress = `${address}, Kec. ${dist}, ${cityType} ${city}, Prov. ${prov}`;

      const payload = {
        customer_name: name,
        customer_phone: phone,
        customer_address: fullAddress,
        notes,
        payment_method: paymentMethod,
        shipping_cost: shippingCost,
        courier_name: courierName,
        items: items.map(i => ({ product_id: i.product_id, qty: i.qty })),
      };

      const res = await fetch(`/api/sellers/${slug}/orders`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.error || 'Gagal membuat pesanan');
        return;
      }

      setOrderId(data.order_id);
      clearCart();

      if (paymentMethod === 'qris' && data.payment_url) {
        setQrisUrl(data.payment_url);
        setStep('qris');
      } else {
        if (data.seller_phone) {
          const formattedPhone = data.seller_phone.startsWith('0') 
            ? '62' + data.seller_phone.substring(1) 
            : data.seller_phone.replace(/[^0-9]/g, '');
          
          const waMessage = `Halo Kak, saya ada pesanan baru dari Toko Online:
Nama: ${name || 'Anonim'}
No. HP: ${phone || '-'}
Alamat: ${fullAddress || '-'}

*Pesanan:*
${items.map(i => `- ${i.name} (${i.qty}x)`).join('\n')}

Catatan: ${notes || '-'}
Ongkos Kirim: ${shippingCost > 0 ? `${formatRupiah(shippingCost)} (${courierName})` : '-'}
*Grand Total: ${formatRupiah(total + shippingCost)}*

Tolong segera diproses ya, terima kasih!`;
          
          setWaLink(`https://wa.me/${formattedPhone}?text=${encodeURIComponent(waMessage)}`);
        }
        setStep('success');
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="drawer-overlay" onClick={e => { if ((e.target as HTMLElement).classList.contains('drawer-overlay')) onClose(); }}>
      <div className="drawer">
        {/* Header */}
        <div className="drawer-header">
          <span className="drawer-title">
            {step === 'cart' ? `🛒 Keranjang (${count})` : step === 'checkout' ? '📋 Checkout' : step === 'qris' ? '📱 Pembayaran QRIS' : '✅ Pesanan Berhasil'}
          </span>
          <button className="close-btn" onClick={onClose}>✕</button>
        </div>

        {/* CART */}
        {step === 'cart' && (
          <div className="drawer-body">
            {items.length === 0 ? (
              <div className="empty-cart">
                <span>🛒</span>
                <p>Keranjang kosong</p>
              </div>
            ) : (
              <div className="cart-items">
                {items.map(item => (
                  <div key={item.product_id} className="cart-item">
                    <div className="cart-item-info">
                      <p className="cart-item-name">{item.name}</p>
                      <p className="cart-item-price">{formatRupiah(item.price)}</p>
                    </div>
                    <div className="qty-control">
                      <button onClick={() => updateQty(item.product_id, item.qty - 1)}>−</button>
                      <span>{item.qty}</span>
                      <button onClick={() => updateQty(item.product_id, item.qty + 1)} disabled={item.qty >= item.stock}>+</button>
                    </div>
                    <button className="remove-btn" onClick={() => removeItem(item.product_id)}>🗑️</button>
                  </div>
                ))}
              </div>
            )}
            <div className="drawer-total">
              <span>Total</span>
              <span className="total-amount">{formatRupiah(total)}</span>
            </div>
            <button className="primary-btn" disabled={items.length === 0} onClick={() => setStep('checkout')}>
              Lanjut ke Checkout →
            </button>
          </div>
        )}

        {/* CHECKOUT */}
        {step === 'checkout' && (
          <div className="drawer-body">
            <label className="form-label">Nama Pemesan</label>
            <input className="form-input" placeholder="Masukkan nama" value={name} onChange={e => setName(e.target.value)} />

            <label className="form-label">No. WhatsApp</label>
            <input className="form-input" placeholder="08xxxxxxxxxx" value={phone} onChange={e => setPhone(e.target.value)} type="tel" />

            <label className="form-label">Provinsi</label>
            <select
              className="form-input"
              value={selectedProvinceId}
              onChange={(e) => {
                setSelectedProvinceId(e.target.value);
                setSelectedCityId('');
                setCities([]);
                setSelectedDistrictId('');
                setDistricts([]);
                setSelectedCourier('');
                setCouriers([]);
                setShippingCost(0);
                setCourierName('');
                if (e.target.value) fetchCities(e.target.value);
              }}
              disabled={loadingLocation}
            >
              <option value="">-- Pilih Provinsi --</option>
              {provinces.map((p) => (
                <option key={p.province_id} value={p.province_id}>{p.province}</option>
              ))}
            </select>

            <label className="form-label">Kota / Kabupaten</label>
            <select
              className="form-input"
              value={selectedCityId}
              onChange={(e) => {
                setSelectedCityId(e.target.value);
                setSelectedDistrictId('');
                setDistricts([]);
                setSelectedCourier('');
                setCouriers([]);
                setShippingCost(0);
                setCourierName('');
                if (e.target.value) fetchDistricts(e.target.value);
              }}
              disabled={!selectedProvinceId || loadingLocation}
            >
              <option value="">-- Pilih Kota/Kab --</option>
              {cities.map((c) => (
                <option key={c.city_id} value={c.city_id}>{c.type} {c.city_name}</option>
              ))}
            </select>

            <label className="form-label">Kecamatan</label>
            <select
              className="form-input"
              value={selectedDistrictId}
              onChange={(e) => {
                setSelectedDistrictId(e.target.value);
                setSelectedCourier('');
                setCouriers([]);
                setShippingCost(0);
                setCourierName('');
              }}
              disabled={!selectedCityId || loadingLocation}
            >
              <option value="">-- Pilih Kecamatan --</option>
              {districts.map((d) => (
                <option key={d.district_id} value={d.district_id}>{d.district_name}</option>
              ))}
            </select>

            <label className="form-label">Alamat Lengkap (Jalan, RT/RW, No. Rumah)</label>
            <textarea className="form-input" placeholder="Alamat lengkap..." value={address} onChange={e => setAddress(e.target.value)} rows={2} />

            {/* RajaOngkir Shipping Cost */}
            {storeCityId && totalWeight > 0 && selectedDistrictId && (
              <div className="shipping-box">
                <h4 className="shipping-title">Pengiriman (Total Berat: {totalWeight}g)</h4>
                
                <div className="shipping-grid">
                  <select
                    className="form-input"
                    value={selectedCourier}
                    onChange={(e) => {
                      setSelectedCourier(e.target.value);
                      if (e.target.value) calculateShipping(selectedDistrictId, e.target.value);
                      else {
                        setCouriers([]);
                        setShippingCost(0);
                        setCourierName('');
                      }
                    }}
                  >
                    <option value="">-- Pilih Kurir --</option>
                    <option value="jne">JNE</option>
                    <option value="jnt">J&T Express</option>
                    <option value="sicepat">SiCepat</option>
                    <option value="anteraja">AnterAja</option>
                    <option value="pos">POS Indonesia</option>
                    <option value="tiki">TIKI</option>
                    <option value="wahana">Wahana</option>
                  </select>
                </div>

                {loadingShipping && <p className="loading-text">Sedang menghitung ongkos kirim...</p>}

                {couriers.length > 0 && (
                  <div className="courier-list">
                    {couriers.map((c, idx) => {
                      const isSelected = courierName === `${selectedCourier.toUpperCase()} ${c.service}`;
                      return (
                        <label key={idx} className={`courier-option ${isSelected ? 'active' : ''}`}>
                          <input
                            type="radio"
                            name="shipping_service"
                            checked={isSelected}
                            onChange={() => {
                              setShippingCost(c.cost[0].value);
                              setCourierName(`${selectedCourier.toUpperCase()} ${c.service}`);
                            }}
                          />
                          <div className="courier-info">
                            <span className="courier-service">{selectedCourier.toUpperCase()} - {c.service}</span>
                            <span className="courier-etd">Estimasi: {c.cost[0].etd} hari</span>
                          </div>
                          <span className="courier-price">{formatRupiah(c.cost[0].value)}</span>
                        </label>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            <label className="form-label">Catatan (Opsional)</label>
            <textarea className="form-input" placeholder="Catatan pesanan..." value={notes} onChange={e => setNotes(e.target.value)} rows={2} />

            <label className="form-label">Metode Pembayaran</label>
            <div className="payment-options">
              <button
                className={`payment-option ${paymentMethod === 'manual' ? 'active' : ''}`}
                onClick={() => setPaymentMethod('manual')}
              >
                💵 Bayar Manual / COD
              </button>
              <button
                className={`payment-option ${paymentMethod === 'qris' ? 'active' : ''}`}
                onClick={() => setPaymentMethod('qris')}
              >
                📱 QRIS Otomatis
              </button>
            </div>

            <div className="order-summary-box">
              {items.map(i => (
                <div key={i.product_id} className="order-summary-row">
                  <span>{i.name} ×{i.qty}</span>
                  <span>{formatRupiah(i.price * i.qty)}</span>
                </div>
              ))}
              {shippingCost > 0 && (
                <div className="order-summary-row">
                  <span>Ongkos Kirim ({courierName})</span>
                  <span>{formatRupiah(shippingCost)}</span>
                </div>
              )}
              <div className="order-summary-row total-row">
                <span>Total</span>
                <span>{formatRupiah(total + shippingCost)}</span>
              </div>
            </div>

            {error && <p className="error-text">⚠️ {error}</p>}

            <div className="btn-row">
              <button className="secondary-btn" onClick={() => setStep('cart')}>← Kembali</button>
              <button className="primary-btn" onClick={handleOrder} disabled={loading || (totalWeight > 0 && storeCityId !== null && shippingCost === 0 && selectedDistrictId !== '')}>
                {loading ? 'Memproses...' : paymentMethod === 'qris' ? 'Buat QRIS 📱' : 'Pesan Sekarang ✓'}
              </button>
            </div>
          </div>
        )}

        {/* QRIS */}
        {step === 'qris' && (
          <div className="drawer-body text-center">
            <div className="qris-icon">📱</div>
            <h3>Scan QRIS untuk Bayar</h3>
            <p className="qris-desc">Scan QR Code di bawah ini menggunakan aplikasi dompet digital</p>
            <a href={qrisUrl} target="_blank" rel="noopener noreferrer" className="qris-btn">
              🔗 Buka Halaman Pembayaran
            </a>
            <p className="order-id-text">ID Pesanan: #{orderId}</p>
            <p className="qris-note">Setelah pembayaran berhasil, pesanan akan diproses otomatis oleh penjual.</p>
            <button className="secondary-btn" onClick={onClose}>Tutup</button>
          </div>
        )}

        {/* SUCCESS */}
        {step === 'success' && (
          <div className="drawer-body text-center">
            <div className="success-icon">✅</div>
            <h3>Pesanan Berhasil!</h3>
            <p className="success-desc">Pesanan Anda sudah diterima. Penjual akan segera menghubungi Anda untuk konfirmasi.</p>
            <p className="order-id-text">ID Pesanan: #{orderId}</p>
            
            {waLink && (
              <a href={waLink} target="_blank" rel="noopener noreferrer" className="primary-btn" style={{ textDecoration: 'none', display: 'block', margin: '20px 0' }}>
                💬 Lanjutkan ke WhatsApp
              </a>
            )}
            <button className={waLink ? "secondary-btn" : "primary-btn"} onClick={onClose} style={{ width: '100%' }}>
              Kembali ke Toko
            </button>
          </div>
        )}

        <style>{`
          .drawer-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); z-index: 200; display: flex; justify-content: flex-end; backdrop-filter: blur(4px); }
          .drawer { background: white; width: 420px; max-width: 100vw; height: 100%; display: flex; flex-direction: column; font-family: 'Outfit', sans-serif; box-shadow: -8px 0 40px rgba(0,0,0,0.15); }
          .drawer-header { padding: 20px 24px; border-bottom: 1px solid #f0f0f8; display: flex; align-items: center; justify-content: space-between; background: #006d77; color: white; }
          .drawer-title { font-size: 17px; font-weight: 700; }
          .close-btn { background: rgba(255,255,255,0.2); border: none; color: white; width: 32px; height: 32px; border-radius: 50%; cursor: pointer; font-size: 16px; display: flex; align-items: center; justify-content: center; transition: background 0.2s; }
          .close-btn:hover { background: rgba(255,255,255,0.3); }
          .drawer-body { flex: 1; overflow-y: auto; padding: 20px 24px; display: flex; flex-direction: column; gap: 12px; }

          .cart-items { display: flex; flex-direction: column; gap: 12px; }
          .cart-item { display: flex; align-items: center; gap: 12px; padding: 12px; background: #f8f9ff; border-radius: 14px; }
          .cart-item-info { flex: 1; }
          .cart-item-name { font-size: 14px; font-weight: 600; }
          .cart-item-price { font-size: 13px; color: #006d77; font-weight: 600; margin-top: 2px; }
          .qty-control { display: flex; align-items: center; gap: 8px; background: white; border-radius: 10px; padding: 4px 8px; border: 1.5px solid #e0e0f0; }
          .qty-control button { background: none; border: none; font-size: 18px; cursor: pointer; color: #006d77; width: 24px; height: 24px; display: flex; align-items: center; justify-content: center; }
          .qty-control button:disabled { color: #ccc; }
          .qty-control span { min-width: 20px; text-align: center; font-weight: 700; font-size: 15px; }
          .remove-btn { background: none; border: none; cursor: pointer; font-size: 18px; padding: 4px; }
          .empty-cart { text-align: center; padding: 60px 20px; color: #aaa; }
          .empty-cart span { font-size: 50px; display: block; margin-bottom: 12px; }

          .drawer-total { display: flex; justify-content: space-between; padding: 16px; background: #f0fff4; border-radius: 14px; font-weight: 600; border: 1.5px solid #d1fae5; margin-top: 8px; }
          .total-amount { color: #006d77; font-size: 18px; font-weight: 700; }

          .primary-btn { background: #006d77; color: white; border: none; border-radius: 14px; padding: 14px; font-size: 15px; font-weight: 700; cursor: pointer; font-family: inherit; transition: all 0.2s; }
          .primary-btn:hover:not(:disabled) { background: #004d55; }
          .primary-btn:disabled { opacity: 0.5; cursor: not-allowed; }
          .secondary-btn { background: #f0f0f8; color: #444; border: none; border-radius: 14px; padding: 14px; font-size: 15px; font-weight: 600; cursor: pointer; font-family: inherit; transition: background 0.2s; }
          .secondary-btn:hover { background: #e0e0f0; }
          .btn-row { display: flex; gap: 10px; }
          .btn-row .primary-btn, .btn-row .secondary-btn { flex: 1; }

          .form-label { font-size: 13px; font-weight: 600; color: #555; margin-bottom: 4px; display: block; }
          .form-input { width: 100%; padding: 12px; border: 1.5px solid #e0e0f0; border-radius: 12px; font-size: 14px; font-family: inherit; outline: none; transition: border 0.2s; resize: none; background: white; }
          .form-input:focus { border-color: #006d77; }
          
          .shipping-box { background: #f0f4f8; padding: 16px; border-radius: 12px; border: 1px solid #d0e0e8; margin: 8px 0; }
          .shipping-title { font-size: 14px; font-weight: 700; color: #006d77; margin-bottom: 12px; }
          .shipping-grid { display: flex; flex-direction: column; gap: 10px; }
          .loading-text { font-size: 12px; color: #666; font-style: italic; margin-top: 10px; }
          
          .courier-list { margin-top: 12px; display: flex; flex-direction: column; gap: 8px; }
          .courier-option { display: flex; align-items: center; gap: 12px; background: white; padding: 12px; border-radius: 10px; border: 1px solid #e0e0f0; cursor: pointer; transition: all 0.2s; }
          .courier-option:hover { border-color: #006d77; }
          .courier-option.active { border-color: #006d77; background: #e8f7f8; }
          .courier-info { flex: 1; display: flex; flex-direction: column; }
          .courier-service { font-weight: 600; font-size: 14px; color: #1a1a2e; }
          .courier-etd { font-size: 12px; color: #666; }
          .courier-price { font-weight: 700; color: #006d77; }

          .payment-options { display: flex; gap: 10px; }
          .payment-option { flex: 1; padding: 12px 8px; border: 2px solid #e0e0f0; border-radius: 12px; background: white; cursor: pointer; font-size: 13px; font-weight: 600; font-family: inherit; transition: all 0.2s; text-align: center; }
          .payment-option.active { border-color: #006d77; background: #e8f7f8; color: #006d77; }

          .order-summary-box { background: #f8f9ff; border-radius: 14px; padding: 14px; border: 1.5px solid #e8e8f8; }
          .order-summary-row { display: flex; justify-content: space-between; font-size: 13px; padding: 4px 0; color: #555; }
          .total-row { font-weight: 700; color: #006d77; font-size: 15px; padding-top: 10px; margin-top: 6px; border-top: 1px solid #e0e0f0; }
          .error-text { color: #dc2626; font-size: 13px; background: #fef2f2; padding: 10px 14px; border-radius: 10px; }

          .text-center { align-items: center; text-align: center; }
          .success-icon, .qris-icon { font-size: 70px; margin: 20px 0 10px; }
          .success-desc, .qris-desc { color: #666; font-size: 14px; line-height: 1.6; max-width: 300px; }
          .qris-btn { display: inline-block; margin: 16px 0; background: #006d77; color: white; padding: 14px 28px; border-radius: 14px; font-weight: 700; text-decoration: none; font-size: 15px; }
          .qris-note { font-size: 12px; color: #999; max-width: 280px; line-height: 1.5; }
          .order-id-text { font-size: 13px; color: #888; background: #f0f0f8; padding: 8px 16px; border-radius: 10px; font-weight: 600; }
        `}</style>
      </div>
    </div>
  );
}
