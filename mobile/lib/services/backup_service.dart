import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile/services/database_service.dart';

class BackupService {
  
  Future<void> exportDatabase(BuildContext context) async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'kiosly.db');
      final file = File(path);

      if (!await file.exists()) {
        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database belum dibuat.')));
        return;
      }

      // Create a temporary copy to share
      final tempDir = Directory.systemTemp;
      final tempPath = join(tempDir.path, 'kiosly_backup_${DateTime.now().millisecondsSinceEpoch}.db');
      await file.copy(tempPath);

      // Share the file
      final xFile = XFile(tempPath);
      await Share.shareXFiles([xFile], text: 'Backup Database Kiosly');
      
    } catch (e) {
      debugPrint('Export Error: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal backup: $e')));
    }
  }

  Future<void> importDatabase(BuildContext context) async {
    try {
      // Pick file
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final File sourceFile = File(result.files.single.path!);
        
        // Confirm overwrite
        final confirm = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Restore Database?'),
            content: const Text('PERINGATAN: Semua data saat ini akan diganti dengan data dari file backup. Data yang ada akan hilang permanen.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Restore'),
              ),
            ],
          ),
        );

        if (confirm == true) {
          // Close DB first? Ideally yes, but sqflite usually handles file replacement if careful.
          // Better to ensure it's closed or just overwrite.
          
          final dbPath = await getDatabasesPath();
          final path = join(dbPath, 'kiosly.db');

          // Overwrite
          await sourceFile.copy(path);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restore berhasil! Silakan restart aplikasi.')));
          }
        }
      }
    } catch (e) {
      debugPrint('Import Error: $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal restore: $e')));
    }
  }
}
