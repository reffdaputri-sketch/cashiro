import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/staff_provider.dart';
import 'package:mobile/screens/staff_form_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<StaffProvider>(context, listen: false).fetchStaffs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Staf')),
      body: Consumer<StaffProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) return const Center(child: CircularProgressIndicator());
          if (provider.staffs.isEmpty) {
            return const Center(child: Text('Belum ada staf kasir.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.staffs.length,
            itemBuilder: (context, index) {
              final staff = provider.staffs[index];
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.person)),
                  title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID Staf: #${staff.id} - Role: ${staff.role}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => StaffFormScreen(staff: staff)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const StaffFormScreen()),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
