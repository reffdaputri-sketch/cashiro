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

class ReceiptService {
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
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Load store logo if available
    pw.MemoryImage? logoImage;
    if (storeInfo['imagePath'] != null && storeInfo['imagePath']!.isNotEmpty) {
      final file = File(storeInfo['imagePath']!);
      if (await file.exists()) {
        final bytes = await file.readAsBytes();
        logoImage = pw.MemoryImage(bytes);
      }
    }

    // Generate formatted invoice number (long format for dense barcode)
    final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
    final invoiceNo = 'KSL-$dateStr-${transactionId.toString().padLeft(4, '0')}';

    // Calculate subtotal and discount dynamically
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
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${item['name']} x${item['quantity']}')),
                      pw.Text(currencyFormatter.format(item['total'])),
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

  Future<void> printReceipt(
    Map<String, dynamic> storeInfo,
    int transactionId,
    double totalAmount,
    double paidAmount,
    double kembalian,
    List<Map<String, dynamic>> items, {
    String paymentMethod = 'Tunai',
  }) async {
    final pdfBytes = await generateReceipt(storeInfo, transactionId, totalAmount, paidAmount, kembalian, items, paymentMethod: paymentMethod);
    
    final prefs = await SharedPreferences.getInstance();
    final printerName = prefs.getString('printer_name');
    final printerUrl = prefs.getString('printer_url');
    final directPrint = prefs.getBool('direct_print') ?? false;

    if (directPrint && printerName != null && printerUrl != null) {
      try {
        final printer = Printer(url: printerUrl, name: printerName);
        await Printing.directPrintPdf(
          printer: printer,
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Struk-#$transactionId',
        );
        return;
      } catch (e) {
        debugPrint('Direct print failed, falling back to layoutPdf: $e');
      }
    }

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
      text: 'Struk Belanja - ${storeInfo['storeName'] ?? 'Toko'} (ID: $transactionId)\nTotal: Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalAmount)}',
    );
  }
}
