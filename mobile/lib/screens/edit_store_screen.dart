import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/screens/qris_scanner_screen.dart';
import 'dart:convert';
import 'package:mobile/screens/purchase_license_screen.dart';


class EditStoreScreen extends StatefulWidget {
  const EditStoreScreen({super.key});

  @override
  State<EditStoreScreen> createState() => _EditStoreScreenState();
}

class _EditStoreScreenState extends State<EditStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _storeNameController;
  late TextEditingController _ownerNameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _bankNameController;
  late TextEditingController _bankAccountController;
  late TextEditingController _bankAccountNameController;
  late TextEditingController _qrisPayloadController;
  File? _imageFile;
  String? _currentImagePath;
  
  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];
  String? _selectedProvinceId;
  String? _selectedCityId;
  bool _isLoadingLocation = false;
  
  List<String> _currentBanners = [];
  List<File> _newBannerFiles = [];
  bool _isUploadingBanners = false;
  bool _isLocalCourierActive = false;
  late TextEditingController _localCourierFeeController;
  double? _storeLat;
  double? _storeLng;
  late TextEditingController _maxDeliveryRadiusController;
  bool _isFetchingLocation = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final info = auth.storeInfo;
    _storeNameController = TextEditingController(text: info['storeName'] ?? '');
    _ownerNameController = TextEditingController(text: info['ownerName'] ?? '');
    _phoneController = TextEditingController(text: info['phone'] ?? '');
    _addressController = TextEditingController(text: info['address'] ?? '');
    _bankNameController = TextEditingController(text: info['bankName'] ?? '');
    _bankAccountController = TextEditingController(text: info['bankAccount'] ?? '');
    _bankAccountNameController = TextEditingController(text: info['bankAccountName'] ?? '');
    _qrisPayloadController = TextEditingController(text: info['qrisPayload'] ?? '');
    _currentImagePath = info['imagePath'];
    _isLocalCourierActive = info['isLocalCourierActive'] == 'true';
    _localCourierFeeController = TextEditingController(text: info['localCourierFee'] ?? '0.0');
    _storeLat = double.tryParse(info['storeLat'] ?? '');
    _storeLng = double.tryParse(info['storeLng'] ?? '');
    _maxDeliveryRadiusController = TextEditingController(text: info['maxDeliveryRadius'] ?? '0.0');
    
    final cityIdStr = info['cityId'];
    if (cityIdStr != null && cityIdStr.isNotEmpty) {
      _selectedCityId = cityIdStr;
    }
    
    final bannersJson = info['banners'];
    if (bannersJson != null && bannersJson.isNotEmpty) {
      try {
        _currentBanners = List<String>.from(jsonDecode(bannersJson));
      } catch (e) {
        debugPrint('Failed to parse banners: $e');
      }
    }
    
    _fetchProvinces();
  }

  Future<void> _fetchProvinces() async {
    setState(() => _isLoadingLocation = true);
    try {
      final data = await ApiService().getRajaOngkirLocations(type: 'province');
      setState(() {
        _provinces = data;
      });
      
      if (_selectedCityId != null && _selectedCityId!.isNotEmpty) {
        final allCities = await ApiService().getRajaOngkirLocations(type: 'city');
        final currentCity = allCities.cast<Map<String, dynamic>>().firstWhere(
          (c) => c['city_id'].toString() == _selectedCityId, 
          orElse: () => <String, dynamic>{}
        );
        
        if (currentCity.isNotEmpty) {
          final provId = currentCity['province_id'].toString();
          setState(() {
            _selectedProvinceId = provId;
            _cities = allCities.where((c) => c['province_id'].toString() == provId).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Failed to load provinces/cities: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _fetchCities(String provinceId) async {
    setState(() {
      _isLoadingLocation = true;
      _cities = [];
      _selectedCityId = null;
    });
    try {
      final data = await ApiService().getRajaOngkirLocations(type: 'city', provinceId: provinceId);
      setState(() {
        _cities = data;
      });
    } catch (e) {
      debugPrint('Failed to load cities: $e');
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    _qrisPayloadController.dispose();
    _localCourierFeeController.dispose();
    _maxDeliveryRadiusController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickBanner() async {
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _newBannerFiles.addAll(pickedFiles.map((pf) => File(pf.path)));
      });
    }
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
          'Anda sedang menggunakan Akun Demo. Untuk dapat mengubah profil toko Anda sendiri, silakan beli lisensi Cashiro.',
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

  Future<void> _submit() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.isDemo) {
      _showDemoLockedDialog();
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() => _isUploadingBanners = true);
      
      final info = auth.storeInfo;
      final storeId = info['storeId'] ?? '';
      final licenseKey = info['licenseKey'] ?? '';
      
      List<String> finalBanners = List.from(_currentBanners);
      
      if (_newBannerFiles.isNotEmpty && storeId.isNotEmpty && licenseKey.isNotEmpty) {
        for (var file in _newBannerFiles) {
          final url = await ApiService().uploadImage(
            filePath: file.path, 
            storeId: storeId, 
            licenseKey: licenseKey
          );
          if (url != null) {
            finalBanners.add(url);
          }
        }
      }
      
      await auth.updateStore(
        _storeNameController.text,
        _ownerNameController.text,
        _phoneController.text,
        _addressController.text,
        _imageFile?.path ?? _currentImagePath,
        cityId: _selectedCityId != null ? int.tryParse(_selectedCityId!) : null,
        bankName: _bankNameController.text,
        bankAccount: _bankAccountController.text,
        bankAccountName: _bankAccountNameController.text,
        qrisPayload: _qrisPayloadController.text,
        banners: finalBanners,
        isLocalCourierActive: _isLocalCourierActive,
        localCourierFee: double.tryParse(_localCourierFeeController.text) ?? 0.0,
        storeLat: _storeLat,
        storeLng: _storeLng,
        maxDeliveryRadius: double.tryParse(_maxDeliveryRadiusController.text) ?? 0.0,
      );
      if (mounted) {
        setState(() => _isUploadingBanners = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil toko berhasil diperbarui')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif.');
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak secara permanen.');
      }
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _storeLat = position.latitude;
        _storeLng = position.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lokasi berhasil didapatkan!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mendapatkan lokasi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Toko')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : (_currentImagePath != null && _currentImagePath!.isNotEmpty
                                    ? FileImage(File(_currentImagePath!))
                                    : null),
                            child: (_imageFile == null && (_currentImagePath == null || _currentImagePath!.isEmpty))
                                ? const Icon(Icons.store, size: 60, color: Colors.grey)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Ganti Logo Toko', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Banner Toko (Slider Landing Page)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_currentBanners.isNotEmpty || _newBannerFiles.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._currentBanners.asMap().entries.map((entry) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 8),
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(image: NetworkImage(entry.value), fit: BoxFit.cover),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _currentBanners.removeAt(entry.key));
                              },
                            ),
                          ),
                        ],
                      )),
                      ..._newBannerFiles.asMap().entries.map((entry) => Stack(
                        alignment: Alignment.topRight,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(right: 8, top: 8),
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(image: FileImage(entry.value), fit: BoxFit.cover),
                            ),
                          ),
                          Container(
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () {
                                setState(() => _newBannerFiles.removeAt(entry.key));
                              },
                            ),
                          ),
                        ],
                      )),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickBanner,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Tambah Banner'),
              ),
              const SizedBox(height: 24),
              // License Information Card
              Consumer<AuthProvider>(
                builder: (context, authProvider, _) {
                  final info = authProvider.storeInfo;
                  final licenseKey = info['licenseKey'] ?? '-';
                  final email = info['email'] ?? '-';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade800, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.vpn_key, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Informasi Lisensi Toko',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const Divider(color: Colors.white24, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'KODE LISENSI',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    licenseKey,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Colors.white70),
                              tooltip: 'Salin Lisensi',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: licenseKey));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Kode lisensi disalin ke clipboard')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'EMAIL TERDAFTAR',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              TextFormField(
                controller: _storeNameController,
                decoration: const InputDecoration(labelText: 'Nama Toko'),
                validator: (value) => value!.isEmpty ? 'Harap isi nama toko' : null,
              ),
              TextFormField(
                controller: _ownerNameController,
                decoration: const InputDecoration(labelText: 'Nama Pemilik'),
                validator: (value) => value!.isEmpty ? 'Harap isi nama pemilik' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
                validator: (value) => value!.isEmpty ? 'Harap isi nomor telepon' : null,
              ),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Alamat Lengkap'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Harap isi alamat' : null,
              ),
              const SizedBox(height: 16),
              const Text('Pengaturan Kurir Lokal', style: TextStyle(fontWeight: FontWeight.bold)),
              SwitchListTile(
                title: const Text('Aktifkan Kurir Lokal'),
                subtitle: const Text('Jika aktif, kurir RajaOngkir akan disembunyikan di Toko Online.'),
                value: _isLocalCourierActive,
                onChanged: (bool value) {
                  setState(() {
                    _isLocalCourierActive = value;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              if (_isLocalCourierActive) ...[
                TextFormField(
                  controller: _localCourierFeeController,
                  decoration: const InputDecoration(labelText: 'Biaya Kurir Lokal (Rp)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxDeliveryRadiusController,
                  decoration: const InputDecoration(labelText: 'Radius Pengiriman Maksimal (Km)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _isFetchingLocation ? null : _getCurrentLocation,
                  icon: _isFetchingLocation 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.location_on),
                  label: Text(_isFetchingLocation ? 'Mengambil Lokasi...' : 'Ambil Lokasi Toko (GPS)'),
                ),
                if (_storeLat != null && _storeLng != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text('Lokasi tersimpan: $_storeLat, $_storeLng', style: const TextStyle(color: Colors.green, fontSize: 12)),
                  ),
                const SizedBox(height: 24),
              ],
              if (!_isLocalCourierActive) ...[
                const Text('Lokasi Pengiriman (Untuk Ongkir)', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_isLoadingLocation && _provinces.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _selectedProvinceId,
                    decoration: const InputDecoration(labelText: 'Provinsi', border: OutlineInputBorder()),
                    items: _provinces.map((p) => DropdownMenuItem<String>(
                      value: p['province_id'].toString(),
                      child: Text(p['province']),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedProvinceId = val);
                        _fetchCities(val);
                      }
                    },
                  ),
                const SizedBox(height: 16),
                if (_isLoadingLocation && _provinces.isNotEmpty)
                  const Center(child: CircularProgressIndicator())
                else if (_cities.isNotEmpty || _selectedCityId != null)
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _cities.any((c) => c['city_id'].toString() == _selectedCityId) ? _selectedCityId : null,
                    decoration: const InputDecoration(labelText: 'Kota / Kabupaten', border: OutlineInputBorder()),
                    items: _cities.map((c) => DropdownMenuItem<String>(
                      value: c['city_id'].toString(),
                      child: Text("${c['type']} ${c['city_name']}"),
                    )).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCityId = val);
                      }
                    },
                    hint: _selectedCityId != null && _cities.isEmpty 
                        ? Text('Kota ID: $_selectedCityId (Pilih ulang provinsi)') 
                        : null,
                  ),
                const SizedBox(height: 24),
              ],
              const Text('Informasi Rekening Bank (Untuk Pembayaran Online)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bankNameController,
                decoration: const InputDecoration(labelText: 'Nama Bank (contoh: BCA, Mandiri)'),
              ),
              TextFormField(
                controller: _bankAccountController,
                decoration: const InputDecoration(labelText: 'Nomor Rekening'),
                keyboardType: TextInputType.number,
              ),
              TextFormField(
                controller: _bankAccountNameController,
                decoration: const InputDecoration(labelText: 'Atas Nama (A.N)'),
              ),
              const SizedBox(height: 24),
              const Text('Integrasi QRIS (Untuk Pembayaran Online & POS)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qrisPayloadController,
                      decoration: const InputDecoration(
                        labelText: 'QRIS Payload (Teks Mentah QRIS)',
                        hintText: 'Bisa didapat dari scan stiker QRIS',
                      ),
                      maxLines: 2,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QrisScannerScreen()),
                      );
                      if (result != null && result is String) {
                        setState(() {
                          _qrisPayloadController.text = result;
                        });
                      }
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploadingBanners ? null : _submit,
                child: _isUploadingBanners 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
