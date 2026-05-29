import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  List<Printer> _printers = [];
  bool _isScanning = false;
  String? _selectedPrinterName;
  String? _selectedPrinterUrl;
  bool _directPrint = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _scanPrinters();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterName = prefs.getString('printer_name');
      _selectedPrinterUrl = prefs.getString('printer_url');
      _directPrint = prefs.getBool('direct_print') ?? false;
    });
  }

  Future<void> _scanPrinters() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });

    try {
      final printers = await Printing.listPrinters();
      setState(() {
        _printers = printers;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memindai printer: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _selectPrinter(Printer printer) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_name', printer.name);
    await prefs.setString('printer_url', printer.url);
    setState(() {
      _selectedPrinterName = printer.name;
      _selectedPrinterUrl = printer.url;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer ${printer.name} terpilih')),
      );
    }
  }

  Future<void> _toggleDirectPrint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('direct_print', value);
    setState(() {
      _directPrint = value;
    });
  }

  Future<void> _testPrint(Printer printer) async {
    try {
      final doc = await Printing.convertHtml(
        html: '<html><body><h1 style="text-align:center;">Test Print Kiosly</h1><p style="text-align:center;">Printer Anda berhasil terhubung!</p></body></html>',
      );
      await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => doc,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal cetak tes: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Printer'),
        actions: [
          IconButton(
            icon: _isScanning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _scanPrinters,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_selectedPrinterName != null) ...[
            Card(
              color: Theme.of(context).primaryColor.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: const Icon(Icons.print, color: Colors.white),
                ),
                title: const Text('Printer Terpilih Aktif', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('$_selectedPrinterName\n$_selectedPrinterUrl', style: const TextStyle(fontSize: 12)),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Direct Print Toggle Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Cetak Langsung (Direct Print)', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Langsung mencetak ke printer tanpa menampilkan dialog sistem'),
              value: _directPrint,
              onChanged: _toggleDirectPrint,
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Daftar Printer Tersedia (Bluetooth / Network)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          if (_printers.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.print_disabled, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tidak ada printer terdeteksi', style: TextStyle(color: Colors.grey)),
                    Text(
                      'Pastikan bluetooth printer Anda aktif dan sudah dipasangkan (paired) di pengaturan sistem HP.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._printers.map((printer) {
              final isSelected = _selectedPrinterUrl == printer.url;
              return Card(
                key: ValueKey(printer.url),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isSelected
                        ? Theme.of(context).primaryColor.withOpacity(0.1)
                        : Colors.grey[200],
                    child: Icon(
                      Icons.print,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  title: Text(
                    printer.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(printer.url, style: const TextStyle(fontSize: 10)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.green)
                      else
                        ElevatedButton(
                          onPressed: () => _selectPrinter(printer),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Pilih', style: TextStyle(fontSize: 12)),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.blue),
                        tooltip: 'Cetak Tes',
                        onPressed: () => _testPrint(printer),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}
