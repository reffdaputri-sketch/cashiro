import 'package:mobile/services/database_service.dart';
import 'package:mobile/services/api_service.dart';
import 'package:mobile/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class SyncService {
  final DatabaseService _dbService = DatabaseService();
  final ApiService _apiService = ApiService();
  final AuthService _authService = AuthService();

  final List<String> _syncTables = [
    'categories',
    'products',
    'product_variations',
    'shifts',
    'transactions',
    'transaction_items',
    'expenses',
    'customers',
    'staff',
    'debt_payments'
  ];

  /// Uploads all unsynced data from local SQLite to Supabase via Next.js
  Future<void> uploadLocalChanges() async {
    final storeInfo = await _authService.getStoreInfo();
    final storeId = storeInfo['storeId'];
    final licenseKey = storeInfo['licenseKey'];

    if (storeId == null || storeId.isEmpty || storeId == 'DEMO-STORE-ID') return;

    final db = await _dbService.database;
    bool allSynced = true;

    for (final table in _syncTables) {
      try {
        // Query unsynced rows
        final List<Map<String, dynamic>> unsyncedRows = await db.query(
          table,
          where: 'is_synced = 0',
        );

        if (unsyncedRows.isEmpty) continue;

        // Prepare payloads
        final List<Map<String, dynamic>> syncItems = [];
        for (final row in unsyncedRows) {
          final mutableRow = Map<String, dynamic>.from(row);
          mutableRow.remove('is_synced');

          if (table == 'products') {
            final String? localPath = row['image_path'] as String?;
            if (localPath != null && localPath.isNotEmpty &&
                !localPath.startsWith('http://') && !localPath.startsWith('https://')) {
              debugPrint('Sync: Uploading local image to Cloudinary: $localPath');
              final String? cloudinaryUrl = await _apiService.uploadImage(
                filePath: localPath,
                storeId: storeId,
                licenseKey: licenseKey!,
              );
              if (cloudinaryUrl != null) {
                debugPrint('Sync: Image uploaded successfully: $cloudinaryUrl');
                await db.update(
                  'products',
                  {'image_path': cloudinaryUrl},
                  where: 'id = ?',
                  whereArgs: [row['id']],
                );
                mutableRow['image_path'] = cloudinaryUrl;
              }
            }
          }

          syncItems.add({
            'entity_type': table,
            'local_id': row['id'],
            'payload': mutableRow,
          });
        }

        // Send to Next.js API proxy
        final success = await _apiService.uploadSync(
          storeId: storeId,
          licenseKey: licenseKey!,
          syncItems: syncItems,
        );

        if (success) {
          // Mark as synced locally
          await db.update(
            table,
            {'is_synced': 1},
            where: 'id IN (${unsyncedRows.map((r) => r['id']).join(',')})',
          );
          debugPrint('Sync: Uploaded ${unsyncedRows.length} rows for $table');
        } else {
          allSynced = false;
        }
      } catch (e) {
        allSynced = false;
        debugPrint('Sync: Error uploading $table: $e');
      }
    }

    if (allSynced) {
      DatabaseService.hasUnsyncedChanges = false;
      debugPrint('Sync: All local changes are fully uploaded and synced.');
    }
  }

  /// Downloads all cloud data for this store and inserts it into local SQLite.
  /// Used during new device login to populate local DB.
  Future<void> downloadAllCloudData(String storeId, String licenseKey) async {
    final db = await _dbService.database;

    try {
      final List<Map<String, dynamic>> cloudData = await _apiService.downloadSync(
        storeId: storeId,
        licenseKey: licenseKey,
      );

      if (cloudData.isEmpty) return;

      // Group items by table/entity_type
      final Map<String, List<Map<String, dynamic>>> groupedData = {};
      for (final item in cloudData) {
        final table = item['entity_type'] as String;
        groupedData.putIfAbsent(table, () => []).add(item);
      }

      // Insert/update into local SQLite in transaction to ensure safety
      await db.transaction((txn) async {
        for (final table in _syncTables) {
          final items = groupedData[table];
          if (items == null || items.isEmpty) continue;

          for (final item in items) {
            final localId = item['local_id'] as int;
            final payload = Map<String, dynamic>.from(item['payload']);
            
            // Mark downloaded items as already synced locally
            payload['is_synced'] = 1;

            // Check if row already exists
            final existing = await txn.query(
              table,
              where: 'id = ?',
              whereArgs: [localId],
              limit: 1,
            );

            if (existing.isNotEmpty) {
              await txn.update(
                table,
                payload,
                where: 'id = ?',
                whereArgs: [localId],
              );
            } else {
              await txn.insert(
                table,
                payload,
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
          debugPrint('Sync: Downloaded & applied ${items.length} rows for $table');
        }
      });
    } catch (e) {
      debugPrint('Sync: Error downloading cloud data: $e');
      rethrow;
    }
  }
}
