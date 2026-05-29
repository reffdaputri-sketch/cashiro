class TransactionModel {
  final int? id;
  final double totalAmount;
  final double paidAmount;
  final DateTime createdAt;
  final int? customerId;

  TransactionModel({
    this.id,
    required this.totalAmount,
    required this.paidAmount,
    required this.createdAt,
    this.customerId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'created_at': createdAt.toIso8601String(),
      'customer_id': customerId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      totalAmount: map['total_amount'],
      paidAmount: map['paid_amount'],
      createdAt: DateTime.parse(map['created_at']),
      customerId: map['customer_id'],
    );
  }
}

class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double priceAtSale;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.priceAtSale,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      priceAtSale: map['price_at_sale'],
    );
  }
}
