import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class AuthService {
  static const String KEY_IS_REGISTERED = 'is_registered';
  static const String KEY_STORE_NAME = 'store_name';
  static const String KEY_OWNER_NAME = 'owner_name';
  static const String KEY_PHONE = 'phone';
  static const String KEY_ADDRESS = 'address';
  static const String KEY_STORE_IMAGE = 'store_image';
  static const String KEY_PIN = 'pin';
  static const String KEY_STORE_ID = 'store_id';
  static const String KEY_LICENSE_KEY = 'license_key';
  static const String KEY_EMAIL = 'email';

  Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_IS_REGISTERED) ?? false;
  }

  String hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> verifyOwnerPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPinHash = prefs.getString(KEY_PIN);
    if (storedPinHash == null) return false;
    
    // Backward compatibility: If the stored value is not a SHA-256 hash (64 hex characters), compare directly
    if (storedPinHash.length != 64) {
      return storedPinHash == pin;
    }
    
    return storedPinHash == hashPin(pin);
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_STORE_NAME, storeName);
    await prefs.setString(KEY_OWNER_NAME, ownerName);
    await prefs.setString(KEY_PHONE, phone);
    await prefs.setString(KEY_ADDRESS, address);
    if (imagePath != null) await prefs.setString(KEY_STORE_IMAGE, imagePath);
    // Hash PIN if it is not already hashed (64 chars length)
    final pinHash = pin.length == 64 ? pin : hashPin(pin);
    await prefs.setString(KEY_PIN, pinHash);
    await prefs.setString(KEY_STORE_ID, storeId);
    await prefs.setString(KEY_LICENSE_KEY, licenseKey);
    await prefs.setString(KEY_EMAIL, email);
    await prefs.setBool(KEY_IS_REGISTERED, true);
  }

  Future<Map<String, String>> getStoreInfo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'storeName': prefs.getString(KEY_STORE_NAME) ?? '',
      'ownerName': prefs.getString(KEY_OWNER_NAME) ?? '',
      'phone': prefs.getString(KEY_PHONE) ?? '',
      'address': prefs.getString(KEY_ADDRESS) ?? '',
      'imagePath': prefs.getString(KEY_STORE_IMAGE) ?? '',
      'storeId': prefs.getString(KEY_STORE_ID) ?? '',
      'licenseKey': prefs.getString(KEY_LICENSE_KEY) ?? '',
      'email': prefs.getString(KEY_EMAIL) ?? '',
    };
  }

  Future<void> updateStoreInfo(String storeName, String ownerName, String phone, String address, String? imagePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(KEY_STORE_NAME, storeName);
    await prefs.setString(KEY_OWNER_NAME, ownerName);
    await prefs.setString(KEY_PHONE, phone);
    await prefs.setString(KEY_ADDRESS, address);
    if (imagePath != null) await prefs.setString(KEY_STORE_IMAGE, imagePath);
  }

  Future<void> updatePin(String newPin) async {
    final prefs = await SharedPreferences.getInstance();
    final pinHash = newPin.length == 64 ? newPin : hashPin(newPin);
    await prefs.setString(KEY_PIN, pinHash);
  }

  static const String KEY_CLOUD_SYNC_ENABLED = 'cloud_sync_enabled';

  Future<bool> isCloudSyncEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(KEY_CLOUD_SYNC_ENABLED) ?? true;
  }

  Future<void> setCloudSyncEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(KEY_CLOUD_SYNC_ENABLED, enabled);
  }

  Future<void> logout() async {
     final prefs = await SharedPreferences.getInstance();
     await prefs.clear();
  }
}
