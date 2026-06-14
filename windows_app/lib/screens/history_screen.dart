import 'package:flutter/material.dart';
import 'package:cashiro/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/auth_provider.dart';
import 'package:cashiro/services/receipt_service.dart';

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
      _transactionsFuture = _db.getAll('transactions', where: "status != 'Draft'", orderBy: 'id DESC');
    });
  }

  void _deleteTransaction(int transactionId) async {
    final db = await _db.database;
    await db.delete('transaction_items', where: 'transaction_id = ?', whereArgs: [transactionId]);
    try {
      await db.delete('debt_payments', where: 'transaction_id = ?', whereArgs: [transactionId]);
    } catch (_) {}
    await _db.delete('transactions', transactionId);
    _refresh();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi berhasil dihapus')));
    }
  }

  void _confirmDelete(BuildContext bContext, int transactionId) {
    showDialog(
      context: bContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Transaksi?'),
        content: const Text('Apakah Anda yakin ingin menghapus transaksi ini? Data tidak dapat dikembalikan dan stok tidak akan di-update otomatis.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(bContext);
              _deleteTransaction(transactionId);
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ─── RETUR LOGIC ─────────────────────────────────────────────────────────────

  /// Tampilkan dialog retur dengan input jumlah per item
  void _showReturDialog(BuildContext sheetContext, Map<String, dynamic> t, List<Map<String, dynamic>> items) {
    // Map dari item_id → TextEditingController untuk qty retur
    final Map<int, TextEditingController> controllers = {};
    for (final item in items) {
      final id = item['item_id'] as int;
      controllers[id] = TextEditingController(text: '0');
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.assignment_return_rounded, color: Colors.orange, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Retur Orderan', style: TextStyle(fontSize: 16)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Masukkan jumlah item yang ingin diretur. Stok akan otomatis bertambah.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    ...items.map((item) {
                      final id = item['item_id'] as int;
                      final int qty = item['quantity'] as int;
                      final int returnedQty = item['returned_qty'] as int? ?? 0;
                      final int maxRetur = qty - returnedQty;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] as String,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Beli: $qty  |  Sisa retur: $maxRetur',
                                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Tombol -
                            _qtyButton(
                              icon: Icons.remove,
                              onTap: () {
                                final current = int.tryParse(controllers[id]!.text) ?? 0;
                                if (current > 0) {
                                  setDialogState(() => controllers[id]!.text = (current - 1).toString());
                                }
                              },
                            ),
                            // Input angka
                            SizedBox(
                              width: 44,
                              child: TextField(
                                controller: controllers[id],
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (val) {
                                  final v = int.tryParse(val) ?? 0;
                                  if (v > maxRetur) {
                                    setDialogState(() => controllers[id]!.text = maxRetur.toString());
                                  }
                                },
                              ),
                            ),
                            // Tombol +
                            _qtyButton(
                              icon: Icons.add,
                              onTap: () {
                                final current = int.tryParse(controllers[id]!.text) ?? 0;
                                if (current < maxRetur) {
                                  setDialogState(() => controllers[id]!.text = (current + 1).toString());
                                }
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    for (final c in controllers.values) c.dispose();
                    Navigator.pop(ctx);
                  },
                  child: const Text('Batal'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Proses Retur'),
                  onPressed: () async {
                    // Kumpulkan qty retur per item
                    final Map<int, int> returQtyMap = {};
                    for (final item in items) {
                      final id = item['item_id'] as int;
                      final qty = int.tryParse(controllers[id]!.text) ?? 0;
                      if (qty > 0) returQtyMap[id] = qty;
                    }

                    if (returQtyMap.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Masukkan minimal 1 item untuk diretur'), backgroundColor: Colors.red),
                      );
                      return;
                    }

                    for (final c in controllers.values) c.dispose();
                    Navigator.pop(ctx);

                    await _processReturn(t, items, returQtyMap, sheetContext);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  /// Proses retur: update stok produk, update returned_qty, update status transaksi
  Future<void> _processReturn(
    Map<String, dynamic> t,
    List<Map<String, dynamic>> items,
    Map<int, int> returQtyMap, // item_id → qty retur baru
    BuildContext sheetContext,
  ) async {
    final db = await _db.database;

    try {
      await db.transaction((txn) async {
        for (final item in items) {
          final itemId = item['item_id'] as int;
          final productId = item['product_id'] as int;
          final returQty = returQtyMap[itemId] ?? 0;
          if (returQty <= 0) continue;

          // 1. Kembalikan stok produk
          await txn.rawUpdate(
            'UPDATE products SET stock = stock + ?, is_synced = 0 WHERE id = ?',
            [returQty, productId],
          );

          // 2. Update returned_qty di transaction_items
          final prevReturnedQty = item['returned_qty'] as int? ?? 0;
          await txn.rawUpdate(
            'UPDATE transaction_items SET returned_qty = ?, is_synced = 0 WHERE id = ?',
            [prevReturnedQty + returQty, itemId],
          );
        }

        // 3. Tentukan status transaksi baru
        // Re-fetch returned_qty terbaru setelah update
        final updatedItems = await txn.rawQuery(
          'SELECT quantity, returned_qty FROM transaction_items WHERE transaction_id = ?',
          [t['id']],
        );

        bool semuaRetur = updatedItems.every(
          (i) => (i['returned_qty'] as int? ?? 0) >= (i['quantity'] as int),
        );
        bool adaRetur = updatedItems.any(
          (i) => (i['returned_qty'] as int? ?? 0) > 0,
        );

        String newStatus = 'Selesai';
        if (semuaRetur) {
          newStatus = 'Retur';
        } else if (adaRetur) {
          newStatus = 'Retur Sebagian';
        }

        // 4. Update status transaksi
        await txn.rawUpdate(
          "UPDATE transactions SET status = ?, is_synced = 0 WHERE id = ?",
          [newStatus, t['id']],
        );
      });

      DatabaseService.hasUnsyncedChanges = true;
      _refresh();

      if (sheetContext.mounted) Navigator.pop(sheetContext); // tutup bottom sheet
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Retur berhasil! Stok produk telah dikembalikan.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal proses retur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ─── PAY SAVED ORDER ──────────────────────────────────────────────────────────

  void _showPaySavedOrderDialog(BuildContext context, Map<String, dynamic> t, List<Map<String, dynamic>> items) {
    final totalAmount = (t['total_amount'] as num).toDouble();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pelunasan Pesanan'),
        content: Text(
          'Selesaikan pembayaran pesanan ini secara Tunai sebesar:\n\n${currencyFormatter.format(totalAmount)}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () async {
              await _db.update('transactions', {
                'paid_amount': totalAmount,
                'payment_method': 'Tunai',
                'is_synced': 0,
              }, t['id']);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                _refresh();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pembayaran berhasil dicatat!'), backgroundColor: Colors.green),
                );

                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                final receiptService = ReceiptService();
                await receiptService.printReceipt(
                  authProvider.storeInfo,
                  t['id'],
                  totalAmount,
                  totalAmount,
                  0,
                  items.map((item) => {
                    'name': item['name'],
                    'quantity': item['quantity'],
                    'total': (item['total'] as num).toDouble(),
                  }).toList(),
                  paymentMethod: 'Tunai',
                  taxAmount: (t['tax_amount'] as num?)?.toDouble() ?? 0.0,
                  serviceChargeAmount: (t['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
                  taxPercentage: (t['tax_percentage'] as num?)?.toDouble(),
                  cashierName: t['cashier_name'] as String?,
                );
              }
            },
            child: const Text('Bayar & Cetak'),
          ),
        ],
      ),
    );
  }

  // ─── DETAIL BOTTOM SHEET ──────────────────────────────────────────────────────

  void _showTransactionDetails(Map<String, dynamic> t) async {
    final db = await _db.database;

    // Query dengan returned_qty dan item_id
    final items = await db.rawQuery('''
      SELECT ti.id as item_id, ti.product_id, p.name, ti.quantity,
             COALESCE(ti.returned_qty, 0) as returned_qty,
             ti.price_at_sale as price, (ti.price_at_sale * ti.quantity) as total
      FROM transaction_items ti
      JOIN products p ON ti.product_id = p.id
      WHERE ti.transaction_id = ?
    ''', [t['id']]);

    // Pastikan field aman
    final List<Map<String, dynamic>> safeItems = items.map((item) {
      final m = Map<String, dynamic>.from(item);
      m['returned_qty'] ??= 0;
      return m;
    }).toList();

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
      builder: (sheetContext) {
        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        final date = DateTime.parse(t['created_at']);
        final double kembalian = (t['paid_amount'] as num).toDouble() - (t['total_amount'] as num).toDouble();
        final bool isUnpaid = (t['paid_amount'] as num).toDouble() < (t['total_amount'] as num).toDouble();
        final String status = t['status'] as String? ?? 'Selesai';
        final bool isRetur = status == 'Retur';
        final bool isOwner = Provider.of<AuthProvider>(sheetContext, listen: false).isOwner;

        return DraggableScrollableSheet(
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle bar
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
                  // Title + status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Detail Transaksi #${t['id']}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(status),
                    ],
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
                  ...safeItems.map((item) {
                    final int returnedQty = item['returned_qty'] as int? ?? 0;
                    final bool itemRetur = returnedQty > 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${item['name']} (x${item['quantity']})'),
                                if (itemRetur)
                                  Text(
                                    'Diretur: $returnedQty',
                                    style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w500),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            currencyFormatter.format(item['total']),
                            style: TextStyle(
                              decoration: isRetur ? TextDecoration.lineThrough : null,
                              color: isRetur ? Colors.grey : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 24),
                  if ((t['tax_amount'] as num?)?.toDouble() != null && (t['tax_amount'] as num).toDouble() > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pajak (PPN)'),
                        Text('+ ${currencyFormatter.format(t['tax_amount'])}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if ((t['service_charge_amount'] as num?)?.toDouble() != null && (t['service_charge_amount'] as num).toDouble() > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biaya Lainnya'),
                        Text('+ ${currencyFormatter.format(t['service_charge_amount'])}'),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
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
                        Text(
                          '$customerName${customerPhone != null && customerPhone.isNotEmpty ? " ($customerPhone)" : ""}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (t['cashier_name'] != null && (t['cashier_name'] as String).isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kasir'),
                        Text(t['cashier_name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Metode Pembayaran'),
                      Text(
                        t['payment_method'] ?? 'Tunai',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isUnpaid ? Colors.orange : Colors.black87,
                        ),
                      ),
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

                  // ── Action Buttons ──
                  if (isUnpaid)
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.payment),
                            label: const Text('Bayar Sekarang', style: TextStyle(fontSize: 16)),
                            onPressed: () {
                              Navigator.pop(sheetContext);
                              _showPaySavedOrderDialog(context, t, safeItems);
                            },
                          ),
                        ),
                      ],
                    )
                  else ...[
                    // Row 1: Hapus + Cetak + Bagikan
                    Row(
                      children: [
                        if (isOwner) ...[
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[50],
                                foregroundColor: Colors.red,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Hapus'),
                              onPressed: () => _confirmDelete(sheetContext, t['id']),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
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
                                safeItems.map((item) => {
                                  'name': item['name'],
                                  'quantity': item['quantity'],
                                  'total': (item['total'] as num).toDouble(),
                                }).toList(),
                                paymentMethod: t['payment_method'] ?? 'Tunai',
                                taxAmount: (t['tax_amount'] as num?)?.toDouble() ?? 0.0,
                                serviceChargeAmount: (t['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
                                taxPercentage: (t['tax_percentage'] as num?)?.toDouble(),
                                cashierName: t['cashier_name'] as String?,
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
                                safeItems.map((item) => {
                                  'name': item['name'],
                                  'quantity': item['quantity'],
                                  'total': (item['total'] as num).toDouble(),
                                }).toList(),
                                paymentMethod: t['payment_method'] ?? 'Tunai',
                                taxAmount: (t['tax_amount'] as num?)?.toDouble() ?? 0.0,
                                serviceChargeAmount: (t['service_charge_amount'] as num?)?.toDouble() ?? 0.0,
                                taxPercentage: (t['tax_percentage'] as num?)?.toDouble(),
                                cashierName: t['cashier_name'] as String?,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    // Row 2: Tombol Retur (owner only, jika belum full retur)
                    if (isOwner && !isRetur) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.orange[800],
                            side: BorderSide(color: Colors.orange[400]!),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.assignment_return_rounded),
                          label: const Text('Retur Orderan'),
                          onPressed: () => _showReturDialog(sheetContext, t, safeItems),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Badge berwarna berdasarkan status transaksi
  Widget _statusBadge(String status) {
    Color bgColor;
    Color textColor;
    IconData icon;

    switch (status) {
      case 'Retur':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        icon = Icons.assignment_return_rounded;
        break;
      case 'Retur Sebagian':
        bgColor = Colors.amber[100]!;
        textColor = Colors.amber[800]!;
        icon = Icons.assignment_return_outlined;
        break;
      default:
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        icon = Icons.check_circle_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(status, style: TextStyle(fontSize: 11, color: textColor, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Riwayat Transaksi', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _transactionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Belum ada transaksi', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ],
              ),
            );
          }

          final transactions = snapshot.data!;

          // Group by Date
          final Map<String, List<Map<String, dynamic>>> grouped = {};
          for (var t in transactions) {
            final date = DateTime.parse(t['created_at']);
            final dateStr = DateFormat('dd MMMM yyyy').format(date);
            grouped.putIfAbsent(dateStr, () => []).add(t);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: grouped.keys.length,
            itemBuilder: (context, index) {
              final dateStr = grouped.keys.elementAt(index);
              final dailyTransactions = grouped[dateStr]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      dateStr,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black54),
                    ),
                  ),
                  ...dailyTransactions.map((t) {
                    final date = DateTime.parse(t['created_at']);
                    final timeStr = DateFormat('HH:mm').format(date);
                    final paymentMethod = t['payment_method'] ?? 'Tunai';
                    final bool isUnpaid = (t['paid_amount'] as num).toDouble() < (t['total_amount'] as num).toDouble();
                    final String status = t['status'] as String? ?? 'Selesai';
                    final bool isRetur = status == 'Retur';
                    final bool isReturSebagian = status == 'Retur Sebagian';

                    Color iconBg = isRetur
                        ? Colors.orange[50]!
                        : isReturSebagian
                            ? Colors.amber[50]!
                            : Colors.green[50]!;
                    Color iconColor = isRetur
                        ? Colors.orange
                        : isReturSebagian
                            ? Colors.amber[700]!
                            : Colors.green;
                    IconData iconData = isRetur || isReturSebagian
                        ? Icons.assignment_return_rounded
                        : Icons.receipt_long;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isRetur
                              ? Colors.orange[200]!
                              : isReturSebagian
                                  ? Colors.amber[200]!
                                  : Colors.grey[200]!,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showTransactionDetails(t),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: iconBg,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(iconData, color: iconColor),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          'Transaksi #${t['id']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        if (isRetur || isReturSebagian) _statusBadge(status),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                                        const SizedBox(width: 4),
                                        Text(timeStr, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                        const SizedBox(width: 12),
                                        Icon(
                                          paymentMethod == 'Tunai' ? Icons.money : (isUnpaid ? Icons.save : Icons.credit_card),
                                          size: 14,
                                          color: isUnpaid ? Colors.red : Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            paymentMethod,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: isUnpaid ? Colors.red : Colors.grey[600],
                                              fontSize: 13,
                                              fontWeight: isUnpaid ? FontWeight.bold : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                currencyFormatter.format(t['total_amount']),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isRetur ? Colors.orange : isUnpaid ? Colors.red : Colors.green,
                                  decoration: isRetur ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
