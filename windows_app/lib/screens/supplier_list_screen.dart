import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/product_provider.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  List<Map<String, dynamic>> _suppliers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final data = await provider.getSuppliers();
    setState(() {
      _suppliers = data;
      _isLoading = false;
    });
  }

  void _showFormDialog({Map<String, dynamic>? supplier}) {
    final nameCtrl = TextEditingController(text: supplier?['name']);
    final phoneCtrl = TextEditingController(text: supplier?['phone']);
    final addrCtrl = TextEditingController(text: supplier?['address']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(supplier == null ? 'Tambah Supplier' : 'Edit Supplier'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama Supplier')),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'No. Telepon'), keyboardType: TextInputType.phone),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Alamat')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameCtrl.text.isEmpty) return;
              final provider = Provider.of<ProductProvider>(context, listen: false);
              if (supplier == null) {
                await provider.addSupplier(nameCtrl.text, phoneCtrl.text, addrCtrl.text);
              } else {
                await provider.updateSupplier(supplier['id'], nameCtrl.text, phoneCtrl.text, addrCtrl.text);
              }
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSuppliers();
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(int id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Supplier?'),
        content: Text('Yakin ingin menghapus supplier $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await Provider.of<ProductProvider>(context, listen: false).deleteSupplier(id);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadSuppliers();
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Supplier'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _suppliers.isEmpty
              ? const Center(child: Text('Belum ada data supplier.'))
              : ListView.builder(
                  itemCount: _suppliers.length,
                  itemBuilder: (context, index) {
                    final sup = _suppliers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: const CircleAvatar(child: Icon(Icons.local_shipping)),
                        title: Text(sup['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${sup['phone'] ?? '-'}\n${sup['address'] ?? '-'}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _showFormDialog(supplier: sup),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(sup['id'], sup['name']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showFormDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
