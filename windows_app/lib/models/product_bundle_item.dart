class ProductBundleItem {
  final int? id;
  final int? bundleProductId;
  final int itemProductId;
  final int quantity;
  
  // Optional, for UI display
  final String? itemName;

  ProductBundleItem({
    this.id,
    this.bundleProductId,
    required this.itemProductId,
    required this.quantity,
    this.itemName,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bundle_product_id': bundleProductId,
      'item_product_id': itemProductId,
      'quantity': quantity,
    };
  }

  factory ProductBundleItem.fromMap(Map<String, dynamic> map, {String? itemName}) {
    return ProductBundleItem(
      id: map['id'],
      bundleProductId: map['bundle_product_id'],
      itemProductId: map['item_product_id'],
      quantity: map['quantity'],
      itemName: itemName,
    );
  }
}
