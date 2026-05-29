import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/services/api_service.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initSeller();
  }

  @override
  void dispose() {
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
    final info = await _api.getSellerInfo(_slug!);
    final balance = await _api.getSellerBalance(_slug!);
    final orders = await _api.getSellerOrders(_slug!);
    setState(() {
      _products = info['products'] ?? [];
      _balance = balance;
      _orders = orders;
    });
  }

  String _formatRupiah(dynamic n) {
    final double value = n is double ? n : (n is int ? n.toDouble() : double.tryParse(n.toString()) ?? 0.0);
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(value);
  }

  String _storeUrl() => 'https://cashiro.vercel.app/store/$_slug';

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
              onPressed: () => _showProductForm(context, null),
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
                        const PopupMenuItem(value: 'edit', child: Text('✏️ Edit')),
                        PopupMenuItem(
                            value: 'toggle',
                            child: Text(isActive ? '❌ Nonaktifkan' : '✅ Aktifkan')),
                      ],
                      onSelected: (val) async {
                        if (val == 'edit') _showProductForm(context, p);
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
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text('#${o['id']} · ${o['customer_name']?.isNotEmpty == true ? o['customer_name'] : 'Anonim'}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                        _statusChip(status),
                      ]),
                      if ((o['customer_phone'] ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('📱 ${o['customer_phone']}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                      const SizedBox(height: 4),
                      Text('🕐 $createdAt', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      const Divider(height: 16),
                      // Items
                      if (o['items'] is List)
                        ...List.from(o['items']).map((item) => Padding(
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
      default: bg = Colors.orange.shade100; fg = Colors.orange.shade700; label = '⏳ Pending';
    }
    return _chip(label, bg, fg);
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

  // ─── FORM PRODUK ───
  void _showProductForm(BuildContext context, Map<String, dynamic>? product) {
    final nameCtrl = TextEditingController(text: product?['name'] ?? '');
    final descCtrl = TextEditingController(text: product?['description'] ?? '');
    final priceCtrl = TextEditingController(text: product != null ? '${product['price']}' : '');
    final stockCtrl = TextEditingController(text: product != null ? '${product['stock']}' : '');
    final imageCtrl = TextEditingController(text: product?['image_url'] ?? '');
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(product == null ? '➕ Tambah Produk' : '✏️ Edit Produk',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
              ]),
              const SizedBox(height: 16),
              _formField('Nama Produk *', nameCtrl, 'Nama produk'),
              const SizedBox(height: 12),
              _formField('Deskripsi', descCtrl, 'Deskripsi singkat', maxLines: 2),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _formField('Harga (Rp) *', priceCtrl, '0', isNumber: true)),
                const SizedBox(width: 12),
                Expanded(child: _formField('Stok', stockCtrl, '0', isNumber: true)),
              ]),
              const SizedBox(height: 12),
              _formField('URL Gambar', imageCtrl, 'https://...'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saving ? null : () async {
                    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nama dan harga wajib diisi'), backgroundColor: Colors.red));
                      return;
                    }
                    setSheetState(() => saving = true);
                    try {
                      final storeId = Provider.of<AuthProvider>(context, listen: false).storeInfo['storeId'] ?? '';
                      if (product == null) {
                        await _api.addSellerProduct(
                          slug: _slug!, storeId: storeId,
                          name: nameCtrl.text, description: descCtrl.text,
                          price: double.tryParse(priceCtrl.text) ?? 0,
                          stock: int.tryParse(stockCtrl.text) ?? 0,
                          imageUrl: imageCtrl.text,
                        );
                      } else {
                        await _api.updateSellerProduct(
                          slug: _slug!, storeId: storeId, productId: product['id'],
                          name: nameCtrl.text, description: descCtrl.text,
                          price: double.tryParse(priceCtrl.text),
                          stock: int.tryParse(stockCtrl.text),
                          imageUrl: imageCtrl.text,
                        );
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      _refreshData();
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      }
                    } finally {
                      setSheetState(() => saving = false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006d77),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(saving ? 'Menyimpan...' : (product == null ? 'Tambah Produk' : 'Simpan Perubahan'),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, String hint,
      {int maxLines = 1, bool isNumber = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]);
  }
}
