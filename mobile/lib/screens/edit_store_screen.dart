import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:mobile/services/api_service.dart';


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
  File? _imageFile;
  String? _currentImagePath;
  
  List<dynamic> _provinces = [];
  List<dynamic> _cities = [];
  String? _selectedProvinceId;
  String? _selectedCityId;
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final info = auth.storeInfo;
    _storeNameController = TextEditingController(text: info['storeName'] ?? '');
    _ownerNameController = TextEditingController(text: info['ownerName'] ?? '');
    _phoneController = TextEditingController(text: info['phone'] ?? '');
    _addressController = TextEditingController(text: info['address'] ?? '');
    _currentImagePath = info['imagePath'];
    
    final cityIdStr = info['cityId'];
    if (cityIdStr != null && cityIdStr.isNotEmpty) {
      _selectedCityId = cityIdStr;
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
      // If we have a selectedCityId from initial data, we might need to fetch cities for its province
      // But we don't know the province ID of the city unless we search through all cities or assume the user will just see the city ID.
      // To keep it simple, we'll just show the provinces. If they want to edit city, they have to re-select province.
    } catch (e) {
      debugPrint('Failed to load provinces: $e');
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



  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await Provider.of<AuthProvider>(context, listen: false).updateStore(
        _storeNameController.text,
        _ownerNameController.text,
        _phoneController.text,
        _addressController.text,
        _imageFile?.path ?? _currentImagePath,
        cityId: _selectedCityId != null ? int.tryParse(_selectedCityId!) : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil toko berhasil diperbarui')),
        );
        Navigator.pop(context);
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
              const Text('Lokasi Pengiriman (Untuk Ongkir)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (_isLoadingLocation && _provinces.isEmpty)
                const Center(child: CircularProgressIndicator())
              else
                DropdownButtonFormField<String>(
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
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Simpan Perubahan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
