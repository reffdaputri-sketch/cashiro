import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

class ReceiptService {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  Future<Uint8List> generateReceipt(
    Map<String, dynamic> storeInfo,
    int transactionId,
    double totalAmount,
    double paidAmount,
    double kembalian,
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'Tunai',
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    if (storeInfo['imagePath'] != null && storeInfo['imagePath']!.isNotEmpty) {
      final file = File(storeInfo['imagePath']!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final invoiceNo = 'KSL-$dateStr-${transactionId.toString().padLeft(4, '0')}';

    final subtotal = items.fold<double>(0.0, (sum, item) => sum + (item['total'] as num).toDouble());
    final discount = subtotal - totalAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (logoImage != null)
                pw.Center(
                  child: pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logoImage),
                  ),
                ),
              pw.SizedBox(height: 5),
              pw.Center(child: pw.Text(storeInfo['storeName'] ?? 'Toko', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Center(child: pw.Text(storeInfo['address'] ?? '', style: const pw.TextStyle(fontSize: 10))),
              pw.Center(child: pw.Text(storeInfo['phone'] ?? '', style: const pw.TextStyle(fontSize: 10))),
              pw.Divider(),
              pw.Text('No: $invoiceNo'),
              pw.Text('Tgl: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}'),
              pw.Divider(),
              pw.ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final double itemDiscount = (item['discount'] as num?)?.toDouble() ?? 0.0;
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Expanded(child: pw.Text('${item['name']} x${item['quantity']}')),
                          pw.Text(currencyFormatter.format(item['total'])),
                        ],
                      ),
                      if (itemDiscount > 0.01)
                        pw.Padding(
                          padding: const pw.EdgeInsets.only(left: 10, bottom: 2),
                          child: pw.Text(
                            'Diskon per item: -${currencyFormatter.format(itemDiscount)}',
                            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
                          ),
                        ),
                    ],
                  );
                },
              ),
              pw.Divider(),
              if (discount > 0.01) ...[
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Subtotal'),
                    pw.Text(currencyFormatter.format(subtotal)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Diskon'),
                    pw.Text('- ${currencyFormatter.format(discount)}'),
                  ],
                ),
              ],
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total'),
                  pw.Text(currencyFormatter.format(totalAmount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bayar ($paymentMethod)'),
                  pw.Text(currencyFormatter.format(paidAmount)),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Kembali'),
                  pw.Text(currencyFormatter.format(kembalian)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: invoiceNo,
                  width: 150,
                  height: 40,
                  drawText: true,
                  textStyle: const pw.TextStyle(fontSize: 8),
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Center(child: pw.Text('Terima Kasih', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Formatting strings for 32 character width (standard 58mm printer)
  String _padLeftRight(String left, String right, {int width = 32}) {
    int spaces = width - left.length - right.length;
    if (spaces < 1) spaces = 1;
    return left + (' ' * spaces) + right;
  }

  Future<void> printReceipt(
    Map<String, dynamic> storeInfo,
    int transactionId,
    double totalAmount,
    double paidAmount,
    double kembalian,
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'Tunai',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final printerMac = prefs.getString('printer_mac');
    final directPrint = prefs.getBool('direct_print') ?? true;

    // Jika direct print ON dan mac address printer ada, print ke thermal Bluetooth
    if (directPrint && printerMac != null && printerMac.isNotEmpty) {
      BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
      
      try {
        bool? isConnected = await bluetooth.isConnected;
        
        if (!isConnected!) {
          // Harus buat BluetoothDevice object
          List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
          BluetoothDevice? device;
          try {
            device = devices.firstWhere((d) => d.address == printerMac);
          } catch (e) {
            // Not found in bonded
          }
          
          if (device != null) {
            await bluetooth.connect(device);
          } else {
            throw Exception('Printer $printerMac tidak ditemukan di daftar perangkat yang dipasangkan.');
          }
        }

        final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
        final invoiceNo = 'KSL-$dateStr-${transactionId.toString().padLeft(4, '0')}';
        
        final subtotal = items.fold<double>(0.0, (sum, item) => sum + (item['total'] as num).toDouble());
        final discount = subtotal - totalAmount;

        // Print header
        bluetooth.printCustom(storeInfo['storeName'] ?? 'Toko', 2, 1); // Size 2, Align Center
        if (storeInfo['address'] != null) bluetooth.printCustom(storeInfo['address'], 0, 1);
        if (storeInfo['phone'] != null) bluetooth.printCustom(storeInfo['phone'], 0, 1);
        bluetooth.printNewLine();
        
        bluetooth.printLeftRight("No", invoiceNo, 0);
        bluetooth.printLeftRight("Tgl", DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()), 0);
        bluetooth.printCustom("--------------------------------", 0, 1);
        
        // Print items
        for (var item in items) {
          String nameLine = '${item['name']} x${item['quantity']}';
          String totalLine = currencyFormatter.format(item['total']);
          
          if (nameLine.length > 20) {
            bluetooth.printCustom(nameLine, 0, 0); // Print name on first line
            bluetooth.printLeftRight("", totalLine, 0); // Print total on second line
          } else {
            bluetooth.printLeftRight(nameLine, totalLine, 0);
          }

          final double itemDiscount = (item['discount'] as num?)?.toDouble() ?? 0.0;
          if (itemDiscount > 0.01) {
            bluetooth.printCustom(" Diskon per item: -${currencyFormatter.format(itemDiscount)}", 0, 0);
          }
        }
        
        bluetooth.printCustom("--------------------------------", 0, 1);
        
        // Print totals
        if (discount > 0.01) {
          bluetooth.printLeftRight("Subtotal", currencyFormatter.format(subtotal), 0);
          bluetooth.printLeftRight("Diskon", "- ${currencyFormatter.format(discount)}", 0);
        }
        
        // Total (Size 1 for emphasis)
        bluetooth.printLeftRight("Total", currencyFormatter.format(totalAmount), 1);
        bluetooth.printLeftRight("Bayar ($paymentMethod)", currencyFormatter.format(paidAmount), 0);
        bluetooth.printLeftRight("Kembali", currencyFormatter.format(kembalian), 0);
        
        bluetooth.printNewLine();
        // Nomor resi sudah dicetak di atas, barcode di-skip karena tidak didukung natively oleh blue_thermal_printer versi ini tanpa plugin tambahan.
        
        bluetooth.printNewLine();
        bluetooth.printCustom("Terima Kasih", 1, 1);
        bluetooth.printNewLine();
        bluetooth.printNewLine(); // Extra lines to feed paper out

        // Disconnect after print (optional, but good for stability on cheap printers)
        // await bluetooth.disconnect(); 

        return;
      } catch (e) {
        debugPrint('Direct thermal print failed: $e');
        // Fallback ke PDF UI jika error koneksi bluetooth
      }
    }

    // Fallback: Tampilkan preview PDF
    final pdfBytes = await generateReceipt(storeInfo, transactionId, totalAmount, paidAmount, kembalian, items, paymentMethod: paymentMethod);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Struk-#$transactionId',
    );
  }

  Future<void> shareReceipt(
    Map<String, dynamic> storeInfo,
    int transactionId,
    double totalAmount,
    double paidAmount,
    double kembalian,
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'Tunai',
  }) async {
    final pdfBytes = await generateReceipt(storeInfo, transactionId, totalAmount, paidAmount, kembalian, items, paymentMethod: paymentMethod);
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Struk-$transactionId.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Struk Belanja - ${storeInfo['storeName'] ?? 'Toko'} (ID: $transactionId)\nTotal: ${currencyFormatter.format(totalAmount)}',
    );
  }
}
