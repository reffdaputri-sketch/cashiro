import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/edit_store_screen.dart';
import 'package:mobile/screens/expense_screen.dart';
import 'package:mobile/screens/printer_settings_screen.dart';
import 'package:mobile/screens/receipt_settings_screen.dart';
import 'package:mobile/screens/tax_settings_screen.dart';
import 'package:mobile/screens/theme_settings_screen.dart';
import 'package:mobile/services/backup_service.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:mobile/services/database_service.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SyncService _syncService = SyncService();
  int _unsyncedCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUnsyncedCount();
  }

  Future<void> _loadUnsyncedCount() async {
    final count = await _syncService.countUnsyncedChanges();
    if (mounted) {
      setState(() {
        _unsyncedCount = count;
      });
    }
  }

  Future<void> _handleUploadSync(AuthProvider auth) async {
    final storeInfo = auth.storeInfo;
    final storeId = storeInfo['storeId'];

    if (storeId == null || storeId.isEmpty || storeId == 'DEMO-STORE-ID') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur sinkronisasi tidak aktif untuk akun Demo/Offline.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.uploadLocalChanges();
      await _loadUnsyncedCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sinkronisasi upload ke cloud berhasil!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal melakukan sinkronisasi upload: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDownloadSync(AuthProvider auth) async {
    final storeInfo = auth.storeInfo;
    final storeId = storeInfo['storeId'];
    final licenseKey = storeInfo['licenseKey'];

    if (storeId == null || storeId.isEmpty || storeId == 'DEMO-STORE-ID') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur sinkronisasi tidak aktif untuk akun Demo/Offline.')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tarik Data dari Cloud?'),
        content: const Text(
          'Tindakan ini akan mengunduh semua data transaksi, produk, dan pengaturan toko Anda dari cloud, lalu menyelaraskannya dengan data lokal di perangkat ini. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Tarik Data'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _syncService.downloadAllCloudData(storeId, licenseKey!);
      await _loadUnsyncedCount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Berhasil menarik dan memperbarui data dari cloud!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menarik data dari cloud: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final info = auth.storeInfo;
    final imagePath = info['imagePath'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditStoreScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: (imagePath != null && imagePath.isNotEmpty)
                        ? FileImage(File(imagePath))
                        : null,
                    child: (imagePath == null || imagePath.isEmpty)
                        ? const Icon(Icons.store, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 20),
                  if (info['storeName'] != null)
                    Text(info['storeName']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    secondary: const Icon(Icons.restaurant_menu, color: Colors.orange),
                    title: const Text('Mode Restoran / F&B'),
                    subtitle: const Text('Matikan untuk mode kasir ritel biasa'),
                    value: auth.isFnbMode,
                    onChanged: (bool value) async {
                      await auth.updateFnbMode(value);
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.settings, color: Colors.blueGrey),
                    title: const Text('Pengaturan Toko'),
                    subtitle: const Text('Ubah nama, alamat, dan logo toko'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const EditStoreScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.print, color: Colors.black87),
                    title: const Text('Pengaturan Printer'),
                    subtitle: const Text('Hubungkan printer thermal Bluetooth'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PrinterSettingsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.receipt_long, color: Colors.indigo),
                    title: const Text('Pengaturan Desain Nota'),
                    subtitle: const Text('Atur logo, teks, dan tampilan struk'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ReceiptSettingsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.calculate, color: Colors.teal),
                    title: const Text('Pengaturan Pajak & Layanan'),
                    subtitle: const Text('Atur PPN dan Service Charge otomatis'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TaxSettingsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.color_lens, color: Colors.orange),
                    title: const Text('Tampilan & Tema'),
                    subtitle: const Text('Ubah warna utama aplikasi'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ThemeSettingsScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.backup, color: Colors.blue),
                    title: const Text('Backup Database'),
                    trailing: const Icon(Icons.download, size: 20),
                    onTap: () async {
                      final backupService = BackupService();
                      await backupService.exportDatabase(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.restore, color: Colors.orange),
                    title: const Text('Restore Database'),
                    trailing: const Icon(Icons.upload, size: 20),
                    onTap: () async {
                      final backupService = BackupService();
                      await backupService.importDatabase(context);
                    },
                  ),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Sinkronisasi Cloud', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ),
                  SwitchListTile(
                    secondary: const Icon(Icons.sync_lock, color: Colors.teal),
                    title: const Text('Sinkronisasi Cloud Otomatis'),
                    subtitle: const Text('Cadangkan data secara otomatis setiap menit'),
                    value: auth.cloudSyncEnabled,
                    onChanged: (bool value) async {
                      await auth.updateCloudSyncEnabled(value);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_upload, color: Colors.blue),
                    title: const Text('Upload Sync ke Cloud'),
                    subtitle: const Text('Kirim semua perubahan lokal ke cloud secara manual'),
                    trailing: _unsyncedCount > 0
                        ? Chip(
                            label: Text('$_unsyncedCount data', style: const TextStyle(color: Colors.white, fontSize: 11)),
                            backgroundColor: Colors.orange,
                            padding: EdgeInsets.zero,
                          )
                        : const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    onTap: () => _handleUploadSync(auth),
                  ),
                  ListTile(
                    leading: const Icon(Icons.cloud_download, color: Colors.green),
                    title: const Text('Tarik Data dari Cloud'),
                    subtitle: const Text('Unduh data produk dan transaksi dari cloud'),
                    trailing: const Icon(Icons.download_for_offline, color: Colors.green, size: 20),
                    onTap: () => _handleDownloadSync(auth),
                  ),
                  ListTile(
                    leading: const Icon(Icons.playlist_add, color: Colors.purple),
                    title: const Text('Generate Demo Data'),
                    subtitle: const Text('Tambah 15 produk contoh (Random)'),
                    onTap: () async {
                      final type = await showDialog<String>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Pilih Jenis Toko'),
                          content: const Text('Pilih jenis data demo yang ingin ditambahkan:'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx, 'sembako'), child: const Text('Sembako')),
                            TextButton(onPressed: () => Navigator.pop(ctx, 'fnb'), child: const Text('F&B')),
                            TextButton(onPressed: () => Navigator.pop(ctx, 'retail'), child: const Text('Retail')),
                            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (type != null) {
                        await Provider.of<ProductProvider>(context, listen: false).generateDemoData(type);
                        await _loadUnsyncedCount();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data demo berhasil ditambahkan!')));
                        }
                      }
                    },
                  ),
                  const Divider(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Reset Semua Data?'),
                            content: const Text(
                              'PERINGATAN: Ini akan menghapus SELURUH data lokal di perangkat ini (produk, transaksi, dll). Data yang belum disinkronkan ke cloud akan hilang secara permanen. Lanjutkan?',
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('Ya, Reset'),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            final dbService = DatabaseService();
                            await dbService.clearAllData();
                            await _loadUnsyncedCount();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua data lokal berhasil dihapus.')));
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal mereset data: $e')));
                            }
                          } finally {
                            if (mounted) {
                              setState(() {
                                _isLoading = false;
                              });
                            }
                          }
                        }
                      },
                      child: const Text('Hapus Seluruh Data Lokal'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                      onPressed: () async {
                        await Provider.of<AuthProvider>(context, listen: false).logout();
                      },
                      child: const Text('Keluar Akun'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Card(
                  margin: EdgeInsets.all(32),
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Sedang melakukan sinkronisasi cloud...',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

