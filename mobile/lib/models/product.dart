import 'package:mobile/models/product_variation.dart';
import 'package:mobile/models/product_bundle_item.dart';

class Product {
  final int? id;
  final String name;
  final double price;
  final int stock;
  final String? code;
  final String? imagePath;
  final DateTime createdAt;
  final double costPrice;
  final String? category;
  final int minStock;
  final bool isOnline;
  final int weight;
  final bool isDeleted;
  final bool isBundle;
  final int? supplierId;
  final List<ProductVariation> variations;
  final List<ProductBundleItem> bundleItems;

  Product({
    this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.code,
    this.imagePath,
    required this.createdAt,
    this.costPrice = 0.0,
    this.category,
    this.minStock = 5,
    this.isOnline = false,
    this.weight = 0,
    this.isDeleted = false,
    this.isBundle = false,
    this.supplierId,
    this.variations = const [],
    this.bundleItems = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'stock': stock,
      'code': code,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'cost_price': costPrice,
      'category': category,
      'min_stock': minStock,
      'is_online': isOnline ? 1 : 0,
      'weight': weight,
      'is_deleted': isDeleted ? 1 : 0,
      'is_bundle': isBundle ? 1 : 0,
      'supplier_id': supplierId,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {List<ProductVariation>? variations, List<ProductBundleItem>? bundleItems}) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      code: map['code'],
      imagePath: map['image_path'],
      createdAt: DateTime.parse(map['created_at']),
      costPrice: map['cost_price'] ?? 0.0,
      category: map['category'],
      minStock: map['min_stock'] ?? 5,
      isOnline: map['is_online'] == 1,
      weight: map['weight'] ?? 0,
      isDeleted: map['is_deleted'] == 1,
      isBundle: map['is_bundle'] == 1,
      supplierId: map['supplier_id'],
      variations: variations ?? [],
      bundleItems: bundleItems ?? [],
    );
  }
}
