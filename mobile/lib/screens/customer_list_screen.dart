import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    final db = await DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query('customers', orderBy: 'name ASC');
    setState(() {
      _customers = maps;
      _isLoading = false;
    });
  }

  Future<void> _deleteCustomer(int id) async {
    final db = await DatabaseService().database;
    await db.delete('customers', where: 'id = ?', whereArgs: [id]);
    _loadCustomers();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pelanggan berhasil dihapus')),
      );
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? customer]) {
    final nameController = TextEditingController(text: customer?['name'] ?? '');
    final phoneController = TextEditingController(text: customer?['phone'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Tambah Pelanggan' : 'Edit Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'No. HP'),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = await DatabaseService().database;
                if (customer == null) {
                  await db.insert('customers', {
                    'name': nameController.text,
                    'phone': phoneController.text,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                } else {
                  await db.update('customers', {
                    'name': nameController.text,
                    'phone': phoneController.text,
                  }, where: 'id = ?', whereArgs: [customer['id']]);
                }
                if (context.mounted) Navigator.pop(context);
                _loadCustomers();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredCustomers = _customers.where((c) {
      final name = (c['name'] as String).toLowerCase();
      final phone = (c['phone'] as String).toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || phone.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Pelanggan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari nama atau no. hp...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredCustomers.isEmpty
                    ? const Center(child: Text('Tidak ada data pelanggan'))
                    : ListView.builder(
                        itemCount: filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final c = filteredCustomers[index];
                          return ListTile(
                            leading: const CircleAvatar(child: Icon(Icons.person)),
                            title: Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(c['phone']),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () => _showAddEditDialog(c),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Hapus Pelanggan?'),
                                        content: const Text('Data pelanggan akan dihapus secara permanen.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                              _deleteCustomer(c['id']);
                                            },
                                            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
