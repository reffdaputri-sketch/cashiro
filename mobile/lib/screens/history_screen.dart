import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/receipt_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _transactionsFuture = _db.getAll('transactions', orderBy: 'id DESC');
    });
  }

  void _showTransactionDetails(Map<String, dynamic> t) async {
    final db = await _db.database;
    final items = await db.rawQuery('''
      SELECT p.name, ti.quantity, ti.price_at_sale as price, (ti.price_at_sale * ti.quantity) as total
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [t['id']]);

    final customerResult = await db.rawQuery('''
      SELECT c.name, c.phone 
      FROM transactions t
      JOIN customers c ON t.customer_id = c.id
      WHERE t.id = ?
    ''', [t['id']]);
    final String? customerName = customerResult.isNotEmpty ? customerResult.first['name'] as String? : null;
    final String? customerPhone = customerResult.isNotEmpty ? customerResult.first['phone'] as String? : null;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final currencyFormatter =
            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final date = DateTime.parse(t['created_at']);
        final double kembalian = (t['paid_amount'] as num).toDouble() - (t['total_amount'] as num).toDouble();

        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Detail Transaksi #${t['id']}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('dd MMMM yyyy, HH:mm').format(date),
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const Divider(height: 24),
                  const Text('Daftar Produk', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text('${item['name']} (x${item['quantity']})'),
                        ),
                        Text(currencyFormatter.format(item['total'])),
                      ],
                    ),
                  )),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Belanja', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(currencyFormatter.format(t['total_amount']), style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  if (customerName != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pelanggan'),
                        Text('$customerName ${customerPhone != null && customerPhone.isNotEmpty ? "($customerPhone)" : ""}', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode Pembayaran'),
                      Text(t['payment_method'] ?? 'Tunai', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tunai / Bayar'),
                      Text(currencyFormatter.format(t['paid_amount'])),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kembalian'),
                      Text(currencyFormatter.format(kembalian)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.print),
                          label: const Text('Cetak'),
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final receiptService = ReceiptService();
                            await receiptService.printReceipt(
                              authProvider.storeInfo,
                              t['id'],
                              (t['total_amount'] as num).toDouble(),
                              (t['paid_amount'] as num).toDouble(),
                              kembalian,
                              items.map((item) => {
                                'name': item['name'],
                                'quantity': item['quantity'],
                                'total': (item['total'] as num).toDouble(),
                              }).toList(),
                              paymentMethod: t['payment_method'] ?? 'Tunai',
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.share_rounded),
                          label: const Text('Bagikan'),
                          onPressed: () async {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            final receiptService = ReceiptService();
                            await receiptService.shareReceipt(
                              authProvider.storeInfo,
                              t['id'],
                              (t['total_amount'] as num).toDouble(),
                              (t['paid_amount'] as num).toDouble(),
                              kembalian,
                              items.map((item) => {
                                'name': item['name'],
                                'quantity': item['quantity'],
                                'total': (item['total'] as num).toDouble(),
                              }).toList(),
                              paymentMethod: t['payment_method'] ?? 'Tunai',
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi'), actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)
      ]),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Belum ada transaksi.'));
          }

          final transactions = snapshot.data!;
          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final t = transactions[index];
              final date = DateTime.parse(t['created_at']);
              return ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.green),
                title: Text('Transaksi #${t['id']}'),
                subtitle: Text(DateFormat('dd MMM yyyy HH:mm').format(date)),
                trailing: Text(
                  currencyFormatter.format(t['total_amount']),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onTap: () => _showTransactionDetails(t),
              );
            },
          );
        },
      ),
    );
  }
}
