import 'package:mobile/models/product_variation.dart';

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
  final List<ProductVariation> variations;

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
    this.variations = const [],
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
    };
  }

  factory Product.fromMap(Map<String, dynamic> map, {List<ProductVariation> variations = const []}) {
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
      variations: variations,
    );
  }
}
