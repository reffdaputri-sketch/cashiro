import 'dart:io';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:mobile/services/report_service.dart';

class ReportExportService {
  static final ReportService _reportService = ReportService();
  static final _currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  static final _dateFormatter = DateFormat('dd/MM/yyyy');

  static Future<void> exportToExcel(DateTime start, DateTime end, String rangeLabel) async {
    final excel = Excel.createExcel();
    final defaultSheetName = excel.tables.keys.first;
    final sheet = excel[defaultSheetName];
    
    final pl = await _reportService.getProfitLoss(start, end);
    final payments = await _reportService.getPaymentMethodsReport(start, end);
    final sellers = await _reportService.getBestSellers(start, end);
    final stocks = await _reportService.getStockReport();

    // Title block
    sheet.appendRow([TextCellValue('LAPORAN KEUANGAN KIOSLY')]);
    sheet.appendRow([TextCellValue('Periode: $rangeLabel (${_dateFormatter.format(start)} - ${_dateFormatter.format(end)})')]);
    sheet.appendRow([]);

    // 1. Profit Loss Summary
    sheet.appendRow([TextCellValue('1. RINGKASAN LABA RUGI')]);
    sheet.appendRow([TextCellValue('Kategori'), TextCellValue('Jumlah')]);
    sheet.appendRow([TextCellValue('Total Penjualan'), IntCellValue(pl['revenue']!.round())]);
    sheet.appendRow([TextCellValue('Total HPP (Modal)'), IntCellValue(pl['cogs']!.round())]);
    sheet.appendRow([TextCellValue('Laba Kotor'), IntCellValue(pl['grossProfit']!.round())]);
    sheet.appendRow([TextCellValue('Pengeluaran'), IntCellValue(pl['expenses']!.round())]);
    sheet.appendRow([TextCellValue('Laba Bersih'), IntCellValue(pl['netProfit']!.round())]);
    sheet.appendRow([]);

    // 2. Payment Methods breakdown
    sheet.appendRow([TextCellValue('2. RINCIAN METODE PEMBAYARAN')]);
    if (payments.isNotEmpty) {
      final mostUsedMethod = payments.reduce((a, b) =>
          (a['transaction_count'] as int) > (b['transaction_count'] as int) ? a : b);
      sheet.appendRow([
        TextCellValue('Metode Terpopuler:'),
        TextCellValue('${mostUsedMethod['payment_method'] ?? 'Tunai'} (${mostUsedMethod['transaction_count']}x)'),
      ]);
    }
    sheet.appendRow([TextCellValue('Metode Pembayaran'), TextCellValue('Jumlah Transaksi'), TextCellValue('Total Nominal')]);
    if (payments.isEmpty) {
      sheet.appendRow([TextCellValue('- Belum ada transaksi -')]);
    } else {
      for (var pay in payments) {
        sheet.appendRow([
          TextCellValue(pay['payment_method'] ?? 'Tunai'),
          IntCellValue(pay['transaction_count'] as int),
          IntCellValue((pay['total_amount'] as num).round()),
        ]);
      }
    }
    sheet.appendRow([]);

    // 3. Best Sellers
    sheet.appendRow([TextCellValue('3. DAFTAR BARANG TERLARIS')]);
    sheet.appendRow([TextCellValue('Nama Produk'), TextCellValue('Terjual (Qty)'), TextCellValue('Total Penjualan')]);
    if (sellers.isEmpty) {
      sheet.appendRow([TextCellValue('- Belum ada data penjualan -')]);
    } else {
      for (var sell in sellers) {
        sheet.appendRow([
          TextCellValue(sell['name']),
          IntCellValue((sell['total_qty'] as num).toInt()),
          IntCellValue((sell['total_sales'] as num).round()),
        ]);
      }
    }
    sheet.appendRow([]);

    // 4. Laporan Stok Barang
    sheet.appendRow([TextCellValue('4. LAPORAN STOK BARANG')]);
    sheet.appendRow([TextCellValue('Nama Produk'), TextCellValue('Stok Saat Ini')]);
    if (stocks.isEmpty) {
      sheet.appendRow([TextCellValue('- Belum ada data produk -')]);
    } else {
      for (var s in stocks) {
        sheet.appendRow([
          TextCellValue(s['name'] ?? ''),
          IntCellValue(s['stock'] as int),
        ]);
      }
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final tempDir = await getTemporaryDirectory();
      final sanitizedLabel = rangeLabel.replaceAll(' ', '_').toLowerCase();
      final tempFile = File('${tempDir.path}/laporan_kiosly_${sanitizedLabel}.xlsx');
      await tempFile.writeAsBytes(fileBytes);
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        subject: 'Laporan Keuangan Kiosly ($rangeLabel)',
      );
    }
  }

  static Future<void> exportToPdf(DateTime start, DateTime end, String rangeLabel) async {
    final pdf = pw.Document();
    
    final pl = await _reportService.getProfitLoss(start, end);
    final payments = await _reportService.getPaymentMethodsReport(start, end);
    final sellers = await _reportService.getBestSellers(start, end);
    final stocks = await _reportService.getStockReport();

    String popularMethodInfo = '';
    if (payments.isNotEmpty) {
      final mostUsedMethod = payments.reduce((a, b) =>
          (a['transaction_count'] as int) > (b['transaction_count'] as int) ? a : b);
      popularMethodInfo = "${mostUsedMethod['payment_method'] ?? 'Tunai'} (${mostUsedMethod['transaction_count']}x)";
    }

    final fontNormal = pw.Font.helvetica();
    final fontBold = pw.Font.helveticaBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('KIOSLY POS', style: pw.TextStyle(font: fontBold, fontSize: 24, color: PdfColors.teal)),
                    pw.Text('Laporan Analisis Keuangan & Penjualan', style: pw.TextStyle(font: fontNormal, fontSize: 12, color: PdfColors.grey700)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Periode: $rangeLabel', style: pw.TextStyle(font: fontBold, fontSize: 12)),
                    pw.Text('${_dateFormatter.format(start)} - ${_dateFormatter.format(end)}', style: pw.TextStyle(font: fontNormal, fontSize: 10, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Section 1: Ringkasan Laba Rugi
          pw.Text('1. Ringkasan Laba Rugi', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.teal800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Kategori Keuangan', 'Jumlah'],
            headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            data: [
              ['Total Penjualan', _currencyFormatter.format(pl['revenue'])],
              ['Total HPP (Modal)', _currencyFormatter.format(pl['cogs'])],
              ['Laba Kotor', _currencyFormatter.format(pl['grossProfit'])],
              ['Total Pengeluaran', _currencyFormatter.format(pl['expenses'])],
              ['Laba Bersih', _currencyFormatter.format(pl['netProfit'])],
            ],
            cellStyle: pw.TextStyle(font: fontNormal),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 24),

          // Section 2: Rincian Metode Pembayaran
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('2. Uang Masuk per Metode Pembayaran', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.teal800)),
              if (popularMethodInfo.isNotEmpty)
                pw.Text('Terpopuler: $popularMethodInfo', style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.teal900)),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Metode Pembayaran', 'Jumlah Transaksi', 'Total Nominal'],
            headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            data: payments.isEmpty 
              ? [['- Tidak ada transaksi -', '-', '-']]
              : payments.map((pay) => [
                  pay['payment_method'] ?? 'Tunai',
                  pay['transaction_count'].toString(),
                  _currencyFormatter.format(pay['total_amount']),
                ]).toList(),
            cellStyle: pw.TextStyle(font: fontNormal),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 24),

          // Section 3: Daftar Barang Terlaris
          pw.Text('3. Daftar Barang Terlaris', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.teal800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Nama Produk', 'Jumlah Terjual (Qty)', 'Total Penjualan'],
            headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            data: sellers.isEmpty
              ? [['- Belum ada penjualan -', '-', '-']]
              : sellers.map((sell) => [
                  sell['name'],
                  sell['total_qty'].toString(),
                  _currencyFormatter.format(sell['total_sales']),
                ]).toList(),
            cellStyle: pw.TextStyle(font: fontNormal),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.center, 2: pw.Alignment.centerRight},
          ),
          pw.SizedBox(height: 24),

          // Section 4: Laporan Stok Barang
          pw.Text('4. Laporan Stok Barang', style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.teal800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Nama Produk', 'Stok Saat Ini'],
            headerStyle: pw.TextStyle(font: fontBold, color: PdfColors.white),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.teal),
            data: stocks.isEmpty
              ? [['- Belum ada data produk -', '-']]
              : stocks.map((s) => [
                  s['name'] ?? '',
                  s['stock'].toString(),
                ]).toList(),
            cellStyle: pw.TextStyle(font: fontNormal),
            cellAlignment: pw.Alignment.centerLeft,
            cellAlignments: {1: pw.Alignment.center},
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final sanitizedLabel = rangeLabel.replaceAll(' ', '_').toLowerCase();
    final tempFile = File('${tempDir.path}/laporan_kiosly_${sanitizedLabel}.pdf');
    await tempFile.writeAsBytes(bytes);
    
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      subject: 'Laporan Keuangan Kiosly ($rangeLabel)',
    );
  }
}
