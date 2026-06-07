class ProductVariation {
  final int? id;
  final int? productId; // Can be null before saving
  final String name;
  final double price;
  final int stock;
  final String? sku;

  ProductVariation({
    this.id,
    this.productId,
    required this.name,
    required this.price,
    required this.stock,
    this.sku,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'name': name,
      'price': price,
      'stock': stock,
      'sku': sku,
    };
  }

  factory ProductVariation.fromMap(Map<String, dynamic> map) {
    return ProductVariation(
      id: map['id'],
      productId: map['product_id'],
      name: map['name'],
      price: map['price'],
      stock: map['stock'],
      sku: map['sku'],
    );
  }
}
