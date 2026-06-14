import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/database_service.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/auth_provider.dart';
import '../services/sync_service.dart';
import '../services/receipt_service.dart';
import 'package:intl/intl.dart';

class ActiveOrdersScreen extends StatefulWidget {
  const ActiveOrdersScreen({super.key});

  @override
  State<ActiveOrdersScreen> createState() => _ActiveOrdersScreenState();
}

class _ActiveOrdersScreenState extends State<ActiveOrdersScreen> {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _draftOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDraftOrders();
  }

  Future<void> _loadDraftOrders() async {
    setState(() => _isLoading = true);
    try {
      final db = await _db.database;
      final results = await db.query(
        'transactions',
        where: "status = 'Draft' OR kitchen_status IN ('Pending', 'Ready')",
        orderBy: 'created_at DESC',
      );
      setState(() {
        _draftOrders = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showOrderDetails(BuildContext context, int orderId, String tableStr) async {
    final db = await _db.database;
    final items = await db.rawQuery('''
      SELECT ti.*, 
             p.name as p_name, 
             pv.name as v_name 
      FROM transaction_items ti
      LEFT JOIN products p ON ti.product_id = p.id
      LEFT JOIN product_variations pv ON ti.variation_id = pv.id
      WHERE ti.transaction_id = ?
    ''', [orderId]);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16))
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Detail $tableStr', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      final pName = item['p_name'] as String? ?? 'Produk Terhapus';
                      final vName = item['v_name'] as String?;
                      final displayName = vName != null ? '$pName ($vName)' : pName;
                      final notes = item['notes'] as String?;
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['quantity']}x', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: const TextStyle(fontSize: 16)),
                                  if (notes != null && notes.isNotEmpty)
                                    Text('Catatan: $notes', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontStyle: FontStyle.italic)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesanan Aktif (Meja)'),
        backgroundColor: primaryColor,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Tarik Data Dapur',
            onPressed: () async {
              setState(() => _isLoading = true);
              try {
                final auth = Provider.of<AuthProvider>(context, listen: false);
                final storeInfo = auth.storeInfo;
                if (storeInfo['storeId'] != null && storeInfo['storeId'] != 'DEMO-STORE-ID') {
                  await SyncService().downloadAllCloudData(storeInfo['storeId']!, storeInfo['licenseKey'] ?? '');
                }
              } catch(e) {
                 debugPrint('Sync active orders error: $e');
              }
              await _loadDraftOrders();
            },
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _draftOrders.isEmpty
              ? const Center(child: Text('Tidak ada pesanan aktif.', style: TextStyle(fontSize: 16)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _draftOrders.length,
                  itemBuilder: (context, index) {
                    final order = _draftOrders[index];
                    final date = DateTime.parse(order['created_at']);
                    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(date);
                    final tableStr = order['table_number'] != null && order['table_number'].toString().isNotEmpty
                        ? 'Meja: ${order['table_number']}'
                        : 'Tanpa Meja';
                    final orderType = order['order_type'] ?? 'Dine In';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        onTap: () => _showOrderDetails(context, order['id'] as int, tableStr),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          backgroundColor: primaryColor.withOpacity(0.1),
                          child: Icon(
                            orderType == 'Dine In' ? Icons.restaurant : Icons.takeout_dining,
                            color: primaryColor,
                          ),
                        ),
                        title: Text(
                          tableStr,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('Tipe: $orderType'),
                            Text('Waktu: $formattedDate'),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (order['kitchen_status'] == 'Ready')
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                                    child: const Text('Siap Disajikan', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: order['status'] == 'Draft' ? Colors.red : Colors.blue, borderRadius: BorderRadius.circular(4)),
                                  child: Text(order['status'] == 'Draft' ? 'Belum Bayar' : 'Lunas', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currencyFormatter.format(order['total_amount']),
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        trailing: order['status'] == 'Draft'
                          ? ElevatedButton(
                              onPressed: () async {
                                final cartProvider = Provider.of<CartProvider>(context, listen: false);
                                final productProvider = Provider.of<ProductProvider>(context, listen: false);
                                
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (c) => const Center(child: CircularProgressIndicator()),
                                );
                                
                                await cartProvider.loadDraftOrder(order['id'] as int, productProvider.products);
                                
                                if (context.mounted) {
                                   Navigator.pop(context); // Tutup loading
                                   Navigator.pop(context); // Kembali ke POS Screen
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text('Bayar', style: TextStyle(fontSize: 12)),
                            )
                          : ElevatedButton.icon(
                              onPressed: () async {
                                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                                final dbService = DatabaseService();
                                final db = await dbService.database;
                                final itemsResult = await db.rawQuery('''
                                  SELECT ti.quantity, p.name, (ti.price_at_sale * ti.quantity) as total
                                  FROM transaction_items ti
                                  JOIN products p ON ti.product_id = p.id
                                  WHERE ti.transaction_id = ?
                                ''', [order['id']]);

                                final paidAmount = (order['paid_amount'] as num?)?.toDouble() ?? 0.0;
                                final totalAmount = (order['total_amount'] as num?)?.toDouble() ?? 0.0;
                                final kembalian = paidAmount - totalAmount;
                                
                                final receiptService = ReceiptService();
                                await receiptService.printReceipt(
                                  authProvider.storeInfo,
                                  order['id'] as int,
                                  totalAmount,
                                  paidAmount,
                                  kembalian,
                                  itemsResult.map((item) => {
                                    'name': item['name'],
                                    'quantity': item['quantity'],
                                    'total': (item['total'] as num?)?.toDouble() ?? 0.0,
                                  }).toList(),
                                  paymentMethod: order['payment_method'] as String? ?? 'Tunai',
                                  taxAmount: (order['tax_amount'] as num?)?.toDouble() ?? 0.0,
                                  serviceChargeAmount: (order['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
                                  taxPercentage: (order['tax_percentage'] as num?)?.toDouble(),
                                  cashierName: order['cashier_name'] as String?,
                                );
                              },
                              icon: const Icon(Icons.print, size: 14),
                              label: const Text('Struk', style: TextStyle(fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                      ),
                    );
                  },
                ),
    );
  }
}
