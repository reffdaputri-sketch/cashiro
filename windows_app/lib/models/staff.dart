class Staff {
  final int? id;
  final String name;
  final String pin;
  final String role;
  final List<String> permissions;
  final DateTime createdAt;

  Staff({
    this.id,
    required this.name,
    required this.pin,
    this.role = 'Cashier',
    required this.permissions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pin': pin,
      'role': role,
      'permissions': permissions.join(','),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id'],
      name: map['name'],
      pin: map['pin'],
      role: map['role'] ?? 'Cashier',
      permissions: (map['permissions'] as String?)?.split(',').where((s) => s.isNotEmpty).toList() ?? [],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
