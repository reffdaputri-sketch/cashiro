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
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showDatabaseModeDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.storage, color: Colors.indigo, size: 24),
              SizedBox(width: 10),
              Expanded(
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

  InputDecoration _inputDeco(String label, IconData icon, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: const Color(0xFF1A1A2E).withOpacity(0.7), fontSize: 14),
      hintStyle: TextStyle(color: const Color(0xFF1A1A2E).withOpacity(0.4), fontSize: 14),
      filled: true,
      fillColor: const Color(0xFFF0F2F8),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF3F51B5), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF3F51B5).withOpacity(0.7), size: 20),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Registrasi & Aktivasi Toko',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 18,
                color: Color(0xFF1A1A2E))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF3F51B5)),
                  const SizedBox(height: 16),
                  Text('Mendaftarkan toko...',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Photo picker ──
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                                color: Colors.indigo.withOpacity(0.15),
                                width: 2),
                            image: _imageFile != null
                                ? DecorationImage(
                                    image: FileImage(_imageFile!),
                                    fit: BoxFit.cover)
                                : null,
                          ),
                          child: _imageFile == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded,
                                        size: 32,
                                        color: Colors.indigo.withOpacity(0.4)),
                                    const SizedBox(height: 4),
                                    Text('Foto Toko',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                Colors.indigo.withOpacity(0.5),
                                            fontWeight: FontWeight.w500)),
                                  ],
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Section: Lisensi ──
                    _sectionLabel('Informasi Lisensi'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _licenseKeyController,
                      decoration:
                          _inputDeco('Kode Lisensi Cashiro', Icons.vpn_key_rounded,
                              hint: 'CSH-XXXX-XXXX'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Harap isi kode lisensi'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          _inputDeco('Alamat Email Lisensi', Icons.email_rounded),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Harap isi email';
                        }
                        if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Toko ──
                    _sectionLabel('Detail Toko'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _storeNameController,
                      decoration:
                          _inputDeco('Nama Toko', Icons.store_rounded),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Harap isi nama toko'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _ownerNameController,
                      decoration:
                          _inputDeco('Nama Pemilik', Icons.person_rounded),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Harap isi nama pemilik'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _phoneController,
                      decoration:
                          _inputDeco('Nomor Telepon', Icons.phone_rounded),
                      keyboardType: TextInputType.phone,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Harap isi nomor telepon'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _addressController,
                      decoration:
                          _inputDeco('Alamat Toko', Icons.location_on_rounded),
                      maxLines: 2,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Harap isi alamat'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // ── Section: Keamanan ──
                    _sectionLabel('Keamanan'),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pinController,
                      decoration: _inputDeco(
                          'PIN Masuk / Transaksi', Icons.lock_rounded),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      maxLength: 6,
                      validator: (value) => (value == null || value.length < 4)
                          ? 'PIN minimal 4 digit'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _referralCodeController,
                      decoration: _inputDeco(
                          'Kode Referral (Opsional)', Icons.card_giftcard_rounded,
                          hint: 'CSH-XXXX-XXXX'),
                    ),
                    const SizedBox(height: 32),

                    // ── Submit Button ──
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3F51B5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Aktifkan & Daftar Toko',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFF3F51B5),
        letterSpacing: 0.5,
      ),
    );
  }
}
