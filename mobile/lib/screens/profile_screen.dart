import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/edit_store_screen.dart';
import 'package:mobile/screens/expense_screen.dart';
import 'package:mobile/services/backup_service.dart';
import 'package:mobile/providers/product_provider.dart';
import 'dart:io';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final info = auth.storeInfo;
    final imagePath = info['imagePath'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Toko'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const EditStoreScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
               CircleAvatar(
                radius: 50,
                backgroundImage: (imagePath != null && imagePath.isNotEmpty)
                    ? FileImage(File(imagePath))
                    : null,
                child: (imagePath == null || imagePath.isEmpty)
                    ? const Icon(Icons.store, size: 50)
                    : null,
              ),
              const SizedBox(height: 20),
              if (info['storeName'] != null)
                Text(info['storeName']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Pemilik'),
                subtitle: Text(info['ownerName'] ?? '-'),
              ),
              ListTile(
                leading: const Icon(Icons.phone),
                title: const Text('Telepon'),
                subtitle: Text(info['phone'] ?? '-'),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Alamat'),
                subtitle: Text(info['address'] ?? '-'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.money_off, color: Colors.red),
                title: const Text('Manajemen Pengeluaran'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ExpenseScreen()),
                  );
                },
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.blueGrey),
                title: const Text('Pengaturan Toko'),
                subtitle: const Text('Ubah nama, alamat, dan logo toko'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditStoreScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.backup, color: Colors.blue),
                title: const Text('Backup Database'),
                trailing: const Icon(Icons.download, size: 20),
                onTap: () async {
                   final backupService = BackupService();
                   await backupService.exportDatabase(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.restore, color: Colors.orange),
                title: const Text('Restore Database'),
                trailing: const Icon(Icons.upload, size: 20),
                onTap: () async {
                   final backupService = BackupService();
                   await backupService.importDatabase(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.playlist_add, color: Colors.purple),
                title: const Text('Generate Demo Data'),
                subtitle: const Text('Tambah 15 produk contoh (Random)'),
                onTap: () async {
                   final confirm = await showDialog<bool>(
                     context: context,
                     builder: (ctx) => AlertDialog(
                       title: const Text('Generate Data?'),
                       content: const Text('Ini akan menambahkan 15 produk contoh ke database.'),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                         ElevatedButton(
                           onPressed: () => Navigator.pop(ctx, true),
                           child: const Text('Generate'),
                         ),
                       ],
                     ),
                   );

                   if (confirm == true) {
                     await Provider.of<ProductProvider>(context, listen: false).generateDemoData();
                     if (context.mounted) {
                       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Data demo berhasil ditambahkan!')));
                     }
                   }
                },
              ),
              const Divider(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  onPressed: () async {
                    await Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                  child: const Text('Keluar (Reset)'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
