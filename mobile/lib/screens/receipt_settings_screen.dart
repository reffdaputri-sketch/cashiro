import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptSettingsScreen extends StatefulWidget {
  const ReceiptSettingsScreen({super.key});

  @override
  State<ReceiptSettingsScreen> createState() => _ReceiptSettingsScreenState();
}

class _ReceiptSettingsScreenState extends State<ReceiptSettingsScreen> {
  final _footerController = TextEditingController();
  
  bool _showLogo = true;
  bool _showStoreName = true;
  bool _showAddress = true;
  bool _showPhone = true;
  bool _showDate = true;
  bool _showTransactionId = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _footerController.text = prefs.getString('receipt_footer_text') ?? 'Terima Kasih';
      _showLogo = prefs.getBool('receipt_show_logo') ?? true;
      _showStoreName = prefs.getBool('receipt_show_store_name') ?? true;
      _showAddress = prefs.getBool('receipt_show_address') ?? true;
      _showPhone = prefs.getBool('receipt_show_phone') ?? true;
      _showDate = prefs.getBool('receipt_show_date') ?? true;
      _showTransactionId = prefs.getBool('receipt_show_transaction_id') ?? true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('receipt_footer_text', _footerController.text.trim());
    await prefs.setBool('receipt_show_logo', _showLogo);
    await prefs.setBool('receipt_show_store_name', _showStoreName);
    await prefs.setBool('receipt_show_address', _showAddress);
    await prefs.setBool('receipt_show_phone', _showPhone);
    await prefs.setBool('receipt_show_date', _showDate);
    await prefs.setBool('receipt_show_transaction_id', _showTransactionId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan desain nota berhasil disimpan')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Desain Nota'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Teks Tambahan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _footerController,
                  decoration: const InputDecoration(
                    labelText: 'Watermark / Teks Bawah Nota',
                    hintText: 'Misal: Terima Kasih, Barang tidak bisa ditukar',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tampilan Elemen Nota',
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
                    title: const Text('Tampilkan Logo Outlet'),
                    value: _showLogo,
                    onChanged: (val) => setState(() => _showLogo = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tampilkan Nama Outlet'),
                    value: _showStoreName,
                    onChanged: (val) => setState(() => _showStoreName = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tampilkan Alamat'),
                    value: _showAddress,
                    onChanged: (val) => setState(() => _showAddress = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tampilkan Nomor Telepon'),
                    value: _showPhone,
                    onChanged: (val) => setState(() => _showPhone = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tampilkan Tanggal dan Waktu'),
                    value: _showDate,
                    onChanged: (val) => setState(() => _showDate = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Tampilkan Nomor Transaksi/Nota'),
                    value: _showTransactionId,
                    onChanged: (val) => setState(() => _showTransactionId = val),
                    activeColor: Theme.of(context).primaryColor,
                  ),
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
