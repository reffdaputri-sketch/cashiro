import 'dart:async';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrinterSettingsScreen extends StatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  State<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends State<PrinterSettingsScreen> {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _isScanning = false;
  String? _selectedPrinterName;
  String? _selectedPrinterMac;
  bool _directPrint = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initBluetooth();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedPrinterName = prefs.getString('printer_name');
      _selectedPrinterMac = prefs.getString('printer_mac');
      _directPrint = prefs.getBool('direct_print') ?? true; // Default true for thermal
    });
  }

  Future<void> _initBluetooth() async {
    bool? isConnected = await bluetooth.isConnected;
    setState(() {
      _connected = isConnected ?? false;
    });

    bluetooth.onStateChanged().listen((state) {
      switch (state) {
        case BlueThermalPrinter.CONNECTED:
          setState(() {
            _connected = true;
          });
          break;
        case BlueThermalPrinter.DISCONNECTED:
        case BlueThermalPrinter.DISCONNECT_REQUESTED:
          setState(() {
            _connected = false;
          });
          break;
        default:
          break;
      }
    });

    _scanPrinters();
  }

  Future<void> _scanPrinters() async {
    if (_isScanning) return;

    // Minta permission bluetooth
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();

    setState(() {
      _isScanning = true;
    });

    try {
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      setState(() {
        _devices = devices;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mencari perangkat: $e')),
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

  Future<void> _selectPrinter(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('printer_name', device.name ?? 'Printer');
    await prefs.setString('printer_mac', device.address ?? '');
    
    setState(() {
      _selectedPrinterName = device.name;
      _selectedPrinterMac = device.address;
      _device = device;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Printer ${device.name} terpilih')),
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

  Future<void> _testPrint(BluetoothDevice device) async {
    if (device.address == null) return;
    
    try {
      bool? isConnected = await bluetooth.isConnected;
      if (!isConnected!) {
        await bluetooth.connect(device);
      }

      bluetooth.printNewLine();
      bluetooth.printCustom("Test Print Kiosly", 2, 1); // Size 2, Align Center
      bluetooth.printNewLine();
      bluetooth.printCustom("Printer Anda berhasil terhubung!", 1, 1);
      bluetooth.printNewLine();
      bluetooth.printNewLine();
      
      // bluetooth.disconnect(); // Opsional: tutup koneksi atau biarkan terbuka
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
                subtitle: Text('$_selectedPrinterName\n$_selectedPrinterMac', style: const TextStyle(fontSize: 12)),
                trailing: _connected 
                  ? const Chip(label: Text('Connected', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.green)
                  : const Chip(label: Text('Offline', style: TextStyle(fontSize: 10))),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: SwitchListTile(
              title: const Text('Cetak Otomatis ke Thermal', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Langsung mencetak struk format teks saat transaksi selesai'),
              value: _directPrint,
              onChanged: _toggleDirectPrint,
              activeColor: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Daftar Perangkat Bluetooth (Paired)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 10),

          if (_devices.isEmpty)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(Icons.bluetooth_disabled, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Tidak ada perangkat bluetooth', style: TextStyle(color: Colors.grey)),
                    Text(
                      'Pastikan bluetooth Anda aktif dan printer sudah di-pairing (dipasangkan) via pengaturan HP Anda.',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else
            ..._devices.map((device) {
              final isSelected = _selectedPrinterMac == device.address;
              return Card(
                key: ValueKey(device.address),
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
                      Icons.bluetooth,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                    ),
                  ),
                  title: Text(
                    device.name ?? 'Unknown Device',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(device.address ?? '', style: const TextStyle(fontSize: 10)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check_circle, color: Colors.green)
                      else
                        ElevatedButton(
                          onPressed: () => _selectPrinter(device),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Pilih', style: TextStyle(fontSize: 12)),
                        ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.play_arrow, color: Colors.blue),
                        tooltip: 'Cetak Tes',
                        onPressed: () => _testPrint(device),
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
