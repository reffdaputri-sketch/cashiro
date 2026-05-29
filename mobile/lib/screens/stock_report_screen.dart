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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Laporan Stok Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _reportService.getStockReport(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          
          final outOfStock = data.where((p) => (p['stock'] as int) == 0).toList();
          final lowStock = data.where((p) => (p['stock'] as int) > 0 && (p['stock'] as int) <= ((p['min_stock'] as int?) ?? 5)).toList();
          final safeStock = data.where((p) => (p['stock'] as int) > ((p['min_stock'] as int?) ?? 5)).toList();

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      _buildSummaryCard('Total', data.length, Icons.inventory_2, Colors.blue),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Menipis', lowStock.length, Icons.warning_amber_rounded, Colors.orange),
                      const SizedBox(width: 12),
                      _buildSummaryCard('Habis', outOfStock.length, Icons.error_outline, Colors.red),
                    ],
                  ),
                ),
              ),
              if (outOfStock.isNotEmpty) ...[
                _buildSectionHeader('Stok Habis', Colors.red),
                _buildProductList(outOfStock, Colors.red),
              ],
              if (lowStock.isNotEmpty) ...[
                _buildSectionHeader('Stok Menipis', Colors.orange),
                _buildProductList(lowStock, Colors.orange),
              ],
              if (safeStock.isNotEmpty) ...[
                _buildSectionHeader('Stok Aman', Colors.green),
                _buildProductList(safeStock, Colors.green),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(String title, int count, IconData icon, MaterialColor color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color[100]!),
        ),
        child: Column(
          children: [
            Icon(icon, color: color[700], size: 28),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color[900]),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: color[700], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> products, Color statusColor) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('Min. Stok: ${p['min_stock'] ?? 5}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${p['stock']}',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_note, color: Colors.blue),
                      tooltip: 'Sesuaikan Stok',
                      onPressed: () => _showStockOpnameDialog(p),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  Future<void> _showStockOpnameDialog(Map<String, dynamic> product) async {
    final controller = TextEditingController(text: product['stock'].toString());
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            const Icon(Icons.inventory, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('Opname Stok', textAlign: TextAlign.center),
            Text(
              product['name'],
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Stok Fisik Saat Ini',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context), 
            child: const Text('Batal')
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
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
