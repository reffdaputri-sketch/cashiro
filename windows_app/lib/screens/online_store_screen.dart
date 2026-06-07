import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/auth_provider.dart';
import 'package:cashiro/services/api_service.dart';
import 'package:cashiro/screens/master_data_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cashiro/services/database_service.dart';
import 'package:cashiro/providers/shift_provider.dart';
import 'package:cashiro/services/receipt_service.dart';

class OnlineStoreScreen extends StatefulWidget {
  const OnlineStoreScreen({super.key});

  @override
  State<OnlineStoreScreen> createState() => _OnlineStoreScreenState();
}

class _OnlineStoreScreenState extends State<OnlineStoreScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;

  bool _loading = true;
  String? _slug;
  double _balance = 0;
  List<dynamic> _products = [];
  List<dynamic> _orders = [];
  String? _error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Auto-refresh when switching tabs (e.g. going to Products tab)
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _slug != null && !_loading) {
        // Refresh silently when landing on a tab
        _refreshData();
      }
    });

    _initSeller();
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!_loading && _slug != null && mounted) {
        _refreshData();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initSeller() async {
    setState(() { _loading = true; _error = null; });
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeId = auth.storeInfo['storeId'] ?? '';

      if (storeId.isEmpty || storeId == 'DEMO-STORE-ID') {
        setState(() { _error = 'Fitur ini hanya tersedia untuk toko yang sudah terdaftar dengan lisensi aktif.'; _loading = false; });
        return;
      }

      // Aktivasi / ambil slug seller
      final result = await _api.activateSeller(storeId);
      _slug = result['slug'];

      // Ambil produk dan saldo
      await _refreshData();
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _refreshData() async {
    if (_slug == null) return;
    
    // Gunakan Future.wait agar request berjalan paralel (jauh lebih cepat)
    final results = await Future.wait([
      _api.getSellerProducts(_slug!), // Mengambil semua produk termasuk yg nonaktif
      _api.getSellerBalance(_slug!),
      _api.getSellerOrders(_slug!),
    ]);
    
    if (!mounted) return; // Mencegah error setState setelah layar ditutup

    final fetchedOrders = results[2] as List<dynamic>;
    await _syncPaidOrdersToLocal(fetchedOrders);

    setState(() {
      _products = (results[0] as Map<String, dynamic>)['products'] ?? [];
      _balance = results[1] as double;
      _orders = fetchedOrders;
    });
  }

  Future<void> _syncPaidOrdersToLocal(List<dynamic> orders) async {
    final dbService = DatabaseService();
    final db = await dbService.database;
    bool hasNewLocalTransactions = false;

    for (var o in orders) {
      if (o['status'] == 'paid') {
        final orderId = o['id'];
        final existing = await db.query('transactions', where: 'payment_method = ?', whereArgs: ['Toko Online #$orderId']);
        if (existing.isEmpty) {
          await db.transaction((txn) async {
            final total = (o['total_amount'] as num).toDouble();
            int? shiftId;
            try {
              if (mounted) {
                shiftId = Provider.of<ShiftProvider>(context, listen: false).activeShift?['id'] as int?;
              }
            } catch (e) {
              debugPrint('Error getting active shift: $e');
            }

            final transactionId = await txn.insert('transactions', {
              'total_amount': total,
              'paid_amount': total,
              'created_at': o['created_at'] ?? DateTime.now().toIso8601String(),
              'payment_method': 'Toko Online #$orderId',
              'shift_id': shiftId,
              'is_synced': 0
            });

            if (o['items'] is List) {
              for (var item in o['items']) {
                final productId = item['product_id'];
                final productRows = await txn.query('products', columns: ['cost_price'], where: 'id = ?', whereArgs: [productId]);
                double cost = 0.0;
                if (productRows.isEmpty) {
                  await txn.insert('products', {
                    'id': productId,
                    'name': item['name'] ?? 'Produk Toko Online',
                    'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                    'stock': 0,
                    'created_at': DateTime.now().toIso8601String(),
                  });
                } else {
                  cost = (productRows.first['cost_price'] as num?)?.toDouble() ?? 0.0;
                }

                await txn.insert('transaction_items', {
                  'transaction_id': transactionId,
                  'product_id': productId,
                  'quantity': item['qty'],
                  'price_at_sale': (item['price'] as num?)?.toDouble() ?? 0.0,
                  'cost_at_sale': cost,
                  'is_synced': 0
                });
              }
            }
          });
          hasNewLocalTransactions = true;
          debugPrint('Sync: Online Store Order #$orderId automatically synced to local transactions.');
        }
      }
    }

    if (hasNewLocalTransactions) {
      DatabaseService.hasUnsyncedChanges = true;
      if (mounted) {
        try {
          Provider.of<ShiftProvider>(context, listen: false).checkActiveShift();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan online yang lunas otomatis disinkronkan ke Laporan POS!'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          debugPrint('Error updating shift or showing snackbar: $e');
        }
      }
    }
  }

  String _formatRupiah(dynamic n) {
    final double value = n is double ? n : (n is int ? n.toDouble() : double.tryParse(n.toString()) ?? 0.0);
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  String _storeUrl() => 'https://cashiro.web.id/store/$_slug';

  void _copyLink() {
    Clipboard.setData(ClipboardData(text: _storeUrl()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔗 Link toko berhasil disalin!'),
        backgroundColor: Color(0xFF006d77),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = const Color(0xFF006d77);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toko Online')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Toko Online')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.store_mall_directory_outlined, size: 72, color: Colors.grey),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Toko Online'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: const Color(0xFFffb703),
          tabs: [
            const Tab(icon: Icon(Icons.inventory_2_outlined), text: 'Produk'),
            Tab(
              icon: Stack(
                children: [
                  const Icon(Icons.shopping_bag_outlined),
                  if (_orders.any((o) => o['status'] == 'pending'))
                    Positioned(
                      right: 0, top: 0,
                      child: Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: Color(0xFFffb703), shape: BoxShape.circle),
                      ),
                    ),
                ],
              ),
              text: 'Pesanan',
            ),
            const Tab(icon: Icon(Icons.link_outlined), text: 'Link Toko'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildProductsTab(primary),
          _buildOrdersTab(primary),
          _buildLinkTab(primary),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
              backgroundColor: primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Tambah Produk'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MasterDataScreen()),
                ).then((_) => _refreshData());
              },
            )
          : null,
    );
  }

  // ─── TAB PRODUK ───
  Widget _buildProductsTab(Color primary) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _products.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Column(children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                    SizedBox(height: 12),
                    Text('Belum ada produk.\nTambahkan produk pertama Anda!',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
                  ]),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _products.length,
              itemBuilder: (ctx, i) {
                final p = _products[i];
                final isActive = p['is_active'] == true;
                final stock = p['stock'] as int? ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: (p['image_url'] != null && p['image_url'].isNotEmpty)
                          ? Image.network(p['image_url'], width: 52, height: 52, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _productPlaceholder())
                          : _productPlaceholder(),
                    ),
                    title: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_formatRupiah(p['price']),
                            style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(children: [
                          _stockChip(stock),
                          const SizedBox(width: 8),
                          if (!isActive) _chip('Nonaktif', Colors.red.shade100, Colors.red.shade700),
                        ]),
                      ],
                    ),
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: 'toggle',
                            child: Text(isActive ? '❌ Nonaktifkan' : '✅ Aktifkan')),
                      ],
                      onSelected: (val) async {
                        if (val == 'toggle') {
                          await _api.updateSellerProduct(
                            slug: _slug!,
                            storeId: Provider.of<AuthProvider>(context, listen: false).storeInfo['storeId'] ?? '',
                            productId: p['id'],
                            isActive: !isActive,
                          );
                          _refreshData();
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _productPlaceholder() => Container(
    width: 52, height: 52,
    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(10)),
    child: const Icon(Icons.inventory_2, color: Colors.grey, size: 28),
  );

  Widget _stockChip(int stock) {
    Color bg, fg;
    String label;
    if (stock == 0) { bg = Colors.red.shade100; fg = Colors.red.shade700; label = 'Habis'; }
    else if (stock <= 5) { bg = Colors.orange.shade100; fg = Colors.orange.shade700; label = 'Sisa $stock'; }
    else { bg = Colors.green.shade100; fg = Colors.green.shade700; label = '$stock pcs'; }
    return _chip(label, bg, fg);
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.bold)),
  );

  // ─── TAB PESANAN ───
  Widget _buildOrdersTab(Color primary) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: _orders.isEmpty
          ? ListView(children: const [
              SizedBox(height: 120),
              Center(child: Column(children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Belum ada pesanan masuk', style: TextStyle(color: Colors.grey)),
              ])),
            ])
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (ctx, i) {
                final o = _orders[i];
                final status = o['status'] as String? ?? 'pending';
                final method = o['payment_method'] as String? ?? 'manual';
                final createdAt = o['created_at'] != null
                    ? DateFormat('dd MMM yy, HH:mm').format(DateTime.parse(o['created_at']).toLocal())
                    : '-';
                final isDineIn = o['order_type'] == 'dine_in';
                final tableNum = o['table_number'] != null ? o['table_number'].toString() : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showOrderDetail(context, o, primary),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Expanded(child: Text('#${o['id']} · ${o['customer_name']?.isNotEmpty == true ? o['customer_name'] : 'Anonim'}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                            if (isDineIn && tableNum != null)
                              Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '🍽️ Meja $tableNum',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange.shade800,
                                  ),
                                ),
                              ),
                            _statusChip(status),
                          ]),
                          if ((o['customer_phone'] ?? '').isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('📱 ${o['customer_phone']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                          const SizedBox(height: 4),
                          Text('🕐 $createdAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const Divider(height: 16),
                          // Items summary (max 2)
                          if (o['items'] is List)
                            ...List.from(o['items']).take(2).map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${item['name']} ×${item['qty']}',
                                      style: const TextStyle(fontSize: 13)),
                                  Text(_formatRupiah(item['total'] ?? 0),
                                      style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            )),
                          if ((o['items'] as List?)?.length != null && (o['items'] as List).length > 2)
                            const Text('...', style: TextStyle(color: Colors.grey)),
                          const Divider(height: 12),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Row(children: [
                              Icon(method == 'qris' ? Icons.qr_code : Icons.payments_outlined, size: 16, color: Colors.grey),
                              const SizedBox(width: 4),
                              Text(method == 'qris' ? 'QRIS' : 'Manual', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ]),
                            Text(_formatRupiah(o['total_amount'] ?? 0),
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primary)),
                          ]),
                        ]),
                      ),
                    ),
                );
              },
            ),
    );
  }

  Widget _statusChip(String status) {
    Color bg, fg;
    String label;
    switch (status) {
      case 'paid': bg = Colors.green.shade100; fg = Colors.green.shade700; label = '✅ Lunas'; break;
      case 'cancelled': bg = Colors.red.shade100; fg = Colors.red.shade700; label = '❌ Batal'; break;
      case 'processing': bg = Colors.blue.shade100; fg = Colors.blue.shade700; label = '⚙️ Proses'; break;
      default: bg = Colors.orange.shade100; fg = Colors.orange.shade700; label = '⏳ Pending';
    }
    return _chip(label, bg, fg);
  }

  void _showOrderDetail(BuildContext context, Map<String, dynamic> o, Color primary) {
    final status = o['status'] as String? ?? 'pending';
    final method = o['payment_method'] as String? ?? 'manual';
    final createdAt = o['created_at'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(o['created_at']).toLocal())
        : '-';
    final address = o['customer_address'] as String? ?? '';
    final phone = o['customer_phone'] as String? ?? '';
    final notes = o['notes'] as String? ?? '';
    final shippingCost = (o['shipping_cost'] as num?)?.toDouble() ?? 0.0;
    final courierName = o['courier_name'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final status = o['status'] as String? ?? 'pending';
          return DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) => Padding(
              padding: const EdgeInsets.all(24),
              child: ListView(
                controller: scrollController,
                children: [
                  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Detail Pesanan #${o['id']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Status Saat Ini', style: TextStyle(color: Colors.grey)),
                  _statusChip(status),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Ubah Status:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _statusOption(ctx, o, 'pending', '⏳ Pending', status, setSheetState),
                  _statusOption(ctx, o, 'processing', '⚙️ Proses', status, setSheetState),
                  _statusOption(ctx, o, 'paid', '✅ Lunas', status, setSheetState),
                  _statusOption(ctx, o, 'cancelled', '❌ Batal', status, setSheetState),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tipe Pesanan', style: TextStyle(color: Colors.grey)),
                  Text(o['order_type'] == 'dine_in' ? '🍽️ Makan di Tempat (Dine-in)' : '🛵 Kirim / Delivery', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              if (o['order_type'] == 'dine_in' && o['table_number'] != null) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nomor Meja', style: TextStyle(color: Colors.grey)),
                    Text('Meja ${o['table_number']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Waktu', style: TextStyle(color: Colors.grey)),
                  Text(createdAt, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Metode', style: TextStyle(color: Colors.grey)),
                  Text(method == 'qris' ? 'QRIS Otomatis' : 'Manual / COD', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              
              const SizedBox(height: 24),
              const Text('Info Pembeli', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _detailRow(Icons.person, o['customer_name']?.isNotEmpty == true ? o['customer_name'] : 'Anonim'),
              _detailRow(Icons.phone, phone.isNotEmpty ? phone : '-'),
              _detailRow(Icons.location_on, address.isNotEmpty ? address : 'Tidak ada alamat'),
              
              if (address.isNotEmpty || phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (phone.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final formattedPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone.replaceAll(RegExp(r'[^0-9]'), '');
                            final url = Uri.parse('https://wa.me/$formattedPhone');
                            if (await canLaunchUrl(url)) {
                              await launchUrl(url, mode: LaunchMode.externalApplication);
                            }
                          },
                          icon: const Icon(Icons.chat, size: 16, color: Colors.green),
                          label: const Text('Chat WA', style: TextStyle(color: Colors.green)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.green)),
                        ),
                      ),
                    if (phone.isNotEmpty && address.isNotEmpty) const SizedBox(width: 8),
                    if (address.isNotEmpty)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: address));
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Alamat disalin')));
                          },
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy Alamat'),
                        ),
                      ),
                  ],
                ),
              ],
              
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final receiptService = ReceiptService();
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    final storeInfo = auth.storeInfo;
                    
                    final rawItems = o['items'] as List? ?? [];
                    final List<Map<String, dynamic>> itemsToPrint = rawItems.map((item) {
                      return {
                        'name': item['name'] ?? '',
                        'quantity': (item['qty'] as num?)?.toInt() ?? 1,
                        'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                        'total': (item['total'] as num?)?.toDouble() ?? 0.0,
                        'discount': (item['discount'] as num?)?.toDouble() ?? 0.0,
                      };
                    }).toList();

                    await receiptService.printReceipt(
                      storeInfo,
                      o['id'] as int? ?? 0,
                      (o['total_amount'] as num?)?.toDouble() ?? 0.0,
                      (o['total_amount'] as num?)?.toDouble() ?? 0.0,
                      0.0,
                      itemsToPrint,
                      paymentMethod: method == 'qris' ? 'QRIS' : 'Manual',
                    );
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Cetak Tiket Dapur / Struk'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),

              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.note, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Catatan: $notes', style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              const Text('Daftar Item', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                child: Column(
                  children: [
                    if (o['items'] is List)
                      ...List.from(o['items']).map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${item['name']} ×${item['qty']}'),
                            Text(_formatRupiah(item['total'] ?? 0)),
                          ],
                        ),
                      )),
                    if (shippingCost > 0) ...[
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ongkos Kirim (${courierName.isNotEmpty ? courierName : 'Kurir'})'),
                          Text(_formatRupiah(shippingCost)),
                        ],
                      ),
                    ],
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text(_formatRupiah(o['total_amount'] ?? 0), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: primary)),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      );
    },
    ),
    );
  }

  Widget _statusOption(BuildContext ctx, Map<String, dynamic> o, String value, String label, String currentStatus, StateSetter setSheetState) {
    final isSelected = currentStatus == value;
    final primary = const Color(0xFF006d77);
    return InkWell(
      onTap: isSelected ? null : () async {
        final oldStatus = o['status'];
        // Optimistic update
        setSheetState(() => o['status'] = value);
        setState(() {}); 

        try {
          await _api.updateSellerOrderStatus(slug: _slug!, orderId: o['id'], status: value);
          
          if (value == 'paid') {
            final dbService = DatabaseService();
            final db = await dbService.database;
            
            final existing = await db.query('transactions', where: 'payment_method = ?', whereArgs: ['Toko Online #${o['id']}']);
            if (existing.isEmpty) {
              await db.transaction((txn) async {
                 final total = (o['total_amount'] as num).toDouble();
                 int? shiftId;
                 if (ctx.mounted) {
                   shiftId = Provider.of<ShiftProvider>(ctx, listen: false).activeShift?['id'] as int?;
                 }
                 
                 final transactionId = await txn.insert('transactions', {
                   'total_amount': total,
                   'paid_amount': total,
                   'created_at': DateTime.now().toIso8601String(),
                   'payment_method': 'Toko Online #${o['id']}',
                   'shift_id': shiftId,
                   'is_synced': 0
                 });
                 
                 if (o['items'] is List) {
                   for (var item in o['items']) {
                      final productId = item['product_id'];
                      final productRows = await txn.query('products', columns: ['cost_price'], where: 'id = ?', whereArgs: [productId]);
                      double cost = 0.0;
                      if (productRows.isEmpty) {
                        await txn.insert('products', {
                          'id': productId,
                          'name': item['name'] ?? 'Produk Toko Online',
                          'price': (item['price'] as num?)?.toDouble() ?? 0.0,
                          'stock': 0,
                          'created_at': DateTime.now().toIso8601String(),
                        });
                      } else {
                        cost = (productRows.first['cost_price'] as num?)?.toDouble() ?? 0.0;
                      }
                      
                      await txn.insert('transaction_items', {
                         'transaction_id': transactionId,
                         'product_id': productId,
                         'quantity': item['qty'],
                         'price_at_sale': (item['price'] as num?)?.toDouble() ?? 0.0,
                         'cost_at_sale': cost,
                         'is_synced': 0
                      });
                   }
                 }
              });
              DatabaseService.hasUnsyncedChanges = true;
              if (ctx.mounted) {
                Provider.of<ShiftProvider>(ctx, listen: false).checkActiveShift();
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Pesanan otomatis masuk ke Laporan POS!'), backgroundColor: Colors.green));
              }
            }
          }
          
          // refresh silently in background
          _refreshData();
        } catch (e) {
          // Revert on error
          setSheetState(() => o['status'] = oldStatus);
          setState(() {});
          if (ctx.mounted) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Gagal update: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.red));
          }
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? primary : Colors.grey.shade300),
          boxShadow: isSelected ? [BoxShadow(color: primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // ─── TAB LINK TOKO ───
  Widget _buildLinkTab(Color primary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Saldo card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF006d77), Color(0xFF004d55)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💰 Saldo Toko Online', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 8),
            Text(_formatRupiah(_balance),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('/${_slug ?? '-'}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Link toko
        const Text('🔗 Link Toko Online', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        const Text('Bagikan link ini ke pelanggan agar mereka bisa melihat dan memesan produk Anda.',
            style: TextStyle(color: Colors.grey, fontSize: 13)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(children: [
            Expanded(
              child: Text(_storeUrl(),
                  style: const TextStyle(color: Color(0xFF006d77), fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _copyLink,
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Salin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showEditSlugDialog,
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Ubah Link'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(_storeUrl());
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('Buka Toko'),
                style: ElevatedButton.styleFrom(backgroundColor: primary, foregroundColor: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Tips
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡 Tips Bagikan Link', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),
            ...[
              '📱 WhatsApp: Kirim link ke grup atau kontak pelanggan',
              '📸 Instagram: Tambahkan link di bio profil Anda',
              '🔖 Status WA: Bagikan sebagai status promosi',
            ].map((tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('• $tip', style: const TextStyle(fontSize: 13, color: Colors.black87)),
            )),
          ]),
        ),

        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh Data'),
          ),
        ),
      ]),
    );
  }

  void _showEditSlugDialog() {
    final ctrl = TextEditingController(text: _slug);
    bool saving = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Ubah Link Toko'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan nama link baru untuk toko Anda (tanpa spasi).', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  prefixText: 'cashiro.web.id/store/',
                  prefixStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final newSlug = ctrl.text.trim();
                if (newSlug.isEmpty || newSlug == _slug) return;
                setDialogState(() => saving = true);
                try {
                  final updatedSlug = await _api.updateSellerSlug(_slug!, newSlug);
                  setState(() => _slug = updatedSlug);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Link berhasil diubah!')));
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                  }
                } finally {
                  setDialogState(() => saving = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006d77), foregroundColor: Colors.white),
              child: saving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }
}
