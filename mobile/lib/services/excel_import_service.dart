import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/models/product.dart';
import 'package:mobile/models/product_variation.dart';
import 'package:mobile/models/product_bundle_item.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExcelImportService {
  static Future<void> shareTemplate() async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];
    
    // Header
    sheet.appendRow([
      TextCellValue('Nama Produk'),
      TextCellValue('Harga Jual'),
      TextCellValue('Harga Modal'),
      TextCellValue('Stok'),
      TextCellValue('Kode Barcode'),
      TextCellValue('Kategori'),
      TextCellValue('Minimal Stok'),
      TextCellValue('Berat (gram)'),
      TextCellValue('Jual Online (Y/N)'),
      TextCellValue('Tanpa Batas Stok (Y/N)'),
      TextCellValue('Tipe Produk (Normal/Bundle)'),
      TextCellValue('Variasi (Nama:Harga:Stok:SKU|...)'),
      TextCellValue('Item Bundle (Kode_atau_Nama:Qty|...)'),
    ]);
    
    // Contoh Data Normal
    sheet.appendRow([
      TextCellValue('Kopi Susu Gula Aren'),
      IntCellValue(18000),
      IntCellValue(12000),
      IntCellValue(100),
      TextCellValue('8990123456789'),
      TextCellValue('Minuman'),
      IntCellValue(5),
      IntCellValue(0),
      TextCellValue('Y'),
      TextCellValue('N'),
      TextCellValue('Normal'),
      TextCellValue(''),
      TextCellValue(''),
    ]);
    
    // Contoh Data dengan Variasi
    sheet.appendRow([
      TextCellValue('Kaos Polos Kiosly'),
      IntCellValue(50000),
      IntCellValue(35000),
      IntCellValue(0),
      TextCellValue(''),
      TextCellValue('Pakaian'),
      IntCellValue(5),
      IntCellValue(200),
      TextCellValue('Y'),
      TextCellValue('N'),
      TextCellValue('Normal'),
      TextCellValue('Ukuran M:50000:10:KP-M|Ukuran L:55000:15:KP-L'),
      TextCellValue(''),
    ]);

    // Contoh Data Bundle
    sheet.appendRow([
      TextCellValue('Paket Ngopi Hemat'),
      IntCellValue(30000),
      IntCellValue(21000),
      IntCellValue(50),
      TextCellValue('PKG-001'),
      TextCellValue('Paket'),
      IntCellValue(5),
      IntCellValue(0),
      TextCellValue('Y'),
      TextCellValue('N'),
      TextCellValue('Bundle'),
      TextCellValue(''),
      TextCellValue('8990123456789:1|Roti Bakar Coklat:1'),
    ]);

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/template_kiosly.xlsx');
      await tempFile.writeAsBytes(fileBytes);
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Template Import Produk Kiosly',
        text: 'Gunakan template ini untuk mengimpor produk secara massal ke aplikasi Kiosly.',
      );
    }
  }

  static Future<List<Product>?> pickAndParseExcel() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final bytes = await File(result.files.single.path!).readAsBytes();
    final excel = Excel.decodeBytes(bytes);
    final List<Product> products = [];

    for (var table in excel.tables.keys) {
      final sheet = excel.tables[table];
      if (sheet == null || sheet.rows.isEmpty) continue;

      // Skip the header (row 0)
      for (int i = 1; i < sheet.rows.length; i++) {
        final row = sheet.rows[i];
        if (row.isEmpty) continue;

        // Extract values using helper to avoid nulls/type casting errors
        final String name = _getStringValue(row.isNotEmpty ? row[0]?.value : null);
        if (name.isEmpty) continue; // Nama produk wajib ada

        final double price = _getDoubleValue(row.length > 1 ? row[1]?.value : null);
        final double costPrice = _getDoubleValue(row.length > 2 ? row[2]?.value : null);
        final int stock = _getIntValue(row.length > 3 ? row[3]?.value : null);
        
        // Handle barcode as string
        String? code;
        if (row.length > 4 && row[4]?.value != null) {
          code = _getStringValue(row[4]?.value);
          if (code.isEmpty) code = null;
        }

        String? category;
        if (row.length > 5 && row[5]?.value != null) {
          category = _getStringValue(row[5]?.value);
          if (category.isEmpty) category = null;
        }

        final int minStock = _getIntValue(row.length > 6 ? row[6]?.value : null, defaultVal: 5);
        final int weight = _getIntValue(row.length > 7 ? row[7]?.value : null);
        final bool isOnline = _getStringValue(row.length > 8 ? row[8]?.value : null).toUpperCase() == 'Y';
        final bool isUnlimited = _getStringValue(row.length > 9 ? row[9]?.value : null).toUpperCase() == 'Y';
        final bool isBundle = _getStringValue(row.length > 10 ? row[10]?.value : null).toUpperCase() == 'BUNDLE';
        
        final String variasiStr = _getStringValue(row.length > 11 ? row[11]?.value : null);
        final String bundleStr = _getStringValue(row.length > 12 ? row[12]?.value : null);

        List<ProductVariation> variations = [];
        if (variasiStr.isNotEmpty) {
          final parts = variasiStr.split('|');
          for (var p in parts) {
            final vData = p.split(':');
            if (vData.isNotEmpty) {
              final vName = vData[0].trim();
              final vPrice = vData.length > 1 ? double.tryParse(vData[1].trim()) ?? price : price;
              final vStock = vData.length > 2 ? int.tryParse(vData[2].trim()) ?? 0 : 0;
              final vSku = vData.length > 3 ? vData[3].trim() : null;
              
              if (vName.isNotEmpty) {
                variations.add(ProductVariation(
                  name: vName,
                  price: vPrice,
                  stock: vStock,
                  sku: (vSku?.isEmpty ?? true) ? null : vSku,
                ));
              }
            }
          }
        }

        List<ProductBundleItem> bundleItems = [];
        if (isBundle && bundleStr.isNotEmpty) {
          final parts = bundleStr.split('|');
          for (var p in parts) {
            final bData = p.split(':');
            if (bData.isNotEmpty) {
              final bCodeOrName = bData[0].trim();
              final bQty = bData.length > 1 ? int.tryParse(bData[1].trim()) ?? 1 : 1;
              if (bCodeOrName.isNotEmpty) {
                bundleItems.add(ProductBundleItem(
                  itemProductId: 0, // Temp until ProductProvider resolves it
                  itemName: bCodeOrName,
                  quantity: bQty,
                ));
              }
            }
          }
        }

        products.add(Product(
          name: name,
          price: price,
          costPrice: costPrice,
          stock: stock,
          code: code,
          category: category,
          minStock: minStock,
          weight: weight,
          isOnline: isOnline,
          isUnlimited: isUnlimited,
          isBundle: isBundle,
          variations: variations,
          bundleItems: bundleItems,
          createdAt: DateTime.now(),
        ));
      }
    }

    return products;
  }

  static String _getStringValue(CellValue? value) {
    if (value == null) return '';
    // Format double strings from cells without decimals if they represent integers (e.g. barcode)
    String valStr = value.toString().trim();
    if (valStr.endsWith('.0')) {
      valStr = valStr.substring(0, valStr.length - 2);
    }
    return valStr;
  }

  static double _getDoubleValue(CellValue? value) {
    if (value == null) return 0.0;
    if (value is DoubleCellValue) return value.value;
    if (value is IntCellValue) return value.value.toDouble();
    return double.tryParse(value.toString().trim()) ?? 0.0;
  }

  static int _getIntValue(CellValue? value, {int defaultVal = 0}) {
    if (value == null) return defaultVal;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.round();
    
    // Strip trailing .0 if present
    String valStr = value.toString().trim();
    if (valStr.isEmpty) return defaultVal;
    if (valStr.endsWith('.0')) {
      valStr = valStr.substring(0, valStr.length - 2);
    }
    return int.tryParse(valStr) ?? defaultVal;
  }
}
