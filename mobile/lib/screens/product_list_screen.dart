import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/screens/product_form_screen.dart';
import 'package:mobile/services/excel_import_service.dart';
import 'package:intl/intl.dart';

import 'dart:io';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manajemen Produk'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductMenu(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<ProductProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.products.isEmpty) {
            return const Center(child: Text('Belum ada produk.'));
          }
          return ListView.builder(
            itemCount: provider.products.length,
            itemBuilder: (context, index) {
              final product = provider.products[index];
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
                    Text(currencyFormatter.format(product.price)),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductFormScreen(product: product),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
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
                                child: const Text('Hapus'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await provider.deleteProduct(product.id!);
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
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
