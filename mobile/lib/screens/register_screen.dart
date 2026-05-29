import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class RegisterScreen extends StatefulWidget {
  final String? prefilledLicenseKey;
  final String? prefilledEmail;
  final String? prefilledStoreName;

  const RegisterScreen({
    super.key,
    this.prefilledLicenseKey,
    this.prefilledEmail,
    this.prefilledStoreName,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _licenseKeyController;
  late final TextEditingController _emailController;
  late final TextEditingController _storeNameController;
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pinController = TextEditingController();
  final _referralCodeController = TextEditingController();
  final _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _licenseKeyController = TextEditingController(text: widget.prefilledLicenseKey ?? '');
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
    _storeNameController = TextEditingController(text: widget.prefilledStoreName ?? '');
  }

  @override
  void dispose() {
    _licenseKeyController.dispose();
    _emailController.dispose();
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pinController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }
  
  File? _imageFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final licenseKey = _licenseKeyController.text.trim();
    final email = _emailController.text.trim();
    final storeName = _storeNameController.text.trim();
    final ownerName = _ownerNameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final rawPin = _pinController.text.trim();
    final referralCode = _referralCodeController.text.trim();
    final pinHash = AuthService().hashPin(rawPin);
    String storeId = '';

    try {
      // Offline/Mock Bypass option
      if (licenseKey.startsWith('KSL-MOCK-')) {
        storeId = 'MOCK-STORE-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Online register using Next.js proxy
        final result = await _apiService.registerStore(
          licenseKey: licenseKey,
          email: email,
          storeName: storeName,
          ownerName: ownerName,
          phone: phone,
          address: address,
          pin: pinHash,
          referralCode: referralCode.isNotEmpty ? referralCode : null,
        );
        storeId = result['store_id'];
      }

      if (mounted) {
        await Provider.of<AuthProvider>(context, listen: false).register(
          storeName: storeName,
          ownerName: ownerName,
          phone: phone,
          address: address,
          imagePath: _imageFile?.path,
          pin: pinHash,
          storeId: storeId,
          licenseKey: licenseKey,
          email: email,
        );
        
        await _showDatabaseModeDialog(context);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Registrasi & Aktivasi Lisensi Berhasil!')),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registrasi Gagal: $e')),
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

  Future<void> _showDatabaseModeDialog(BuildContext context) async {
    final primaryColor = Theme.of(context).primaryColor;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.storage, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Pilih Mode Database',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tentukan bagaimana Anda ingin mengelola data transaksi toko Anda:',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              
              // Option 1: Offline First
              Card(
                elevation: 0,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Icon(Icons.phone_android, color: Colors.blue.shade800, size: 36),
                  title: Text('Offline First (Lokal)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                  subtitle: const Text('Simpan di memori internal HP. Cepat, hemat data internet. Sinkronisasi otomatis ke cloud dimatikan (dapat Anda nyalakan kapan saja dari Pengaturan).', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    await Provider.of<AuthProvider>(context, listen: false).updateCloudSyncEnabled(false);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
              ),
              const SizedBox(height: 12),
              
              // Option 2: Cloud Sync
              Card(
                elevation: 0,
                color: Colors.green.shade50,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Icon(Icons.cloud_queue, color: Colors.green.shade800, size: 36),
                  title: Text('Cloud Sync (Otomatis)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                  subtitle: const Text('Otomatis menyinkronkan seluruh data transaksi ke cloud server setiap 30 detik secara aman. Sangat direkomendasikan jika Anda memiliki banyak perangkat.', style: TextStyle(fontSize: 11)),
                  onTap: () async {
                    await Provider.of<AuthProvider>(context, listen: false).updateCloudSyncEnabled(true);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi & Aktivasi Toko'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Photo picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.08),
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryColor.withOpacity(0.3), width: 2),
                            image: _imageFile != null
                                ? DecorationImage(image: FileImage(_imageFile!), fit: BoxFit.cover)
                                : null,
                          ),
                          child: _imageFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 32, color: primaryColor.withOpacity(0.5)),
                                    const SizedBox(height: 4),
                                    Text('Foto Toko', style: TextStyle(fontSize: 11, color: primaryColor.withOpacity(0.8))),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Section: Lisensi
                    _sectionLabel('Informasi Lisensi', primaryColor),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licenseKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Lisensi Cashiro',
                        hintText: 'CSH-XXXX-XXXX',
                        prefixIcon: Icon(Icons.vpn_key),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Harap isi kode lisensi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Email Lisensi',
                        prefixIcon: Icon(Icons.email),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Harap isi email';
                        if (!value.contains('@')) return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Section: Toko
                    _sectionLabel('Detail Toko', primaryColor),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _storeNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko',
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Harap isi nama toko' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Pemilik',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Harap isi nama pemilik' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Nomor Telepon',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty ? 'Harap isi nomor telepon' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Alamat Toko',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      maxLines: 2,
                      validator: (value) => value == null || value.isEmpty ? 'Harap isi alamat' : null,
                    ),
                    const SizedBox(height: 24),

                    // Section: Keamanan
                    _sectionLabel('Keamanan', primaryColor),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pinController,
                      decoration: const InputDecoration(
                        labelText: 'PIN Masuk / Transaksi',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      validator: (value) => (value == null || value.length < 4) ? 'PIN minimal 4 digit' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _referralCodeController,
                      decoration: const InputDecoration(
                        labelText: 'Kode Referral (Opsional)',
                        hintText: 'CSH-XXXX-XXXX',
                        prefixIcon: Icon(Icons.card_giftcard),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Aktifkan & Daftar Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text, Color primaryColor) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: primaryColor,
      ),
    );
  }
}
