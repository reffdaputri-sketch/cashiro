class TransactionModel {
  final int? id;
  final double totalAmount;
  final double paidAmount;
  final DateTime createdAt;
  final int? customerId;
  final String status;
  final double taxAmount;
  final double serviceChargeAmount;

  TransactionModel({
    this.id,
    required this.totalAmount,
    required this.paidAmount,
    required this.createdAt,
    this.customerId,
    this.status = 'Selesai',
    this.taxAmount = 0.0,
    this.serviceChargeAmount = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'created_at': createdAt.toIso8601String(),
      'customer_id': customerId,
      'status': status,
      'tax_amount': taxAmount,
      'service_charge_amount': serviceChargeAmount,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      totalAmount: map['total_amount'],
      paidAmount: map['paid_amount'],
      createdAt: DateTime.parse(map['created_at']),
      customerId: map['customer_id'],
      status: map['status'] ?? 'Selesai',
      taxAmount: map['tax_amount'] ?? 0.0,
      serviceChargeAmount: map['service_charge_amount'] ?? 0.0,
    );
  }
}

class TransactionItem {
  final int? id;
  final int transactionId;
  final int productId;
  final int quantity;
  final double priceAtSale;
  final int returnedQty;

  TransactionItem({
    this.id,
    required this.transactionId,
    required this.productId,
    required this.quantity,
    required this.priceAtSale,
    this.returnedQty = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transaction_id': transactionId,
      'product_id': productId,
      'quantity': quantity,
      'price_at_sale': priceAtSale,
      'returned_qty': returnedQty,
    };
  }

  factory TransactionItem.fromMap(Map<String, dynamic> map) {
    return TransactionItem(
      id: map['id'],
      transactionId: map['transaction_id'],
      productId: map['product_id'],
      quantity: map['quantity'],
      priceAtSale: map['price_at_sale'],
      returnedQty: map['returned_qty'] as int? ?? 0,
    );
  }
}
