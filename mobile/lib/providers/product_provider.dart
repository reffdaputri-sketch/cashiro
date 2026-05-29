import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';
import 'dart:math';

class ProductProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Product> _products = [];
  bool _isLoading = false;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  Future<void> fetchProducts() async {
    _isLoading = true;
    notifyListeners();
    
    final productMaps = await _db.getAll('products', orderBy: 'id DESC');
    final variationMaps = await _db.getAll('product_variations');

    _products = productMaps.map((pMap) {
       final pId = pMap['id'] as int;
       final variations = variationMaps
           .where((v) => v['product_id'] == pId)
           .map((v) => ProductVariation.fromMap(v))
           .toList();
       return Product.fromMap(pMap, variations: variations);
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final id = await txn.insert('products', product.toMap()..['is_synced'] = 0);
      for (var v in product.variations) {
        final vMap = v.toMap();
        vMap['product_id'] = id;
        vMap.remove('id'); // Ensure ID is generated
        vMap['is_synced'] = 0;
        await txn.insert('product_variations', vMap);
      }
    });
    DatabaseService.hasUnsyncedChanges = true;
    await fetchProducts();
  }

  Future<void> addProductsInBatch(List<Product> productsList) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      for (var product in productsList) {
        final id = await txn.insert('products', product.toMap()..['is_synced'] = 0);
        for (var v in product.variations) {
          final vMap = v.toMap();
          vMap['product_id'] = id;
          vMap.remove('id');
          vMap['is_synced'] = 0;
          await txn.insert('product_variations', vMap);
        }
      }
    });
    DatabaseService.hasUnsyncedChanges = true;
    await fetchProducts();
  }

  Future<void> updateProduct(Product product) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.update('products', product.toMap()..['is_synced'] = 0, where: 'id = ?', whereArgs: [product.id]);
      
      // Sync variations: Delete all and re-insert (simplest strategy)
      await txn.delete('product_variations', where: 'product_id = ?', whereArgs: [product.id]);
      
      for (var v in product.variations) {
         final vMap = v.toMap();
         vMap['product_id'] = product.id;
         vMap.remove('id'); 
         vMap['is_synced'] = 0;
         await txn.insert('product_variations', vMap);
      }
    });
    DatabaseService.hasUnsyncedChanges = true;
    await fetchProducts();
  }

  Future<void> deleteProduct(int id) async {
    await _db.delete('products', id); // Variations deleted by CASCADE
    await fetchProducts();
  }
  Future<void> updateStock(int id, int newStock) async {
    await _db.update('products', {'stock': newStock}, id);
    await fetchProducts();
  }

  Future<void> generateDemoData() async {
    _isLoading = true;
    notifyListeners();

    final now = DateTime.now();
    final productNames = [
      {'name': 'Air Mineral 600ml', 'cat': 'Minuman', 'basePrice': 3000},
      {'name': 'Roti Tawar Kupas', 'cat': 'Makanan', 'basePrice': 15000},
      {'name': 'Beras Premium 5kg', 'cat': 'Sembako', 'basePrice': 65000},
      {'name': 'Minyak Goreng 2L', 'cat': 'Sembako', 'basePrice': 35000},
      {'name': 'Keripik Kentang', 'cat': 'Snack', 'basePrice': 12000},
      {'name': 'Wafer Coklat', 'cat': 'Snack', 'basePrice': 8000},
      {'name': 'Kopi Instan 10x', 'cat': 'Minuman', 'basePrice': 15000},
      {'name': 'Teh Botol 500ml', 'cat': 'Minuman', 'basePrice': 6000},
      {'name': 'Gula Pasir 1kg', 'cat': 'Sembako', 'basePrice': 14000},
      {'name': 'Telur Ayam 1kg', 'cat': 'Sembako', 'basePrice': 28000},
      {'name': 'Mie Instan Goreng', 'cat': 'Makanan', 'basePrice': 3500},
      {'name': 'Sabun Mandi Cair', 'cat': 'Sembako', 'basePrice': 25000},
      {'name': 'Shampoo Sachet', 'cat': 'Sembako', 'basePrice': 1000},
      {'name': 'Buku Tulis 38lbr', 'cat': 'Alat Tulis', 'basePrice': 4000},
      {'name': 'Pulpen Hitam', 'cat': 'Alat Tulis', 'basePrice': 2000},
    ];

    final random = Random();

    for (var p in productNames) {
      // Randomize price slightly +/- 10%
      double basePrice = (p['basePrice'] as int).toDouble();
      double costPrice = basePrice * 0.75; // 25% margin roughly
      double sellingPrice = basePrice;

      // Random Stock 10-100
      int stock = 10 + random.nextInt(90);

      // Random Barcode (13 digits)
      String barcode = '899' + List.generate(10, (_) => random.nextInt(10)).join();

      final product = Product(
        name: p['name'] as String,
        price: sellingPrice,
        costPrice: costPrice,
        stock: stock,
        code: barcode,
        category: p['cat'] as String,
        createdAt: now,
      );

      await addProduct(product);
    }
    
    _isLoading = false;
    notifyListeners();
  }
}
