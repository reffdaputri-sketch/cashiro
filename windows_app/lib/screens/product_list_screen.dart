import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/product_provider.dart';
import 'package:cashiro/screens/product_form_screen.dart';
import 'package:cashiro/services/excel_import_service.dart';
import 'package:intl/intl.dart';

import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cashiro/models/product.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<ProductProvider>(context, listen: false).fetchProducts());
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddProductMenu(context),
              child: const Icon(Icons.add),
            ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final filteredProducts = provider.products.where((p) {
            final nameMatch = p.name.toLowerCase().contains(_searchQuery);
            final codeMatch = p.code?.toLowerCase().contains(_searchQuery) ?? false;
            return nameMatch || codeMatch;
          }).toList();

          if (isDesktop) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Cari nama produk atau kode SKU...',
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductFormScreen()));
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Produk'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _handleExcelImport,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Unggah Excel'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _handleTemplateDownload,
                        icon: const Icon(Icons.download),
                        label: const Text('Template'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: filteredProducts.isEmpty
                    ? const Center(child: Text('Produk tidak ditemukan.'))
                    : Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[50]),
                                  dataRowMinHeight: 60,
                                  dataRowMaxHeight: 60,
                                  columns: const [
                                    DataColumn(label: Text('Gambar', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Nama Produk', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Harga Jual', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Harga Modal', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Stok', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Kode', style: TextStyle(fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                  rows: filteredProducts.map((product) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          (product.imagePath != null && product.imagePath!.isNotEmpty)
                                              ? (product.imagePath!.startsWith('http')
                                                  ? Image.network(product.imagePath!, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image))
                                                  : Image.file(File(product.imagePath!), width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image)))
                                              : const Icon(Icons.image, size: 40, color: Colors.grey),
                                        ),
                                        DataCell(Text(product.name)),
                                        DataCell(Text(currencyFormatter.format(product.price), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                        DataCell(Text(currencyFormatter.format(product.costPrice ?? 0))),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('${product.stock}'),
                                              if (product.stock <= product.minStock)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 8.0),
                                                  child: Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(4)),
                                                    child: Text('Menipis', style: TextStyle(color: Colors.red[700], fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        DataCell(Text(product.code ?? '-')),
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.qr_code_2, color: Colors.teal, size: 20),
                                                tooltip: 'Bagikan Barcode',
                                                onPressed: () => _shareBarcode(context, product),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                                tooltip: 'Edit Produk',
                                                onPressed: () {
                                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)));
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                                tooltip: 'Hapus Produk',
                                                onPressed: () async {
                                                  final confirm = await showDialog(
                                                    context: context,
                                                    builder: (ctx) => AlertDialog(
                                                      title: const Text('Hapus Produk?'),
                                                      content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                                        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) await provider.deleteProduct(product.id!);
                                                },
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                ),
              ],
            );
          }

              if (filteredProducts.isEmpty) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const Expanded(child: Center(child: Text('Produk tidak ditemukan.'))),
                  ],
                );
              }

              // Mobile View
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                  return ListTile(
                    leading: (product.imagePath != null && product.imagePath!.isNotEmpty)
                        ? (product.imagePath!.startsWith('http://') || product.imagePath!.startsWith('https://')
                            ? Image.network(
                                product.imagePath!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                              )
                            : Image.file(
                                File(product.imagePath!),
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 50),
                              ))
                        : const Icon(Icons.image, size: 50),
                    title: Text(product.name),
                    subtitle: Wrap(
                      spacing: 4,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Stok: ${product.stock}'),
                        if (product.stock <= product.minStock)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              border: Border.all(color: Colors.red[200]!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.warning_amber_rounded, size: 10, color: Colors.red[700]),
                                const SizedBox(width: 2),
                                Text(
                                  'Menipis',
                                  style: TextStyle(color: Colors.red[700], fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        Text(' | Kode: ${product.code ?? "-"}'),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currencyFormatter.format(product.price),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'barcode') {
                              _shareBarcode(context, product);
                            } else if (value == 'edit') {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductFormScreen(product: product),
                                ),
                              );
                            } else if (value == 'delete') {
                              final confirm = await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Hapus Produk?'),
                                  content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Hapus', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirm == true) {
                                await provider.deleteProduct(product.id!);
                              }
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'barcode',
                              child: Row(
                                children: [
                                  Icon(Icons.qr_code_2, color: Colors.teal, size: 20),
                                  SizedBox(width: 8),
                                  Text('Bagikan Barcode'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text('Edit Produk'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red, size: 20),
                                  SizedBox(width: 8),
                                  Text('Hapus Produk', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ),
  );
}

  Future<void> _shareBarcode(BuildContext context, Product product) async {
    if (product.code == null || product.code!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk ini belum memiliki kode barcode. Edit produk untuk membuat kode.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final code = product.code!;
      // Use TEC-IT API for barcode generation (Code128 format)
      final url = 'https://barcode.tec-it.com/barcode.ashx?data=$code&code=Code128&translate-esc=on';
      
      final response = await http.get(Uri.parse(url));
      
      if (mounted) Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/barcode_$code.png');
        await file.writeAsBytes(response.bodyBytes);
        
        final String textMsg = 'Nama Produk: ${product.name}\nKode Barcode: $code';
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: textMsg,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membuat barcode. Pastikan koneksi internet aktif.')),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close loading dialog
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  void _showAddProductMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Tambah & Impor Produk',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.teal,
                      child: Icon(Icons.add_business_rounded, color: Colors.white),
                    ),
                    title: const Text('Tambah Produk Manual'),
                    subtitle: const Text('Input data produk satu per satu'),
                    onTap: () {
                      Navigator.pop(context); // Close bottom sheet
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.file_upload_rounded, color: Colors.white),
                    ),
                    title: const Text('Unggah Massal (Excel)'),
                    subtitle: const Text('Import banyak produk sekaligus dari file .xlsx'),
                    onTap: () async {
                      Navigator.pop(context); // Close bottom sheet
                      await _handleExcelImport();
                    },
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.download_rounded, color: Colors.white),
                    ),
                    title: const Text('Unduh Template Excel'),
                    subtitle: const Text('Unduh format Excel untuk pengisian data awal'),
                    onTap: () async {
                      Navigator.pop(context); // Close bottom sheet
                      await _handleTemplateDownload();
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Panduan Format Excel:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '• Kolom wajib diisi: Nama Produk, Harga Jual, Stok\n'
                          '• Kolom opsional: Harga Modal (default 0), Kode Barcode, Kategori\n'
                          '• Pastikan format file adalah .xlsx',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleTemplateDownload() async {
    try {
      await ExcelImportService.shareTemplate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membagikan template: $e')),
        );
      }
    }
  }

  Future<void> _handleExcelImport() async {
    bool isDialogOpened = false;
    try {
      final products = await ExcelImportService.pickAndParseExcel();
      if (products == null) return; // User cancelled

      if (products.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tidak ada produk valid ditemukan di file Excel.'),
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Mengimpor produk...'),
                ],
              ),
            ),
          ),
        ),
      );
      isDialogOpened = true;

      await Provider.of<ProductProvider>(context, listen: false)
          .addProductsInBatch(products);

      if (isDialogOpened && mounted) {
        Navigator.pop(context);
        isDialogOpened = false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Berhasil mengimpor ${products.length} produk.'),
          ),
        );
      }
    } catch (e) {
      if (isDialogOpened && mounted) {
        Navigator.pop(context);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengimpor produk: $e')),
        );
      }
    }
  }
}
