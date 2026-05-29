import { NextResponse } from 'next/server';
import { supabase } from '@/lib/supabase';
import crypto from 'crypto';

// POST /api/sellers/[slug]/orders - Buat pesanan baru dari landing page
export async function POST(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;
    const { customer_name, customer_phone, customer_address, items, payment_method, notes, shipping_cost, courier_name } = await req.json();

    if (!items || !Array.isArray(items) || items.length === 0) {
      return NextResponse.json({ error: 'Items pesanan tidak boleh kosong' }, { status: 400 });
    }

    const { data: seller, error: sellerErr } = await supabase
      .from('sellers')
      .select('id, balance, store_id, stores(store_name, phone, bank_name, bank_account, bank_account_name)')
      .eq('slug', slug)
      .eq('is_active', true)
      .single();

    if (sellerErr || !seller) {
      return NextResponse.json({ error: 'Toko tidak ditemukan atau tidak aktif' }, { status: 404 });
    }

    let totalAmount = 0;
    const enrichedItems: any[] = [];

    for (const item of items) {
      const { data: product, error: prodErr } = await supabase
        .from('seller_products')
        .select('id, name, price, stock')
        .eq('id', item.product_id)
        .eq('seller_id', seller.id)
        .eq('is_active', true)
        .single();

      if (prodErr || !product) {
        return NextResponse.json({ error: `Produk ID ${item.product_id} tidak ditemukan` }, { status: 400 });
      }

      if (product.stock < item.qty) {
        return NextResponse.json({ error: `Stok "${product.name}" tidak cukup (tersisa ${product.stock})` }, { status: 400 });
      }

      const itemTotal = product.price * item.qty;
      totalAmount += itemTotal;
      enrichedItems.push({
        product_id: product.id,
        name: product.name,
        qty: item.qty,
        price: product.price,
        discount: item.discount || 0,
        total: itemTotal,
      });
    }

    for (const item of enrichedItems) {
      const { data: currentProduct } = await supabase
        .from('seller_products')
        .select('stock')
        .eq('id', item.product_id)
        .single();

      await supabase
        .from('seller_products')
        .update({ stock: (currentProduct?.stock || 0) - item.qty, updated_at: new Date().toISOString() })
        .eq('id', item.product_id);
    }

    const shipCost = Number(shipping_cost) || 0;
    totalAmount += shipCost;

    let paymentUrl = '';
    let merchantOrderId = '';

    if (payment_method === 'qris') {
      return NextResponse.json({ error: 'Metode pembayaran QRIS sudah dinonaktifkan' }, { status: 400 });
    }

    const { data: order, error: orderErr } = await supabase
      .from('seller_orders')
      .insert({
        seller_id: seller.id,
        customer_name: customer_name || '',
        customer_phone: customer_phone || '',
        customer_address: customer_address || '',
        items: enrichedItems,
        total_amount: totalAmount,
        shipping_cost: shipCost,
        courier_name: courier_name || '',
        payment_method: payment_method || 'manual',
        status: 'pending',
        payment_url: paymentUrl,
        merchant_order_id: merchantOrderId,
        notes: notes || '',
      })
      .select('id, status, total_amount, payment_url')
      .single();

    if (orderErr || !order) {
      return NextResponse.json({ error: orderErr?.message || 'Gagal membuat order' }, { status: 500 });
    }

    return NextResponse.json({
      success: true,
      order_id: order.id,
      total_amount: order.total_amount,
      status: order.status,
      seller_phone: (seller as any).stores?.phone || '',
      seller_bank_name: (seller as any).stores?.bank_name || '',
      seller_bank_account: (seller as any).stores?.bank_account || '',
      seller_bank_account_name: (seller as any).stores?.bank_account_name || '',
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// GET /api/sellers/[slug]/orders - List orders
export async function GET(req: Request, { params }: { params: Promise<{ slug: string }> }) {
  try {
    const { slug } = await params;

    const { data: seller } = await supabase
      .from('sellers').select('id').eq('slug', slug).single();
    if (!seller) return NextResponse.json({ error: 'Toko tidak ditemukan' }, { status: 404 });

    const { data: orders, error } = await supabase
      .from('seller_orders')
      .select('*')
      .eq('seller_id', seller.id)
      .order('created_at', { ascending: false });

    if (error) return NextResponse.json({ error: error.message }, { status: 500 });
    return NextResponse.json({ orders: orders || [] });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
