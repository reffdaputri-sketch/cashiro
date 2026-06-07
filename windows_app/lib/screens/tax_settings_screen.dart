import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/cart_provider.dart';

class TaxSettingsScreen extends StatefulWidget {
  const TaxSettingsScreen({super.key});

  @override
  State<TaxSettingsScreen> createState() => _TaxSettingsScreenState();
}

class _TaxSettingsScreenState extends State<TaxSettingsScreen> {
  bool _taxEnabled = false;
  double _taxPercentage = 11.0;
  bool _serviceChargeEnabled = false;
  double _serviceChargePercentage = 5.0;

  final _taxController = TextEditingController();
  final _serviceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _taxEnabled = prefs.getBool('tax_enabled') ?? false;
      _taxPercentage = prefs.getDouble('tax_percentage') ?? 11.0;
      _serviceChargeEnabled = prefs.getBool('service_charge_enabled') ?? false;
      _serviceChargePercentage = prefs.getDouble('service_charge_percentage') ?? 5.0;

      _taxController.text = _taxPercentage.toString();
      _serviceController.text = _serviceChargePercentage.toString();
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    double taxVal = double.tryParse(_taxController.text) ?? 0.0;
    double svcVal = double.tryParse(_serviceController.text) ?? 0.0;

    await prefs.setBool('tax_enabled', _taxEnabled);
    await prefs.setDouble('tax_percentage', taxVal);
    await prefs.setBool('service_charge_enabled', _serviceChargeEnabled);
    await prefs.setDouble('service_charge_percentage', svcVal);

    if (mounted) {
      // Reload cart provider to apply new taxes immediately
      Provider.of<CartProvider>(context, listen: false).loadTaxSettings();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan Pajak & Layanan berhasil disimpan')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _taxController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pajak & Biaya Layanan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Pajak (PPN)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Aktifkan Pajak Otomatis'),
                    subtitle: const Text('Terapkan pajak pada setiap transaksi'),
                    value: _taxEnabled,
                    onChanged: (val) => setState(() => _taxEnabled = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  if (_taxEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Besaran Pajak (%)'),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _taxController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Pengaturan Biaya Layanan (Service Charge)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Aktifkan Service Charge'),
                    subtitle: const Text('Tambahkan biaya layanan ke pesanan'),
                    value: _serviceChargeEnabled,
                    onChanged: (val) => setState(() => _serviceChargeEnabled = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  if (_serviceChargeEnabled) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          const Expanded(
                            flex: 2,
                            child: Text('Besaran Layanan (%)'),
                          ),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _serviceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              decoration: const InputDecoration(
                                isDense: true,
                                suffixText: '%',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveSettings,
                child: const Text('SIMPAN', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
