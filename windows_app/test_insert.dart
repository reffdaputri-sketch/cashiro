import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  String path = join(await databaseFactory.getDatabasesPath(), 'cashiro.db');
  
  var db = await databaseFactory.openDatabase(path);
  
  try {
    await db.insert('products', {
      'name': 'Test',
      'price': 1000,
      'stock': 10,
      'code': '123',
      'created_at': DateTime.now().toIso8601String(),
      'cost_price': 0.0,
      'category': 'test',
      'min_stock': 5,
      'is_online': 0,
      'weight': 0,
      'is_deleted': 0,
      'is_bundle': 0,
      'supplier_id': null,
      'is_synced': 0
    });
    print('Insert successful!');
  } catch (e) {
    print('INSERT ERROR: \$e');
  }
  
  await db.close();
}
