import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/category_provider.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
    });
  }

  Future<void> _deleteCategory(int id) async {
    try {
      await Provider.of<CategoryProvider>(context, listen: false).deleteCategory(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Kategori berhasil dihapus')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus kategori. Pastikan tidak ada produk yang menggunakan kategori ini.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddEditDialog([Map<String, dynamic>? category]) {
    final nameController = TextEditingController(text: category?['name'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(category == null ? 'Tambah Kategori' : 'Edit Kategori'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nama Kategori'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final db = await DatabaseService().database;
                try {
                  if (category == null) {
                    await Provider.of<CategoryProvider>(context, listen: false).addCategory(nameController.text);
                  } else {
                    await Provider.of<CategoryProvider>(context, listen: false).updateCategory(category['id'], nameController.text);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Error: Nama kategori sudah ada'), backgroundColor: Colors.red),
                    );
                  }
                }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Kategori'),
      ),
      body: Consumer<CategoryProvider>(
        builder: (context, catProvider, _) {
          if (catProvider.isLoading) return const Center(child: CircularProgressIndicator());
          if (catProvider.categories.isEmpty) return const Center(child: Text('Belum ada kategori'));
          
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: catProvider.categories.length,
            itemBuilder: (context, index) {
              final cat = catProvider.categories[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.category)),
                title: Text(cat['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showAddEditDialog(cat),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Hapus Kategori?'),
                            content: Text('Hapus kategori "${cat['name']}"?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _deleteCategory(cat['id']);
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
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEditDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
