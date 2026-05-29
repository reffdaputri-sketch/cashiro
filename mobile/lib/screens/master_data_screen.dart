import 'package:flutter/material.dart';
import 'package:mobile/screens/product_list_screen.dart';
import 'package:mobile/screens/customer_list_screen.dart';
import 'package:mobile/screens/category_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/stock_report_screen.dart';

class MasterDataScreen extends StatelessWidget {
  const MasterDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (auth.hasPermission('Manajemen Produk'))
            _buildMenuCard(
              context,
              title: 'Data Produk',
              subtitle: 'Kelola stok, harga, dan variasi produk',
              icon: Icons.inventory,
              color: Colors.blue,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProductListScreen()),
              ),
            ),
          if (auth.hasPermission('Manajemen Produk')) const SizedBox(height: 16),
          if (auth.hasPermission('Manajemen Kategori'))
            _buildMenuCard(
              context,
              title: 'Kategori Produk',
              subtitle: 'Kelola pengelompokan produk',
              icon: Icons.category,
              color: Colors.orange,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CategoryListScreen()),
              ),
            ),
          if (auth.hasPermission('Manajemen Kategori')) const SizedBox(height: 16),
          if (auth.hasPermission('Data Pelanggan'))
            _buildMenuCard(
              context,
              title: 'Data Pelanggan',
              subtitle: 'Kelola database dan riwayat pelanggan',
              icon: Icons.people,
              color: Colors.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomerListScreen()),
              ),
            ),
          if (auth.hasPermission('Manajemen Produk')) const SizedBox(height: 16),
          if (auth.hasPermission('Manajemen Produk'))
            _buildMenuCard(
              context,
              title: 'Laporan Stok Barang',
              subtitle: 'Pantau stok produk & opname fisik',
              icon: Icons.assessment_outlined,
              color: Colors.teal,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StockReportScreen()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 30),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

}
