import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/staff_provider.dart';
import 'package:mobile/models/staff.dart';

class StaffFormScreen extends StatefulWidget {
  final Staff? staff;
  const StaffFormScreen({super.key, this.staff});

  @override
  State<StaffFormScreen> createState() => _StaffFormScreenState();
}

class _StaffFormScreenState extends State<StaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _pinController;
  final Map<String, bool> _permissions = {
    'Laporan Penjualan': false,
    'Laporan Kasir': false,
    'Manajemen Produk': false,
    'Manajemen Kategori': false,
    'Manajemen Diskon': false,
    'Data Pelanggan': false,
    'Konsinyasi': false,
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _pinController = TextEditingController(text: widget.staff?.pin ?? '');
    if (widget.staff != null) {
      for (var p in widget.staff!.permissions) {
        if (_permissions.containsKey(p)) {
          _permissions[p] = true;
        }
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final List<String> selectedPermissions = _permissions.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final staff = Staff(
        id: widget.staff?.id,
        name: _nameController.text,
        pin: _pinController.text,
        permissions: selectedPermissions,
        createdAt: widget.staff?.createdAt ?? DateTime.now(),
      );

      try {
        final provider = Provider.of<StaffProvider>(context, listen: false);
        if (widget.staff == null) {
          await provider.addStaff(staff);
        } else {
          await provider.updateStaff(staff);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Data staf berhasil disimpan')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menyimpan data: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staff == null ? 'Tambah Staf' : 'Edit Staf'),
        actions: [
          if (widget.staff != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: () => _confirmDelete(),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama Staf', prefixIcon: Icon(Icons.person)),
              validator: (v) => v!.isEmpty ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pinController,
              decoration: const InputDecoration(labelText: 'PIN Login', prefixIcon: Icon(Icons.lock)),
              keyboardType: TextInputType.number,
              maxLength: 6,
              obscureText: true,
              validator: (v) => v!.length < 4 ? 'PIN minimal 4 digit' : null,
            ),
            const SizedBox(height: 24),
            const Text('Izin Modul', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ..._permissions.keys.map((key) {
              return CheckboxListTile(
                title: Text(key),
                value: _permissions[key],
                onChanged: (val) => setState(() => _permissions[key] = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              );
            }).toList(),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Simpan Staf'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Staf?'),
        content: Text('Hapus staf "${widget.staff?.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          TextButton(
            onPressed: () async {
              await Provider.of<StaffProvider>(context, listen: false).deleteStaff(widget.staff!.id!);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
