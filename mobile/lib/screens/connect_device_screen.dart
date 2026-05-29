import 'package:flutter/material.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/sync_service.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';

class ConnectDeviceScreen extends StatefulWidget {
  const ConnectDeviceScreen({super.key});

  @override
  State<ConnectDeviceScreen> createState() => _ConnectDeviceScreenState();
}

class _ConnectDeviceScreenState extends State<ConnectDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _licenseKeyController = TextEditingController();
  final _apiService = ApiService();
  final _syncService = SyncService();

  bool _isLoading = false;
  String _loadingMessage = '';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _loadingMessage = 'Memverifikasi lisensi Anda...';
    });

    final email = _emailController.text.trim();
    final licenseKey = _licenseKeyController.text.trim();

    try {
      Map<String, dynamic> storeData;

      // 1. Authenticate with License + Email
      if (licenseKey.startsWith('KSL-MOCK-')) {
        // Simulated mock offline validation
        storeData = {
          'store_id': 'MOCK-STORE-ID',
          'store_name': 'Toko Mock Offline',
          'owner_name': 'Owner Mock',
          'phone': '0812345678',
          'address': 'Alamat Mock',
          'pin': '123456',
        };
      } else {
        final result = await _apiService.loginWithLicense(
          email: email,
          licenseKey: licenseKey,
        );
        storeData = result['store'];
      }

      // 2. Download synced cloud database
      setState(() {
        _loadingMessage = 'Mengunduh data transaksi & produk dari cloud...';
      });

      final storeId = storeData['store_id'] ?? 'MOCK-STORE-ID';
      
      // If not mock, sync down from Supabase
      if (!licenseKey.startsWith('KSL-MOCK-')) {
        await _syncService.downloadAllCloudData(storeId, licenseKey);
      }

      // 3. Register the store info locally in SharedPreferences
      if (mounted) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        await authProvider.register(
          storeName: storeData['store_name'] ?? 'Toko',
          ownerName: storeData['owner_name'] ?? 'Pemilik',
          phone: storeData['phone'] ?? '',
          address: storeData['address'] ?? '',
          imagePath: storeData['image_path'],
          pin: storeData['pin'] ?? '123456',
          storeId: storeId,
          licenseKey: licenseKey,
          email: email,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device berhasil terhubung & data tersinkronisasi!')),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Koneksi Gagal: $e')),
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
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hubungkan Device Baru'),
      ),
      body: _isLoading
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _loadingMessage,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.sync_alt, size: 60, color: primaryColor),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Sinkronisasi Toko',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Masukkan email & kode lisensi yang terdaftar untuk mengunduh seluruh data produk, stok, dan transaksi toko Anda ke device ini.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email Terdaftar',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Harap isi email';
                        if (!value.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // License Key Field
                    TextFormField(
                      controller: _licenseKeyController,
                      decoration: InputDecoration(
                        labelText: 'Kode Lisensi Cashiro',
                        hintText: 'CSH-XXXX-XXXX',
                        prefixIcon: const Icon(Icons.vpn_key),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Harap isi kode lisensi' : null,
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _submit,
                        child: const Text('Hubungkan & Sinkronkan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
