import 'package:flutter/material.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/models/staff.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final DatabaseService _db = DatabaseService();
  final ApiService _apiService = ApiService();
  bool _isRegistered = false;
  bool _isAuthenticated = false;
  bool _cloudSyncEnabled = true;
  Staff? _currentStaff;
  Map<String, String> _storeInfo = {};

  bool get isRegistered => _isRegistered;
  bool get isAuthenticated => _isAuthenticated;
  bool get cloudSyncEnabled => _cloudSyncEnabled;
  Staff? get currentStaff => _currentStaff;
  bool get isOwner => _isAuthenticated && _currentStaff == null;
  Map<String, String> get storeInfo => _storeInfo;

  Future<void> checkRegistration() async {
    _isRegistered = await _authService.isRegistered();
    if (_isRegistered) {
      _storeInfo = await _authService.getStoreInfo();
      _cloudSyncEnabled = await _authService.isCloudSyncEnabled();
    }
  }

  Future<bool> login(String pin) async {
    // 1. Check Owner PIN
    final isOwnerResult = await _authService.verifyOwnerPin(pin);
    if (isOwnerResult) {
      _currentStaff = null;
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    // 2. Check Staff PIN
    final staffMap = await _db.getStaffByPin(pin);
    if (staffMap != null) {
      _currentStaff = Staff.fromMap(staffMap);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    }

    return false;
  }

  bool hasPermission(String permission) {
    if (isOwner) return true;
    if (_currentStaff == null) return false;
    return _currentStaff!.permissions.contains(permission);
  }

  Future<bool> verifyPin(String pin) async {
    return await _authService.verifyOwnerPin(pin);
  }

  Future<void> register({
    required String storeName,
    required String ownerName,
    required String phone,
    required String address,
    required String? imagePath,
    required String pin,
    required String storeId,
    required String licenseKey,
    required String email,
  }) async {
    await _authService.register(
      storeName: storeName,
      ownerName: ownerName,
      phone: phone,
      address: address,
      imagePath: imagePath,
      pin: pin,
      storeId: storeId,
      licenseKey: licenseKey,
      email: email,
    );
    await checkRegistration();
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> loginDemo() async {
    await _authService.register(
      storeName: 'Toko Demo',
      ownerName: 'User Demo',
      phone: '081234567890',
      address: 'Jl. Contoh No. 123',
      imagePath: null,
      pin: '123456',
      storeId: 'DEMO-STORE-ID',
      licenseKey: 'DEMO-LICENSE-KEY',
      email: 'demo@kiosly.com',
    );
    await checkRegistration();
    _isAuthenticated = true;
    notifyListeners();
  }

  Future<void> updateStore(String storeName, String ownerName, String phone, String address, String? imagePath, {int? cityId}) async {
    await _authService.updateStoreInfo(storeName, ownerName, phone, address, imagePath, cityId: cityId);
    await checkRegistration();
    
    // Update in cloud if online (license key is not mock)
    final storeId = _storeInfo['storeId'];
    final licenseKey = _storeInfo['licenseKey'];
    if (storeId != null && storeId.isNotEmpty && licenseKey != null && !licenseKey.startsWith('KSL-MOCK-')) {
      try {
        await _apiService.updateStoreProfile(
          storeId: storeId,
          licenseKey: licenseKey,
          storeName: storeName,
          ownerName: ownerName,
          phone: phone,
          address: address,
          pin: null, // do not update PIN here
          cityId: cityId,
        );
      } catch (e) {
        debugPrint('Cloud profile update failed: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updatePin(String newPin) async {
    final pinHash = _authService.hashPin(newPin);
    await _authService.updatePin(pinHash);
    
    // Update in cloud if online (license key is not mock)
    final storeId = _storeInfo['storeId'];
    final licenseKey = _storeInfo['licenseKey'];
    if (storeId != null && storeId.isNotEmpty && licenseKey != null && !licenseKey.startsWith('KSL-MOCK-')) {
      try {
        await _apiService.updateStoreProfile(
          storeId: storeId,
          licenseKey: licenseKey,
          storeName: _storeInfo['storeName'] ?? '',
          ownerName: _storeInfo['ownerName'] ?? '',
          phone: _storeInfo['phone'] ?? '',
          address: _storeInfo['address'] ?? '',
          pin: pinHash, // Pass new PIN hash to update
        );
      } catch (e) {
        debugPrint('Cloud PIN hash update failed: $e');
      }
    }
    notifyListeners();
  }

  Future<void> updateCloudSyncEnabled(bool enabled) async {
    await _authService.setCloudSyncEnabled(enabled);
    _cloudSyncEnabled = enabled;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _isRegistered = false;
    _isAuthenticated = false;
    _currentStaff = null;
    _storeInfo = {};
    _cloudSyncEnabled = true;
    notifyListeners();
  }
}
