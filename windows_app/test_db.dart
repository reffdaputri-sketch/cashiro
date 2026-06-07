import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  // Use same path as DatabaseService
  String path = join(await databaseFactory.getDatabasesPath(), 'cashiro.db');
  
  print('DB path: $path');
  var db = await databaseFactory.openDatabase(path);
  
  var version = await db.getVersion();
  print('DB version: $version');
  
  // Print products table schema
  var result = await db.rawQuery("PRAGMA table_info('products')");
  print('products table columns:');
  for (var row in result) {
    print('  ${row['name']} (${row['type']})');
  }

  // Print product_bundles schema
  result = await db.rawQuery("PRAGMA table_info('product_bundles')");
  print('product_bundles table columns:');
  for (var row in result) {
    print('  ${row['name']} (${row['type']})');
  }
  
  await db.close();
}
