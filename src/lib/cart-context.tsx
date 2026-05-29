'use client';

import { createContext, useContext, useState, ReactNode } from 'react';

interface CartItem {
  product_id: number;
  name: string;
  price: number;
  qty: number;
  stock: number;
  image_url?: string;
}

interface CartContextType {
  items: CartItem[];
  addItem: (item: Omit<CartItem, 'qty'>) => void;
  removeItem: (product_id: number) => void;
  updateQty: (product_id: number, qty: number) => void;
  clearCart: () => void;
  total: number;
  count: number;
}

const CartContext = createContext<CartContextType | null>(null);

export function CartProvider({ children }: { children: ReactNode }) {
  const [items, setItems] = useState<CartItem[]>([]);

  const addItem = (item: Omit<CartItem, 'qty'>) => {
    setItems(prev => {
      const existing = prev.find(i => i.product_id === item.product_id);
      if (existing) {
        const newQty = existing.qty + 1;
        if (newQty > item.stock) return prev;
        return prev.map(i => i.product_id === item.product_id ? { ...i, qty: newQty } : i);
      }
      if (item.stock <= 0) return prev;
      return [...prev, { ...item, qty: 1 }];
    });
  };

  const removeItem = (product_id: number) => {
    setItems(prev => prev.filter(i => i.product_id !== product_id));
  };

  const updateQty = (product_id: number, qty: number) => {
    if (qty <= 0) { removeItem(product_id); return; }
    setItems(prev => prev.map(i =>
      i.product_id === product_id
        ? { ...i, qty: Math.min(qty, i.stock) }
        : i
    ));
  };

  const clearCart = () => setItems([]);
  const total = items.reduce((sum, i) => sum + i.price * i.qty, 0);
  const count = items.reduce((sum, i) => sum + i.qty, 0);

  return (
    <CartContext.Provider value={{ items, addItem, removeItem, updateQty, clearCart, total, count }}>
      {children}
    </CartContext.Provider>
  );
}

export function useCart() {
  const ctx = useContext(CartContext);
  if (!ctx) throw new Error('useCart must be used within CartProvider');
  return ctx;
}
