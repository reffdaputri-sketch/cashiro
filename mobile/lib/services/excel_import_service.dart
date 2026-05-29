import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/models/product.dart';
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
    ]);
    
    // Contoh Data
    sheet.appendRow([
      TextCellValue('Kopi Susu Gula Aren'),
      IntCellValue(18000),
      IntCellValue(12000),
      IntCellValue(100),
      TextCellValue('8990123456789'),
      TextCellValue('Minuman'),
    ]);
    
    sheet.appendRow([
      TextCellValue('Roti Bakar Coklat'),
      IntCellValue(15000),
      IntCellValue(9000),
      IntCellValue(50),
      TextCellValue('8990123456780'),
      TextCellValue('Makanan'),
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

        products.add(Product(
          name: name,
          price: price,
          costPrice: costPrice,
          stock: stock,
          code: code,
          category: category,
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

  static int _getIntValue(CellValue? value) {
    if (value == null) return 0;
    if (value is IntCellValue) return value.value;
    if (value is DoubleCellValue) return value.value.round();
    
    // Strip trailing .0 if present
    String valStr = value.toString().trim();
    if (valStr.endsWith('.0')) {
      valStr = valStr.substring(0, valStr.length - 2);
    }
    return int.tryParse(valStr) ?? 0;
  }
}
