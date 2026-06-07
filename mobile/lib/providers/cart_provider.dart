import 'package:flutter/material.dart';
import 'package:mobile/models/cart_item.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';
import 'package:mobile/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final List<CartItem> _items = [];
  double _discount = 0.0;

  // Tax & Service Charge settings
  bool _taxEnabled = false;
  double _taxPercentage = 0.0;
  bool _serviceChargeEnabled = false;
  double _serviceChargePercentage = 0.0;

  double _manualTax = -1.0;
  bool _manualTaxIsPercent = false;
  double _manualOtherFee = -1.0;
  bool _manualOtherFeeIsPercent = false;

  CartProvider() {
    loadTaxSettings();
  }

  List<CartItem> get items => _items;
  double get discount => _discount;
  bool get taxEnabled => _taxEnabled;
  double get taxPercentage => _taxPercentage;
  bool get serviceChargeEnabled => _serviceChargeEnabled;
  double get serviceChargePercentage => _serviceChargePercentage;
  double get manualTax => _manualTax;
  bool get manualTaxIsPercent => _manualTaxIsPercent;
  double get manualOtherFee => _manualOtherFee;
  bool get manualOtherFeeIsPercent => _manualOtherFeeIsPercent;

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.total);

  double get subtotalAfterDiscount => subtotal - _discount;

  double get taxAmount {
    if (_manualTax >= 0) {
      if (_manualTaxIsPercent) return (subtotalAfterDiscount * _manualTax / 100).roundToDouble();
      return _manualTax;
    }
    if (!_taxEnabled) return 0.0;
    return (subtotalAfterDiscount * _taxPercentage / 100).roundToDouble();
  }

  double? get appliedTaxPercentage {
    if (_manualTax >= 0) {
      if (_manualTaxIsPercent) return _manualTax;
      return null;
    }
    if (_taxEnabled) return _taxPercentage;
    return null;
  }

  double get serviceChargeAmount {
    if (_manualOtherFee >= 0) {
      if (_manualOtherFeeIsPercent) return (subtotalAfterDiscount * _manualOtherFee / 100).roundToDouble();
      return _manualOtherFee;
    }
    if (!_serviceChargeEnabled) return 0.0;
    return (subtotalAfterDiscount * _serviceChargePercentage / 100).roundToDouble();
  }

  double get totalAmount {
    return subtotalAfterDiscount + taxAmount + serviceChargeAmount;
  }

  Future<void> loadTaxSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _taxEnabled = prefs.getBool('tax_enabled') ?? false;
    _taxPercentage = prefs.getDouble('tax_percentage') ?? 11.0;
    _serviceChargeEnabled = prefs.getBool('service_charge_enabled') ?? false;
    _serviceChargePercentage = prefs.getDouble('service_charge_percentage') ?? 5.0;
    notifyListeners();
  }

  void setDiscount(double amount) {
    _discount = amount;
    notifyListeners();
  }

  void setManualTax(double amount, {bool isPercent = false}) {
    _manualTax = amount;
    _manualTaxIsPercent = isPercent;
    notifyListeners();
  }

  void setManualOtherFee(double amount, {bool isPercent = false}) {
    _manualOtherFee = amount;
    _manualOtherFeeIsPercent = isPercent;
    notifyListeners();
  }

  void addToCart(Product product, {ProductVariation? variation}) {
    final index = _items.indexWhere((item) =>
      item.product.id == product.id && item.variation?.id == variation?.id
    );

    if (index >= 0) {
      final item = _items[index];
      final currentStock = item.variation?.stock ?? item.product.stock;
      if (product.isBundle || item.quantity < currentStock) {
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
      if (item.product.isBundle || item.quantity < currentStock) {
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
    _discount = 0.0;
    _manualTax = -1.0;
    _manualTaxIsPercent = false;
    _manualOtherFee = -1.0;
    _manualOtherFeeIsPercent = false;
    notifyListeners();
  }

  void setItemDiscount(CartItem item, double amount) {
    final index = _items.indexOf(item);
    if (index >= 0) {
      _items[index].discount = amount;
      notifyListeners();
    }
  }

  Future<int?> checkout(double paidAmount, {int? customerId, String paymentMethod = 'Tunai', int? shiftId, String? cashierName, double? taxPercentage}) async {
    if (_items.isEmpty) return null;

    final db = await _db.database;
    final tax = taxAmount;
    final svc = serviceChargeAmount;

    return await db.transaction((txn) async {
      final total = totalAmount;
      final transactionId = await txn.insert('transactions', {
        'total_amount': total,
        'paid_amount': paidAmount,
        'created_at': DateTime.now().toIso8601String(),
        'customer_id': customerId,
        'payment_method': paymentMethod,
        'shift_id': shiftId,
        'tax_amount': tax,
        'service_charge_amount': svc,
        'cashier_name': cashierName,
        'tax_percentage': taxPercentage,
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
        if (item.product.isBundle) {
           for (var b in item.product.bundleItems) {
               final compResult = await txn.query('products', where: 'id = ?', whereArgs: [b.itemProductId]);
               if (compResult.isEmpty) throw Exception("Komponen produk tidak ditemukan.");
               final compStock = compResult.first['stock'] as int;
               final compName = compResult.first['name'] as String;
               final needed = b.quantity * item.quantity;
               if (compStock < needed) {
                  throw Exception("Barang $compName Habis (dibutuhkan $needed untuk paket).");
               }
               int newStock = compStock - needed;
               await txn.update('products', {'stock': newStock, 'is_synced': 0}, 
                 where: 'id = ?', whereArgs: [b.itemProductId]);
           }
        } else if (item.variation != null) {
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
