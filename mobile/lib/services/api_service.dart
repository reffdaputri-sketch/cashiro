import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Untuk production: 'https://cashiro.vercel.app'
  // Untuk testing di device Android (ganti IP sesuai IP PC kamu di WiFi):
  // Cek IP: jalankan `ipconfig` di terminal, lihat IPv4 Address
  // Untuk emulator: gunakan http://10.0.2.2:3000
  static const String baseUrl = 'https://cashiro.vercel.app';

  /// Sends a request to Duitku payment gateway via Next.js to buy a license
  Future<Map<String, dynamic>> buyLicense(String email, String storeName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/license/buy'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'store_name': storeName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = _parseError(response.body);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('buyLicense Error: $e');
      rethrow;
    }
  }

  /// Checks if a license has been generated for a specific email
  Future<String?> checkLicenseStatus(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/license/status?email=${Uri.encodeComponent(email)}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['license_key'];
      }
      return null;
    } catch (e) {
      debugPrint('checkLicenseStatus Error: $e');
      return null;
    }
  }

  /// Registers a store and activates the license key
  Future<Map<String, dynamic>> registerStore({
    required String licenseKey,
    required String email,
    required String storeName,
    required String ownerName,
    required String phone,
    required String address,
    required String pin,
    String? referralCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/license/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'license_key': licenseKey,
          'email': email,
          'store_name': storeName,
          'owner_name': ownerName,
          'phone': phone,
          'address': address,
          'pin': pin,
          if (referralCode != null && referralCode.isNotEmpty) 'referral_code': referralCode,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = _parseError(response.body);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('registerStore Error: $e');
      rethrow;
    }
  }

  /// Log in and verify email & license key
  Future<Map<String, dynamic>> loginWithLicense({
    required String email,
    required String licenseKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/license/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'license_key': licenseKey,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = _parseError(response.body);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('loginWithLicense Error: $e');
      rethrow;
    }
  }

  /// Uploads SQLite sync data payloads to Supabase via Next.js proxy
  Future<bool> uploadSync({
    required String storeId,
    required String licenseKey,
    required List<Map<String, dynamic>> syncItems,
  }) async {
    if (syncItems.isEmpty) return true;

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'store_id': storeId,
          'license_key': licenseKey,
          'sync_items': syncItems,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('uploadSync Error: $e');
      return false;
    }
  }

  /// Downloads synced data payloads from Supabase via Next.js proxy
  Future<List<Map<String, dynamic>>> downloadSync({
    required String storeId,
    required String licenseKey,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sync/download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'store_id': storeId,
          'license_key': licenseKey,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Download sync failed with code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('downloadSync Error: $e');
      rethrow;
    }
  }

  String _parseError(String body) {
    try {
      final json = jsonDecode(body);
      return json['error'] ?? json['message'] ?? 'Terjadi kesalahan pada server';
    } catch (_) {
      return 'Gagal memproses data di server';
    }
  }

  /// Uploads a local image file to Next.js API proxy which uploads to Cloudinary
  Future<String?> uploadImage({
    required String filePath,
    required String storeId,
    required String licenseKey,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('uploadImage: File does not exist at $filePath');
        return null;
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/sync/upload-image'),
      );

      request.fields['store_id'] = storeId;
      request.fields['license_key'] = licenseKey;

      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          filePath,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> result = jsonDecode(response.body);
        return result['url'];
      } else {
        debugPrint('uploadImage failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('uploadImage Error: $e');
      return null;
    }
  }

  /// Updates the store profile details (and optionally PIN) on the cloud
  Future<Map<String, dynamic>> updateStoreProfile({
    required String storeId,
    required String licenseKey,
    required String storeName,
    required String ownerName,
    required String phone,
    required String address,
    required String? pin,
    int? cityId,
    String? bankName,
    String? bankAccount,
    String? bankAccountName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/license/update-profile'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'store_id': storeId,
          'license_key': licenseKey,
          'store_name': storeName,
          'owner_name': ownerName,
          'phone': phone,
          'address': address,
          'pin': pin,
          'city_id': cityId,
          'bank_name': bankName,
          'bank_account': bankAccount,
          'bank_account_name': bankAccountName,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorMsg = _parseError(response.body);
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('updateStoreProfile Error: $e');
      rethrow;
    }
  }

  // ─────────────────────────────────────────
  // SELLER LANDING PAGE API
  // ─────────────────────────────────────────

  /// Mengambil data provinsi / kota dari API RajaOngkir (via proxy)
  Future<List<dynamic>> getRajaOngkirLocations({String type = 'province', String? provinceId}) async {
    try {
      String url = '$baseUrl/api/rajaongkir/location?type=$type';
      if (provinceId != null) {
        url += '&province=$provinceId';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('getRajaOngkirLocations Error: $e');
      rethrow;
    }
  }

  /// Aktivasi / ambil slug landing page seller
  Future<Map<String, dynamic>> activateSeller(String storeId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'store_id': storeId}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('activateSeller Error: $e');
      rethrow;
    }
  }

  /// Ambil info seller + daftar produk landing page
  Future<Map<String, dynamic>> getSellerInfo(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sellers/$slug'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('getSellerInfo Error: $e');
      rethrow;
    }
  }

  /// Ambil semua produk seller (termasuk yang nonaktif) untuk dashboard
  Future<Map<String, dynamic>> getSellerProducts(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sellers/$slug/products'));
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('getSellerProducts Error: $e');
      rethrow;
    }
  }

  /// Tambah produk ke landing page seller
  Future<Map<String, dynamic>> addSellerProduct({
    required String slug,
    required String storeId,
    required String name,
    required String description,
    required double price,
    required int stock,
    String imageUrl = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/$slug/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'store_id': storeId,
          'name': name,
          'description': description,
          'price': price,
          'stock': stock,
          'image_url': imageUrl,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('addSellerProduct Error: $e');
      rethrow;
    }
  }

  /// Update produk landing page
  Future<Map<String, dynamic>> updateSellerProduct({
    required String slug,
    required String storeId,
    required int productId,
    String? name,
    String? description,
    double? price,
    int? stock,
    String? imageUrl,
    bool? isActive,
  }) async {
    try {
      final body = <String, dynamic>{'store_id': storeId, 'product_id': productId};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (price != null) body['price'] = price;
      if (stock != null) body['stock'] = stock;
      if (imageUrl != null) body['image_url'] = imageUrl;
      if (isActive != null) body['is_active'] = isActive;

      final response = await http.put(
        Uri.parse('$baseUrl/api/sellers/$slug/products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('updateSellerProduct Error: $e');
      rethrow;
    }
  }

  /// Ambil daftar order masuk dari landing page
  Future<List<dynamic>> getSellerOrders(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sellers/$slug/orders'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['orders'] ?? [];
      }
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('getSellerOrders Error: $e');
      rethrow;
    }
  }

  /// Cek saldo seller
  Future<double> getSellerBalance(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sellers/$slug/balance'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['balance'] ?? 0).toDouble();
      }
      return 0;
    } catch (e) {
      debugPrint('getSellerBalance Error: $e');
      return 0;
    }
  }

  /// Withdraw seller balance (full amount or specified)
  Future<void> withdrawSeller(String slug, double amount) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/$slug/withdraw'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );
      if (response.statusCode != 200) {
        throw Exception(_parseError(response.body));
      }
    } catch (e) {
      debugPrint('withdrawSeller Error: $e');
      rethrow;
    }
  }

  /// Withdraw referral commission (minimum 50000)
  Future<void> withdrawCommission(String slug, double amount) async {
    if (amount < 50000) {
      throw Exception('Minimum withdrawal is Rp 50.000');
    }
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sellers/$slug/withdraw-commission'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'amount': amount}),
      );
      if (response.statusCode != 200) {
        throw Exception(_parseError(response.body));
      }
    } catch (e) {
      debugPrint('withdrawCommission Error: $e');
      rethrow;
    }
  }
  Future<Map<String, dynamic>> getSellerReferrals(String slug) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/sellers/$slug/referrals'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      throw Exception(_parseError(response.body));
    } catch (e) {
      debugPrint('getSellerReferrals Error: $e');
      rethrow;
    }
  }
}

