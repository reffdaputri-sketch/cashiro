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
import 'package:image/image.dart' as img;

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
    double taxAmount = 0.0,
    double serviceChargeAmount = 0.0,
    double? taxPercentage,
    String? cashierName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final footerText = prefs.getString('receipt_footer_text') ?? 'Terima Kasih';
    final showLogo = prefs.getBool('receipt_show_logo') ?? true;
    final showStoreName = prefs.getBool('receipt_show_store_name') ?? true;
    final showAddress = prefs.getBool('receipt_show_address') ?? true;
    final showPhone = prefs.getBool('receipt_show_phone') ?? true;
    final showDate = prefs.getBool('receipt_show_date') ?? true;
    final showTransactionId = prefs.getBool('receipt_show_transaction_id') ?? true;

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
    final discount = subtotal - totalAmount + taxAmount + serviceChargeAmount;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll57,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (showLogo && logoImage != null)
                pw.Center(
                  child: pw.Container(
                    height: 60,
                    width: 60,
                    child: pw.Image(logoImage),
                  ),
                ),
              if (showLogo && logoImage != null) pw.SizedBox(height: 5),
              if (showStoreName) pw.Center(child: pw.Text(storeInfo['storeName'] ?? 'Toko', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              if (showAddress) pw.Center(child: pw.Text(storeInfo['address'] ?? '', style: const pw.TextStyle(fontSize: 10))),
              if (showPhone) pw.Center(child: pw.Text(storeInfo['phone'] ?? '', style: const pw.TextStyle(fontSize: 10))),
              if (showStoreName || showAddress || showPhone || showLogo) pw.Divider(),
              if (showTransactionId) pw.Text('No: $invoiceNo'),
              if (showDate) pw.Text('Tgl: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}'),
              if (cashierName != null && cashierName.isNotEmpty) pw.Text('Kasir: $cashierName'),
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
                  children: [pw.Text('Subtotal'), pw.Text(currencyFormatter.format(subtotal))],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('Diskon'), pw.Text('- ${currencyFormatter.format(discount)}')],
                ),
              ],
              if (taxAmount > 0.01)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text(taxPercentage != null ? 'Pajak (${taxPercentage == taxPercentage.toInt() ? taxPercentage.toInt() : taxPercentage}%)' : 'Pajak'), pw.Text('+ ${currencyFormatter.format(taxAmount)}')],
                ),
              if (serviceChargeAmount > 0.01)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [pw.Text('Service Charge'), pw.Text('+ ${currencyFormatter.format(serviceChargeAmount)}')],
                ),
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
              if (showTransactionId)
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
              if (showTransactionId) pw.SizedBox(height: 10),
              if (footerText.isNotEmpty) pw.Center(child: pw.Text(footerText, style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.center)),
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
    double taxAmount = 0.0,
    double serviceChargeAmount = 0.0,
    double? taxPercentage,
    String? cashierName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final printerMac = prefs.getString('printer_mac');
    final directPrint = prefs.getBool('direct_print') ?? true;
    
    final footerText = prefs.getString('receipt_footer_text') ?? 'Terima Kasih';
    final showLogo = prefs.getBool('receipt_show_logo') ?? true;
    final showStoreName = prefs.getBool('receipt_show_store_name') ?? true;
    final showAddress = prefs.getBool('receipt_show_address') ?? true;
    final showPhone = prefs.getBool('receipt_show_phone') ?? true;
    final showDate = prefs.getBool('receipt_show_date') ?? true;
    final showTransactionId = prefs.getBool('receipt_show_transaction_id') ?? true;

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
        final discount = subtotal - totalAmount + taxAmount + serviceChargeAmount;

        // Print logo (jika ada)
        if (showLogo && storeInfo['imagePath'] != null && (storeInfo['imagePath'] as String).isNotEmpty) {
          final logoFile = File(storeInfo['imagePath'] as String);
          if (await logoFile.exists()) {
            try {
              final logoBytes = await logoFile.readAsBytes();
              // Resize image agar tidak terlalu besar di kertas struk (max width ~200px untuk 58mm printer)
              final img.Image? decodedImage = img.decodeImage(logoBytes);
              if (decodedImage != null) {
                // Hardcode ukuran ke lebar 200px (tinggi proporsional)
                final int targetWidth = 200;
                final img.Image resizedImage = img.copyResize(decodedImage, width: targetWidth);
                
                // Kertas 58mm biasanya memiliki lebar cetak sekitar 384 dots (pixel).
                // Kita buat kanvas putih berukuran 384 x tinggi_gambar agar bisa memposisikan gambar di tengah (center).
                final int printerWidth = 384;
                final img.Image centeredCanvas = img.Image(width: printerWidth, height: resizedImage.height);
                
                // Isi kanvas dengan warna putih
                img.fill(centeredCanvas, color: img.ColorRgb8(255, 255, 255));
                
                // Hitung posisi X agar gambar berada di tengah
                final int xPos = (printerWidth - targetWidth) ~/ 2;
                
                // Gambar ulang logo yang sudah di-resize ke atas kanvas putih di posisi tengah
                img.compositeImage(centeredCanvas, resizedImage, dstX: xPos, dstY: 0);

                // Convert kembali ke bytes (format PNG)
                final Uint8List finalBytes = Uint8List.fromList(img.encodePng(centeredCanvas));
                
                await bluetooth.printImageBytes(finalBytes);
                bluetooth.printNewLine();
              }
            } catch (e) {
              debugPrint('Gagal cetak logo: $e');
              // Lanjut cetak meski logo gagal
            }
          }
        }

        // Print header
        if (showStoreName) bluetooth.printCustom(storeInfo['storeName'] ?? 'Toko', 2, 1); // Size 2, Align Center
        if (showAddress && storeInfo['address'] != null) bluetooth.printCustom(storeInfo['address'], 0, 1);
        if (showPhone && storeInfo['phone'] != null) bluetooth.printCustom(storeInfo['phone'], 0, 1);
        if (showStoreName || showAddress || showPhone || showLogo) bluetooth.printNewLine();
        
        if (showTransactionId) bluetooth.printLeftRight("No", invoiceNo, 0);
        if (showDate) bluetooth.printLeftRight("Tgl", DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()), 0);
        if (cashierName != null && cashierName.isNotEmpty) bluetooth.printLeftRight("Kasir", cashierName, 0);
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
        if (taxAmount > 0.01) {
          String taxLabel = taxPercentage != null ? "Pajak (${taxPercentage == taxPercentage.toInt() ? taxPercentage.toInt() : taxPercentage}%)" : "Pajak";
          bluetooth.printLeftRight(taxLabel, "+ ${currencyFormatter.format(taxAmount)}", 0);
        }
        if (serviceChargeAmount > 0.01) {
          bluetooth.printLeftRight("Service Charge", "+ ${currencyFormatter.format(serviceChargeAmount)}", 0);
        }
        
        // Total (Size 1 for emphasis)
        bluetooth.printLeftRight("Total", currencyFormatter.format(totalAmount), 1);
        bluetooth.printLeftRight("Bayar ($paymentMethod)", currencyFormatter.format(paidAmount), 0);
        bluetooth.printLeftRight("Kembali", currencyFormatter.format(kembalian), 0);
        
        bluetooth.printNewLine();
        // Nomor resi sudah dicetak di atas, barcode di-skip karena tidak didukung natively oleh blue_thermal_printer versi ini tanpa plugin tambahan.
        
        bluetooth.printNewLine();
        if (footerText.isNotEmpty) {
          bluetooth.printCustom(footerText, 1, 1);
          bluetooth.printNewLine();
        }
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
    final pdfBytes = await generateReceipt(
      storeInfo, transactionId, totalAmount, paidAmount, kembalian, items, 
      paymentMethod: paymentMethod, taxAmount: taxAmount, serviceChargeAmount: serviceChargeAmount,
      taxPercentage: taxPercentage, cashierName: cashierName
    );
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
    double taxAmount = 0.0,
    double serviceChargeAmount = 0.0,
    double? taxPercentage,
    String? cashierName,
  }) async {
    final pdfBytes = await generateReceipt(
      storeInfo, transactionId, totalAmount, paidAmount, kembalian, items, 
      paymentMethod: paymentMethod, taxAmount: taxAmount, serviceChargeAmount: serviceChargeAmount,
      taxPercentage: taxPercentage, cashierName: cashierName
    );
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Struk-$transactionId.pdf');
    await file.writeAsBytes(pdfBytes);
    
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Struk Belanja - ${storeInfo['storeName'] ?? 'Toko'} (ID: $transactionId)\nTotal: ${currencyFormatter.format(totalAmount)}',
    );
  }
}
