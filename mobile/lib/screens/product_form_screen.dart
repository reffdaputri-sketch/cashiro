import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';
import 'package:mobile/screens/scanner_screen.dart'; // Import Scanner

import 'dart:io';
import 'dart:math';
import 'package:mobile/services/database_service.dart' as db_service;
import 'package:image_picker/image_picker.dart';


class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _codeController = TextEditingController();
  final _costPriceController = TextEditingController(); // New
  final _minStockController = TextEditingController(text: '5'); // New
  
  File? _imageFile;
  String? _imageUrl;
  List<ProductVariation> _variations = []; // New
  List<String> _categoryList = []; // New
  String? _selectedCategory;
  bool _isOnline = false; // New

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _codeController.text = widget.product!.code ?? '';
      _costPriceController.text = widget.product!.costPrice.toStringAsFixed(0);
      _minStockController.text = widget.product!.minStock.toString();
      _selectedCategory = widget.product!.category;
      _isOnline = widget.product!.isOnline;
      _variations = List.from(widget.product!.variations); // Copy list
      
      if (widget.product!.imagePath != null) {
        final path = widget.product!.imagePath!;
        if (path.startsWith('http://') || path.startsWith('https://')) {
          _imageUrl = path;
        } else {
          _imageFile = File(path);
        }
      }
    }
  }

  Future<void> _loadCategories() async {
    final db = await db_service.DatabaseService().database;
    final List<Map<String, dynamic>> maps = await db.query('categories', orderBy: 'name ASC');
    setState(() {
      _categoryList = maps.map((e) => e['name'] as String).toList();
    });
  }

  Future<void> _addNewCategoryDialog() async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Kategori Baru'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Nama Kategori',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final db = await db_service.DatabaseService().database;
                final existing = await db.query('categories', where: 'name = ?', whereArgs: [name]);
                if (existing.isEmpty) {
                  await db.insert('categories', {'name': name});
                }
                await _loadCategories();
                setState(() {
                  _selectedCategory = name;
                });
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrl = null;
      });
    }
  }



  void _generateCode() {
    final rng = Random();
    final code = List.generate(13, (_) => rng.nextInt(10)).join();
    setState(() {
      _codeController.text = code;
    });
  }

  Future<void> _scanCode() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const ScannerScreen()));
    if (result != null && result is String) {
      setState(() {
        _codeController.text = result;
      });
    } 
  }

  void _addVariation() {
    showDialog(
      context: context,
      builder: (context) {
        final nameCtx = TextEditingController();
        final priceCtx = TextEditingController();
        final stockCtx = TextEditingController();
        return AlertDialog(
          title: const Text('Tambah Variasi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtx, decoration: const InputDecoration(labelText: 'Nama (misal: Merah, XL)')),
              TextField(controller: priceCtx, decoration: const InputDecoration(labelText: 'Harga Jual'), keyboardType: TextInputType.number),
              TextField(controller: stockCtx, decoration: const InputDecoration(labelText: 'Stok'), keyboardType: TextInputType.number),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (nameCtx.text.isNotEmpty && priceCtx.text.isNotEmpty && stockCtx.text.isNotEmpty) {
                  setState(() {
                    _variations.add(ProductVariation(
                      name: nameCtx.text,
                      price: double.tryParse(priceCtx.text) ?? 0,
                      stock: int.tryParse(stockCtx.text) ?? 0,
                    ));
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        code: _codeController.text.isEmpty ? null : _codeController.text,
        imagePath: _imageFile?.path ?? _imageUrl,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        costPrice: double.tryParse(_costPriceController.text) ?? 0,
        category: _selectedCategory,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        isOnline: _isOnline,
        variations: _variations,
      );

      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (widget.product == null) {
        await provider.addProduct(product);
      } else {
        await provider.updateProduct(product);
      }
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    Widget formContent = Form(
      key: _formKey,
      child: ListView(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    )
                  : (_imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_imageUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50)),
                        )
                      : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 20),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nama Produk',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.shopping_bag),
            ),
            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
          ),
           const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _categoryList.contains(_selectedCategory) ? _selectedCategory : null,
                  decoration: const InputDecoration(
                    labelText: 'Kategori (Opsional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: [
                    const DropdownMenuItem<String>(value: null, child: Text('- Tanpa Kategori -')),
                    ..._categoryList.map((c) => DropdownMenuItem(value: c, child: Text(c))),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedCategory = val;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                onPressed: _addNewCategoryDialog,
                tooltip: 'Tambah Kategori Baru',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _costPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga Modal',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Harga Jual',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.payments),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _stockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok Utama',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.inventory),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _minStockController,
                  decoration: const InputDecoration(
                    labelText: 'Stok Minimum',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.warning_amber_rounded),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  decoration: const InputDecoration(
                    labelText: 'Barcode / Kode',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.qr_code),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(icon: const Icon(Icons.qr_code_scanner), onPressed: _scanCode),
              IconButton.filledTonal(icon: const Icon(Icons.autorenew), onPressed: _generateCode),
            ],
          ),
          const SizedBox(height: 24),
          
          // Variations Section
          const Divider(),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Variasi Produk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              TextButton.icon(onPressed: _addVariation, icon: const Icon(Icons.add), label: const Text('Tambah Variasi')),
            ],
          ),
          if (_variations.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Tidak ada variasi (Gunakan harga & stok utama)', style: TextStyle(color: Colors.grey)),
            )
          else
            ..._variations.asMap().entries.map((entry) {
              final index = entry.key;
              final v = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Rp ${v.price.toStringAsFixed(0)} - Stok: ${v.stock}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _variations.removeAt(index);
                      });
                    },
                  ),
                ),
              );
            }),
          
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Tampilkan di Toko Online', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Produk ini akan bisa dibeli oleh pelanggan lewat link Toko Online Anda.'),
            value: _isOnline,
            activeColor: const Color(0xFF006d77),
            onChanged: (val) {
              setState(() {
                _isOnline = val;
              });
            },
          ),

          const SizedBox(height: 32),
          SizedBox(
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _save, 
              child: const Text('Simpan Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Tambah Produk' : 'Edit Produk'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
      ),
      backgroundColor: isTablet ? Colors.grey[50] : Colors.white,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: isTablet 
            ? Card(
                margin: const EdgeInsets.all(24),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: formContent,
                ),
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: formContent,
              ),
        ),
      ),
    );
  }
}
