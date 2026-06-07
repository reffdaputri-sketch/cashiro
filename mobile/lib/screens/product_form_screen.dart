import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';
import 'package:mobile/models/product_bundle_item.dart';
import 'package:mobile/screens/scanner_screen.dart'; // Import Scanner
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/purchase_license_screen.dart';

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
  final _weightController = TextEditingController(text: '0'); // New
  final _codeController = TextEditingController();
  final _costPriceController = TextEditingController(); // New
  final _minStockController = TextEditingController(text: '5'); // New
  
  File? _imageFile;
  String? _imageUrl;
  List<ProductVariation> _variations = []; // New
  List<String> _categoryList = []; // New
  String? _selectedCategory;
  bool _isOnline = false; // New
  bool _isUnlimited = false; // New

  // Bundling & Supplier
  bool _isBundle = false;
  List<ProductBundleItem> _bundleItems = [];
  int? _selectedSupplierId;
  List<Map<String, dynamic>> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadSuppliers();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _priceController.text = widget.product!.price.toStringAsFixed(0);
      _stockController.text = widget.product!.stock.toString();
      _weightController.text = widget.product!.weight.toString();
      _codeController.text = widget.product!.code ?? '';
      _costPriceController.text = widget.product!.costPrice.toStringAsFixed(0);
      _minStockController.text = widget.product!.minStock.toString();
      _selectedCategory = widget.product!.category;
      _isOnline = widget.product!.isOnline;
      _isUnlimited = widget.product!.isUnlimited;
      _variations = List.from(widget.product!.variations); // Copy list
      _isBundle = widget.product!.isBundle;
      _bundleItems = List.from(widget.product!.bundleItems);
      _selectedSupplierId = widget.product!.supplierId;
      
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

  Future<void> _loadSuppliers() async {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    final data = await provider.getSuppliers();
    setState(() {
      _suppliers = data;
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
              final auth = Provider.of<AuthProvider>(context, listen: false);
              if (auth.isDemo) {
                _showDemoLockedDialog();
                return;
              }
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

  /// Buka dialog untuk tambah variasi baru atau edit variasi yang sudah ada.
  /// Jika [editIndex] tidak null, dialog berjalan dalam mode edit.
  void _showVariationDialog({int? editIndex}) {
    final isEdit = editIndex != null;
    final existing = isEdit ? _variations[editIndex] : null;

    final nameCtx  = TextEditingController(text: existing?.name  ?? '');
    final priceCtx = TextEditingController(text: existing != null ? existing.price.toStringAsFixed(0) : '');
    final stockCtx = TextEditingController(text: existing?.stock.toString() ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(isEdit ? Icons.edit : Icons.add_circle_outline,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(isEdit ? 'Edit Variasi' : 'Tambah Variasi'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtx,
              decoration: const InputDecoration(
                labelText: 'Nama Variasi',
                hintText: 'Contoh: Merah, XL, 250ml',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.label_outline),
              ),
              autofocus: !isEdit,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: priceCtx,
                    decoration: const InputDecoration(
                      labelText: 'Harga Jual',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: stockCtx,
                    decoration: const InputDecoration(
                      labelText: 'Stok',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final name  = nameCtx.text.trim();
              final price = double.tryParse(priceCtx.text);
              final stock = int.tryParse(stockCtx.text);
              if (name.isNotEmpty && price != null && stock != null) {
                setState(() {
                  final updated = ProductVariation(
                    id: existing?.id,           // pertahankan ID asli saat edit
                    productId: existing?.productId,
                    name: name,
                    price: price,
                    stock: stock,
                    sku: existing?.sku,
                  );
                  if (isEdit) {
                    _variations[editIndex] = updated;
                  } else {
                    _variations.add(updated);
                  }
                });
                Navigator.pop(dialogCtx);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nama, harga, dan stok wajib diisi.')),
                );
              }
            },
            child: Text(isEdit ? 'Simpan' : 'Tambah'),
          ),
        ],
      ),
    );
  }

  void _showAddBundleItemDialog() {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    // filter only non-bundle products
    final availableProducts = provider.products.where((p) => !p.isBundle).toList();
    Product? selectedProduct;
    final qtyCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Tambah Komponen Paket'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Product>(
                decoration: const InputDecoration(labelText: 'Pilih Produk', border: OutlineInputBorder()),
                items: availableProducts.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                onChanged: (val) => setDialogState(() => selectedProduct = val),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: qtyCtrl,
                decoration: const InputDecoration(labelText: 'Kuantitas (Qty)', border: OutlineInputBorder()),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text);
                if (selectedProduct != null && qty != null && qty > 0) {
                  setState(() {
                    _bundleItems.add(ProductBundleItem(
                      itemProductId: selectedProduct!.id!,
                      quantity: qty,
                      itemName: selectedProduct!.name,
                    ));
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoLockedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Fitur Terkunci'),
          ],
        ),
        content: const Text(
          'Anda sedang menggunakan Akun Demo. Untuk dapat menambah/mengedit produk dan profil toko Anda sendiri, silakan beli lisensi Cashiro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Nanti Saja'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PurchaseLicenseScreen()),
              );
            },
            child: const Text('Beli Lisensi'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isDemo) {
      _showDemoLockedDialog();
      return;
    }

    if (_formKey.currentState!.validate()) {
      final product = Product(
        id: widget.product?.id,
        name: _nameController.text,
        price: double.tryParse(_priceController.text) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        weight: int.tryParse(_weightController.text) ?? 0,
        code: _codeController.text.isEmpty ? null : _codeController.text,
        imagePath: _imageFile?.path ?? _imageUrl,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        costPrice: double.tryParse(_costPriceController.text) ?? 0,
        category: _selectedCategory,
        minStock: int.tryParse(_minStockController.text) ?? 5,
        isOnline: _isOnline,
        isUnlimited: _isUnlimited,
        isBundle: _isBundle,
        supplierId: _selectedSupplierId,
        variations: _variations,
        bundleItems: _bundleItems,
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
          DropdownButtonFormField<int>(
            value: _selectedSupplierId,
            decoration: const InputDecoration(
              labelText: 'Supplier Asal (Opsional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.local_shipping),
            ),
            items: [
              const DropdownMenuItem<int>(value: null, child: Text('- Tanpa Supplier -')),
              ..._suppliers.map((s) => DropdownMenuItem<int>(value: s['id'] as int, child: Text(s['name']))),
            ],
            onChanged: (val) => setState(() => _selectedSupplierId = val),
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
              if (!_isUnlimited)
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
              if (!_isUnlimited) const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Berat (Gram)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.scale),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Stok Unlimited', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Cocok untuk makanan/minuman yang stoknya tidak dihitung per porsi (selalu tersedia).'),
            value: _isUnlimited,
            activeColor: const Color(0xFF006d77),
            onChanged: (val) {
              setState(() {
                _isUnlimited = val;
                if (val) {
                  _stockController.text = '999999'; // Default value when unlimited
                } else if (_stockController.text == '999999') {
                  _stockController.text = '0';
                }
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
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
              const SizedBox(width: 16),
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
              TextButton.icon(onPressed: () => _showVariationDialog(), icon: const Icon(Icons.add), label: const Text('Tambah Variasi')),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                elevation: 0,
                child: ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(v.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    spacing: 8,
                    children: [
                      Chip(
                        label: Text('Rp ${v.price.toStringAsFixed(0)}',
                            style: const TextStyle(fontSize: 11)),
                        avatar: const Icon(Icons.payments_outlined, size: 14),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.green[50],
                      ),
                      Chip(
                        label: Text('Stok: ${v.stock}',
                            style: const TextStyle(fontSize: 11)),
                        avatar: const Icon(Icons.inventory_2_outlined, size: 14),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blue[50],
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue, size: 20),
                        tooltip: 'Edit variasi',
                        onPressed: () => _showVariationDialog(editIndex: index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        tooltip: 'Hapus variasi',
                        onPressed: () {
                          setState(() {
                            _variations.removeAt(index);
                          });
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          
          const SizedBox(height: 16),
          const Divider(),
          SwitchListTile(
            title: const Text('Produk Bundling / Paket / Resep', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: const Text('Produk ini terdiri dari beberapa produk komponen yang akan mengurangi stok mereka secara otomatis saat terjual.'),
            value: _isBundle,
            activeColor: const Color(0xFF006d77),
            onChanged: (val) => setState(() => _isBundle = val),
          ),
          if (_isBundle) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Komponen Paket', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _showAddBundleItemDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Komponen'),
                ),
              ],
            ),
            if (_bundleItems.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Belum ada komponen yang ditambahkan.', style: TextStyle(color: Colors.grey)),
              )
            else
              ..._bundleItems.asMap().entries.map((entry) {
                 final idx = entry.key;
                 final b = entry.value;
                 return ListTile(
                   title: Text(b.itemName ?? 'Unknown Product'),
                   subtitle: Text('Qty: ${b.quantity}'),
                   trailing: IconButton(
                     icon: const Icon(Icons.delete, color: Colors.red),
                     onPressed: () => setState(() => _bundleItems.removeAt(idx)),
                   ),
                 );
              }),
          ],

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
