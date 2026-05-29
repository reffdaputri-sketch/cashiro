import 'package:flutter/material.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';
import 'package:mobile/services/database_service.dart';

class CartProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final List<CartItem> _items = [];
  double _discount = 0.0;

  List<CartItem> get items => _items;
  double get discount => _discount;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);

  double get totalAmount {
    return subtotal - _discount;
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  void addToCart(Product product, {ProductVariation? variation}) {
    final index = _items.indexWhere((item) => 
      item.product.id == product.id && item.variation?.id == variation?.id
    );

    if (index >= 0) {
      final item = _items[index];
      final currentStock = item.variation?.stock ?? item.product.stock;
      if (item.quantity < currentStock) {
        item.quantity++;
      }
    } else {
      _items.add(CartItem(product: product, variation: variation));
    }
    notifyListeners();
  }

  void incrementQuantity(CartItem item) {
    final index = _items.indexOf(item);
    if (index >= 0) {
      final currentStock = item.variation?.stock ?? item.product.stock;
      if (item.quantity < currentStock) {
        _items[index].quantity++;
        notifyListeners();
      }
    }
  }

  void decrementQuantity(CartItem item) {
    final index = _items.indexOf(item);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  // Keep for backward compatibility if needed, or refactor usages
  void removeFromCart(CartItem cartItem) {
    decrementQuantity(cartItem);
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  void setItemDiscount(CartItem item, double amount) {
    final index = _items.indexOf(item);
    if (index >= 0) {
      _items[index].discount = amount;
      notifyListeners();
    }
  }

  Future<int?> checkout(double paidAmount, {int? customerId, String paymentMethod = 'Tunai', int? shiftId}) async {
    if (_items.isEmpty) return null;

    final db = await _db.database;
    return await db.transaction((txn) async {
      final total = totalAmount;
      final transactionId = await txn.insert('transactions', {
        'total_amount': total,
        'paid_amount': paidAmount,
        'created_at': DateTime.now().toIso8601String(),
        'customer_id': customerId,
        'payment_method': paymentMethod,
        'shift_id': shiftId,
      });

      for (var item in _items) {
        await txn.insert('transaction_items', {
          'transaction_id': transactionId,
          'product_id': item.product.id,
          'quantity': item.quantity,
          'price_at_sale': item.price - item.discount,
          'cost_at_sale': item.product.costPrice,
        });
        
        // Update stock and mark as unsynced so changes are uploaded to cloud
        if (item.variation != null) {
           int newStock = item.variation!.stock - item.quantity;
           await txn.update('product_variations', {'stock': newStock, 'is_synced': 0}, 
             where: 'id = ?', whereArgs: [item.variation!.id]);
        } else {
           int newStock = item.product.stock - item.quantity;
           await txn.update('products', {'stock': newStock, 'is_synced': 0}, 
             where: 'id = ?', whereArgs: [item.product.id]);
        }
      }

      clearCart();
      DatabaseService.hasUnsyncedChanges = true;
      return transactionId;
    });
  }
}
