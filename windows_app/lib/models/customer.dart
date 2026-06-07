class Customer {
  final int? id;
  final String name;
  final String phone;
  final DateTime createdAt;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
