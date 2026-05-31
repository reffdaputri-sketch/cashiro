import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/product_provider.dart';
import 'package:mobile/services/report_service.dart';

class StockReportScreen extends StatefulWidget {
  const StockReportScreen({super.key});

  @override
  State<StockReportScreen> createState() => _StockReportScreenState();
}

class _StockReportScreenState extends State<StockReportScreen> with RouteAware {
  final ReportService _reportService = ReportService();
  late Future<List<Map<String, dynamic>>> _stockFuture;
  late Future<List<Map<String, dynamic>>> _deletedFuture;

  @override
  void initState() {
    super.initState();
    _stockFuture = _reportService.getStockReport();
    _deletedFuture = _reportService.getDeletedProducts();
  }

  /// Dipanggil setiap kali screen ini menjadi aktif kembali (misal: kembali dari
  /// halaman produk setelah menghapus barang). Ini memastikan data stok selalu fresh.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _refreshAll();
  }

  void _refreshAll() {
    setState(() {
      _stockFuture = _reportService.getStockReport();
      _deletedFuture = _reportService.getDeletedProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Laporan Stok Barang', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: FutureBuilder<List<List<Map<String, dynamic>>>>(
        future: Future.wait([_stockFuture, _deletedFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final data = snapshot.data![0];
          final deletedProducts = snapshot.data![1];

          final outOfStock = data.where((p) => (p['stock'] as int) == 0).toList();
          final lowStock = data.where((p) => (p['stock'] as int) > 0 && (p['stock'] as int) <= ((p['min_stock'] as int?) ?? 5)).toList();
          final safeStock = data.where((p) => (p['stock'] as int) > ((p['min_stock'] as int?) ?? 5)).toList();

          return CustomScrollView(
            slivers: [
              // ── Summary Cards ──────────────────────────────────────────────
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

              // ── Stok aktif ────────────────────────────────────────────────
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

              // ── Produk Terhapus ───────────────────────────────────────────
              if (deletedProducts.isNotEmpty) ...[
                _buildDeletedSectionHeader(deletedProducts.length),
                _buildDeletedProductList(deletedProducts),
              ],

              const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
            ],
          );
        },
      ),
    );
  }

  // ── Summary card ──────────────────────────────────────────────────────────

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

  // ── Section headers ───────────────────────────────────────────────────────

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

  Widget _buildDeletedSectionHeader(int count) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.grey[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Produk Terhapus ($count)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Produk ini sudah dihapus dari master data. Hapus permanen untuk membersihkan database.',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // ── Product lists ─────────────────────────────────────────────────────────

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

  Widget _buildDeletedProductList(List<Map<String, dynamic>> products) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = products[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              elevation: 0,
              color: Colors.grey[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!, style: BorderStyle.solid),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2_outlined, color: Colors.grey[500], size: 20),
                ),
                title: Text(
                  p['name'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  'Stok tersisa: ${p['stock']} | Kode: ${p['code'] ?? '-'}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                trailing: TextButton.icon(
                  onPressed: () => _confirmPermanentDelete(p),
                  icon: const Icon(Icons.delete_forever, size: 18),
                  label: const Text('Hapus', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    backgroundColor: Colors.red[50],
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            );
          },
          childCount: products.length,
        ),
      ),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

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
            child: const Text('Batal'),
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
                _refreshAll(); // Refresh laporan stok
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPermanentDelete(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.delete_forever, size: 40, color: Colors.red[600]),
            ),
            const SizedBox(height: 16),
            const Text('Hapus Permanen?', textAlign: TextAlign.center),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${product['name']}"',
              style: const TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Riwayat transaksi yang menggunakan produk ini akan tetap tersimpan.',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tindakan ini tidak dapat dibatalkan.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus Permanen'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<ProductProvider>(context, listen: false)
          .permanentlyDeleteProduct(product['id'] as int);
      _refreshAll();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text('"${product['name']}" berhasil dihapus permanen.')),
              ],
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }
}
