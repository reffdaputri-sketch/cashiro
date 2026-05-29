import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/services/report_service.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> {
  final ReportService _reportService = ReportService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Stok Barang'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportService.getStockReport(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          
          // Separate low stock
          final lowStock = data.where((p) => (p['stock'] as int) < 5).toList();
          final others = data.where((p) => (p['stock'] as int) >= 5).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (lowStock.isNotEmpty) ...[
                 const Text('Stok Menipis (< 5)', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                 ...lowStock.map((p) => ListTile(
                   title: Text(p['name']),
                   trailing: Text('${p['stock']}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                 )),
                 const Divider(),
              ],
              const Text('Semua Produk', style: TextStyle(fontWeight: FontWeight.bold)),
              ...others.map((p) => ListTile(
                title: Text(p['name']),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${p['stock']}'),
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: () => _showStockOpnameDialog(p),
                    ),
                  ],
                ),
              )),
            ],
          );
        },
      ),
    );
  }

  Future<void> _showStockOpnameDialog(Map<String, dynamic> product) async {
    final controller = TextEditingController(text: product['stock'].toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Opname Stok: ${product['name']}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Stok Fisik Saat Ini'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text);
              if (newStock != null) {
                await Provider.of<ProductProvider>(context, listen: false)
                    .updateStock(product['id'], newStock);
                setState(() {}); // Refresh report
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
