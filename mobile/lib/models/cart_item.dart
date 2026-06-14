import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';

class CartItem {
  final Product product;
  final ProductVariation? variation;
  int quantity;
  double discount;
  String? notes;

  CartItem({required this.product, this.variation, this.quantity = 1, this.discount = 0.0, this.notes});

  double get price => variation?.price ?? product.price;

  double get total => (price - discount) * quantity;
}
