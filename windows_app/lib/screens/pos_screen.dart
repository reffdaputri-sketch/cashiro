import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cashiro/providers/product_provider.dart';
import 'package:cashiro/providers/cart_provider.dart';
import 'package:cashiro/providers/category_provider.dart';
import 'package:cashiro/providers/auth_provider.dart';
import 'package:cashiro/providers/shift_provider.dart';
import 'package:cashiro/screens/cart_screen.dart';
import 'package:cashiro/models/product.dart';
import 'package:cashiro/models/product_variation.dart';
import 'package:cashiro/models/cart_item.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

import 'dart:io';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cashiro/screens/scanner_screen.dart';
import 'package:cashiro/screens/active_orders_screen.dart';
import 'package:cashiro/screens/kitchen_screen.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cashiro/services/database_service.dart';
import 'package:cashiro/services/sync_service.dart';
import 'package:cashiro/services/api_service.dart';
import 'package:cashiro/screens/online_store_screen.dart';

class POSScreen extends StatefulWidget {
  const POSScreen({super.key});

  @override
  State<POSScreen> createState() => _POSScreenState();
}

class _POSScreenState extends State<POSScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Semua';
  bool _isSearching = false;
  bool _isRetailMode = false;
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  String _barcodeBuffer = '';
  DateTime? _lastScanTime;
  
  Timer? _readyPollTimer;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Set<int> _previousReadyIds = {};
  Set<int> _previousOnlineOrderIds = {};
  String? _storeSlug;
  final DatabaseService _db = DatabaseService();

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    _loadRetailModePref();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final cashierName = auth.currentStaff?.name ?? auth.storeInfo['ownerName'] ?? 'Owner';
      Provider.of<CategoryProvider>(context, listen: false).fetchCategories();
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
      Provider.of<ShiftProvider>(context, listen: false).checkActiveShift(cashierName);
    });
    
    // Polling for Ready Orders
    _pollReadyOrders(firstLoad: true);
    _readyPollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _pollReadyOrders(firstLoad: false);
    });
  }

  void _showTableSelection(BuildContext context, CartProvider cart) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final totalTablesStr = auth.storeInfo['totalTables'];
    final totalTables = int.tryParse(totalTablesStr ?? '0') ?? 0;

    if (totalTables == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Jumlah meja belum diatur di Pengaturan Toko.')));
      return;
    }

    final db = await _db.database;
    final draftTxns = await db.query('transactions', where: "status = 'Draft' AND table_number IS NOT NULL AND table_number != ''");
    final occupiedTables = draftTxns.map((t) => t['table_number'].toString()).toSet();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('Pilih Meja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: totalTables,
                  itemBuilder: (ctx, index) {
                    final tableStr = (index + 1).toString();
                    final isOccupied = occupiedTables.contains(tableStr) && cart.tableNumber != tableStr;

                    return InkWell(
                      onTap: isOccupied ? null : () {
                        cart.setTableNumber(cart.tableNumber == tableStr ? null : tableStr);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isOccupied ? Colors.grey[300] : (cart.tableNumber == tableStr ? Colors.blue : Colors.white),
                          border: Border.all(color: isOccupied ? Colors.grey : Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          tableStr,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isOccupied ? Colors.grey[600] : (cart.tableNumber == tableStr ? Colors.white : Colors.blue),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _readyPollTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _pollReadyOrders({required bool firstLoad}) async {
    try {
      if (!firstLoad) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        final storeId = auth.storeInfo['storeId'];
        final licenseKey = auth.storeInfo['licenseKey'];
        if (storeId != null && licenseKey != null && storeId != 'DEMO-STORE-ID') {
          await SyncService().downloadAllCloudData(storeId, licenseKey);
          
          // Poll Online Store Orders
          if (_storeSlug == null) {
            try {
              final result = await ApiService().activateSeller(storeId);
              _storeSlug = result['slug'];
            } catch (_) {}
          }
          
          if (_storeSlug != null) {
            try {
              final orders = await ApiService().getSellerOrders(_storeSlug!);
              final pendingOrders = orders.where((o) => o['status'] == 'pending').map((o) => o['id'] as int).toSet();
              
              final newOnlineIds = pendingOrders.difference(_previousOnlineOrderIds);
              if (newOnlineIds.isNotEmpty && mounted) {
                 _audioPlayer.play(AssetSource('sounds/notification.wav'));
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                   content: Text('Pesanan Online Baru! Ada ${newOnlineIds.length} pesanan baru dari Toko Online 🔔', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                   backgroundColor: Colors.blue[700],
                   duration: const Duration(seconds: 5),
                   action: SnackBarAction(
                     label: 'LIHAT',
                     textColor: Colors.white,
                     onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const OnlineStoreScreen()));
                     },
                   ),
                 ));
              }
              _previousOnlineOrderIds = pendingOrders;
            } catch (_) {}
          }
        }
      }

      final db = await _db.database;
      final results = await db.query(
        'transactions',
        columns: ['id'],
        where: 'kitchen_status = ?',
        whereArgs: ['Ready'],
      );
      
      Set<int> currentIds = results.map((e) => e['id'] as int).toSet();
      
      if (!firstLoad) {
        final newIds = currentIds.difference(_previousReadyIds);
        if (newIds.isNotEmpty && mounted) {
          _audioPlayer.play(AssetSource('sounds/ready.wav'));
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Pesanan Selesai! Ada ${newIds.length} pesanan siap dijemput 🚀', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'LIHAT',
              textColor: Colors.white,
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ActiveOrdersScreen()));
              },
            ),
          ));
        }
      }
      _previousReadyIds = currentIds;
    } catch (e) {
      debugPrint('Error polling ready orders: $e');
    }
  }

  bool _onKeyEvent(KeyEvent event) {
    if (!mounted) return false;
    
    // Abaikan jika sedang mengetik di kolom pencarian
    if (_searchFocusNode.hasFocus) {
      return false;
    }

    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
        if (_barcodeBuffer.isNotEmpty) {
          final scannedBarcode = _barcodeBuffer;
          _barcodeBuffer = '';
          _handleScannerInput(scannedBarcode);
          return true;
        }
      } else {
        String? char = event.character;
        if (char == null || char.isEmpty) {
          if (event.logicalKey.keyLabel.length == 1) {
             char = event.logicalKey.keyLabel;
          }
        }
        
        if (char != null && char.isNotEmpty) {
          final now = DateTime.now();
          // Jika jeda antar karakter lebih dari 500ms, dianggap ketikan manusia biasa, reset buffer
          if (_lastScanTime != null && now.difference(_lastScanTime!).inMilliseconds > 500) {
            _barcodeBuffer = '';
          }
          if (char.trim().isNotEmpty || char == ' ') {
            _barcodeBuffer += char;
          }
          _lastScanTime = now;
        }
      }
    }
    return false;
  }

  Future<void> _loadRetailModePref() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRetailMode = prefs.getBool('isRetailMode') ?? false;
    });
  }

  Future<void> _toggleRetailMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isRetailMode = !_isRetailMode;
      prefs.setBool('isRetailMode', _isRetailMode);
    });
  }

  void _addToCart(Product product, {ProductVariation? variation}) {
    if (variation != null) {
       if (variation.stock > 0) {
          Provider.of<CartProvider>(context, listen: false).addToCart(product, variation: variation);
          _showSnackBar('${product.name} (${variation.name}) masuk keranjang');
       } else {
          _showSnackBar('Stok variasi habis!');
       }
    } else {
       if (product.stock > 0) {
          Provider.of<CartProvider>(context, listen: false).addToCart(product);
          _showSnackBar('${product.name} masuk keranjang');
       } else {
          _showSnackBar('Stok habis!');
       }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ));
  }

  void _showVariationDialog(Product product) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Variasi ${product.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 10),
              ...product.variations.map((v) => ListTile(
                title: Text(v.name),
                subtitle: Text('Rp ${NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(v.price)} - Stok: ${v.stock}'),
                onTap: () {
                  Navigator.pop(context);
                  _addToCart(product, variation: v);
                },
                enabled: v.stock > 0,
              )),
            ],
          ),
        );
      },
    );
  }

  void _handleScannerInput(String result) {
    if (result.isEmpty) return;
    final provider = Provider.of<ProductProvider>(context, listen: false);
    try {
      // 1. Try finding by Product Code
      try {
        final product = provider.products.firstWhere((p) => p.code == result);
        if (product.variations.isNotEmpty) {
          _showVariationDialog(product);
        } else {
          _addToCart(product);
        }
        return;
      } catch (_) {}

      // 2. Try finding by Variation SKU
      for (var product in provider.products) {
        try {
          final variation = product.variations.firstWhere((v) => v.sku == result);
          _addToCart(product, variation: variation);
          return;
        } catch (_) {}
      }
      
      _showSnackBar('Produk tidak ditemukan');

    } catch (e) {
      _showSnackBar('Terjadi kesalahan');
    }
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScannerScreen()),
    );

    if (result != null && result is String) {
      _handleScannerInput(result);
    }
  }

  Widget _buildOpenShiftView(BuildContext context, Color primaryColor) {
    final startCashController = TextEditingController();
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.point_of_sale, size: 80, color: primaryColor),
                const SizedBox(height: 16),
                const Text(
                  'Shift Kasir Belum Dibuka',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Masukkan nominal uang modal kas awal di laci untuk membuka shift dan mulai bertransaksi.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: startCashController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Modal Awal (Tunai)',
                    hintText: 'Masukkan nominal, contoh: 100000',
                    prefixText: 'Rp ',
                  ),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () async {
                      final startCash = double.tryParse(startCashController.text) ?? 0.0;
                      if (startCash <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Masukkan modal awal yang valid!'), backgroundColor: Colors.red),
                        );
                        return;
                      }
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final cashierName = auth.currentStaff?.name ?? auth.storeInfo['ownerName'] ?? 'Owner';
                      await Provider.of<ShiftProvider>(context, listen: false).openShift(startCash, cashierName);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Shift berhasil dibuka!'), backgroundColor: Colors.green),
                      );
                    },
                    child: const Text('Buka Shift Baru', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCloseShiftDialog(BuildContext context) async {
    final shiftProvider = Provider.of<ShiftProvider>(context, listen: false);
    final summary = await shiftProvider.getShiftSummary();
    final expectedCash = summary['expected_cash']!;
    final startCash = summary['start_cash']!;
    final cashSales = summary['cash_sales']!;
    final totalExpenses = summary['total_expenses']!;

    final actualCashController = TextEditingController();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tutup Shift Kasir'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Rincian Shift:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modal Awal:'),
                  Text(currencyFormatter.format(startCash)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Penjualan Tunai:'),
                  Text('+ ${currencyFormatter.format(cashSales)}', style: const TextStyle(color: Colors.green)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Pengeluaran:'),
                  Text('- ${currencyFormatter.format(totalExpenses)}', style: const TextStyle(color: Colors.red)),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Uang Laci Seharusnya:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(currencyFormatter.format(expectedCash), style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: actualCashController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Total Uang Fisik Aktual',
                  hintText: 'Hitung & masukkan uang di laci fisik',
                  prefixText: 'Rp ',
                ),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final actualCash = double.tryParse(actualCashController.text);
              if (actualCash == null || actualCash < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Masukkan jumlah uang aktual yang valid!'), backgroundColor: Colors.red),
                );
                return;
              }

              final double selisih = actualCash - expectedCash;
              String msg = 'Shift berhasil ditutup.';
              if (selisih == 0) {
                msg += ' Saldo kas cocok!';
              } else if (selisih > 0) {
                msg += ' Ada kelebihan kas: ${currencyFormatter.format(selisih)}';
              } else {
                msg += ' Ada selisih kurang: ${currencyFormatter.format(selisih)}';
              }

              await shiftProvider.closeShift(actualCash);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(msg), backgroundColor: selisih == 0 ? Colors.green : Colors.orange, duration: const Duration(seconds: 4)),
              );
            },
            child: const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }

  void _showAddManualItemDialog(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Barang Dadakan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Barang', prefixIcon: Icon(Icons.shopping_bag_outlined)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Harga (Rp)', prefixIcon: Icon(Icons.payments_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final name = nameController.text.trim();
              final price = double.tryParse(priceController.text) ?? 0.0;
              if (name.isNotEmpty && price > 0) {
                final dummyProduct = Product(
                  id: -(DateTime.now().millisecondsSinceEpoch % 100000), 
                  name: name,
                  price: price,
                  stock: 999, 
                  category: 'Manual',
                  createdAt: DateTime.now(),
                );
                Provider.of<CartProvider>(context, listen: false).addToCart(dummyProduct);
                Navigator.pop(ctx);
                _showSnackBar('$name ditambahkan ke keranjang');
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Nama dan Harga harus diisi dengan benar!'), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Tambahkan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final bool isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final primaryColor = Theme.of(context).primaryColor;
    final shiftProvider = context.watch<ShiftProvider>();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        titleSpacing: 10,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            enabled: shiftProvider.isShiftOpen,
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            onSubmitted: (val) {
              if (val.isNotEmpty) {
                _handleScannerInput(val);
                _searchController.clear();
                setState(() => _searchQuery = '');
                _searchFocusNode.requestFocus(); // Keep focus for next scan
              }
            },
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: shiftProvider.isShiftOpen ? 'Cari produk atau scan barcode...' : 'Buka shift untuk bertransaksi',
              prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
              suffixIcon: IconButton(
                icon: const Icon(Icons.qr_code_scanner, color: Colors.grey, size: 20),
                onPressed: shiftProvider.isShiftOpen ? _scanBarcode : null,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
          ),
        ),
        actions: shiftProvider.isShiftOpen
            ? [
                IconButton(
                  icon: Icon(_isRetailMode ? Icons.grid_view : Icons.list, color: Colors.white),
                  tooltip: _isRetailMode ? 'Mode Grid' : 'Mode Retail',
                  onPressed: _toggleRetailMode,
                ),
                if (Provider.of<AuthProvider>(context).isFnbMode) ...[
                  IconButton(
                    icon: const Icon(Icons.soup_kitchen, color: Colors.white),
                    tooltip: 'Layar Dapur',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const KitchenScreen()));
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.table_restaurant, color: Colors.white),
                    tooltip: 'Pesanan Aktif',
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ActiveOrdersScreen()));
                    },
                  ),
                ],
                IconButton(
                  icon: const Icon(Icons.add_box, color: Colors.white),
                  tooltip: 'Barang Manual',
                  onPressed: () => _showAddManualItemDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_open, color: Colors.white),
                  tooltip: 'Tutup Shift',
                  onPressed: () => _showCloseShiftDialog(context),
                )
              ]
            : null,
      ),
      body: shiftProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : !shiftProvider.isShiftOpen
              ? _buildOpenShiftView(context, primaryColor)
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
                    final isTablet = constraints.maxWidth > 600 && !isPortrait;
                    final isDesktop = constraints.maxWidth > 1000;
                    
                    int crossAxisCount = 3;
                    if (isDesktop) {
                      crossAxisCount = 5;
                    } else if (isTablet) {
                      crossAxisCount = 4;
                    }

                    double childAspectRatio = isDesktop ? 0.75 : (isTablet ? 0.7 : 0.65);

                    final categoryBar = Consumer<CategoryProvider>(
                      builder: (context, catProvider, _) {
                        final categories = ['Semua', ...catProvider.categories.map((c) => c['name'] as String)];
                        return Container(
                          height: isLandscape ? 44 : 50,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: categories.length,
                            itemBuilder: (context, index) {
                              final cat = categories[index];
                              final isSelected = _selectedCategory == cat;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(cat, style: TextStyle(fontSize: isLandscape ? 12 : 13)),
                                  selected: isSelected,
                                  onSelected: (val) => setState(() => _selectedCategory = cat),
                                  backgroundColor: Colors.white,
                                  selectedColor: primaryColor,
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  showCheckmark: false,
                                  padding: EdgeInsets.symmetric(horizontal: isLandscape ? 8 : 12, vertical: 0),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );

                    final orderInfoBar = Consumer<CartProvider>(
                      builder: (context, cart, _) {
                        if (!Provider.of<AuthProvider>(context).isFnbMode) return const SizedBox.shrink();
                        return Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: cart.orderType,
                                  decoration: const InputDecoration(
                                    labelText: 'Tipe Pesanan',
                                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['Dine In', 'Take Away', 'Delivery'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                                  onChanged: (val) {
                                    if (val != null) cart.setOrderType(val);
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: InkWell(
                                  onTap: () => _showTableSelection(context, cart),
                                  child: Container(
                                    height: 48,
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      cart.tableNumber != null && cart.tableNumber!.isNotEmpty ? 'Meja ${cart.tableNumber}' : 'Pilih Meja', 
                                      style: TextStyle(color: cart.tableNumber == null ? Colors.grey[600] : Colors.black, fontSize: 16)
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );

                    return Consumer<ProductProvider>(
                      builder: (context, provider, _) {
                        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

                        final filteredProducts = provider.products.where((p) {
                          final matchName = p.name.toLowerCase().contains(_searchQuery);
                          final matchCode = p.code?.toLowerCase().contains(_searchQuery) ?? false;
                          final matchCategory = _selectedCategory == 'Semua' || p.category == _selectedCategory;
                          return (matchName || matchCode) && matchCategory;
                        }).toList();

                        Widget productContent;
                        if (filteredProducts.isEmpty) {
                          productContent = const Expanded(child: Center(child: Text('Produk tidak ditemukan.')));
                        } else {
                          productGrid() => GridView.builder(
                                padding: const EdgeInsets.all(10),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  childAspectRatio: childAspectRatio,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return Consumer<CartProvider>(
                                    builder: (context, cart, _) {
                                      final cartItem = cart.items.firstWhere(
                                        (item) => item.product.id == product.id && item.variation == null,
                                        orElse: () => CartItem(product: product, quantity: 0),
                                      );
                                      final qty = cartItem.quantity;

                                      return InkWell(
                                        onTap: () {
                                          if (product.variations.isNotEmpty) {
                                            _showVariationDialog(product);
                                          } else {
                                            _addToCart(product);
                                          }
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(12),
                                            border: Border.all(color: Colors.grey[200]!),
                                            boxShadow: [
                                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: Container(
                                                  width: double.infinity,
                                                  decoration: const BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                                     child: (product.imagePath != null && product.imagePath!.isNotEmpty)
                                                         ? (product.imagePath!.startsWith('http://') || product.imagePath!.startsWith('https://')
                                                             ? Image.network(
                                                                 product.imagePath!,
                                                                 fit: BoxFit.contain,
                                                                 errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                               )
                                                             : Image.file(
                                                                 File(product.imagePath!),
                                                                 fit: BoxFit.contain,
                                                                 errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 40, color: Colors.grey),
                                                               ))
                                                         : const Icon(Icons.inventory_2, size: 40, color: Colors.grey),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(product.name,
                                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis),
                                                    const SizedBox(height: 2),
                                                    Text(currencyFormatter.format(product.price),
                                                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 12)),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                margin: const EdgeInsets.all(6),
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: primaryColor.withOpacity(0.05),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                                  children: [
                                                    InkWell(
                                                      onTap: qty > 0 ? () => cart.decrementQuantity(cartItem) : null,
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Icon(Icons.remove, size: 16, color: qty > 0 ? primaryColor : Colors.grey),
                                                      ),
                                                    ),
                                                    Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                    InkWell(
                                                      onTap: () => cart.addToCart(product),
                                                      child: Padding(
                                                        padding: const EdgeInsets.all(4.0),
                                                        child: Icon(Icons.add_circle, size: 18, color: primaryColor),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                          
                          productList() => ListView.separated(
                                padding: const EdgeInsets.all(10),
                                itemCount: filteredProducts.length,
                                separatorBuilder: (context, index) => const Divider(height: 1),
                                itemBuilder: (context, index) {
                                  final product = filteredProducts[index];
                                  return Consumer<CartProvider>(
                                    builder: (context, cart, _) {
                                      final cartItem = cart.items.firstWhere(
                                        (item) => item.product.id == product.id && item.variation == null,
                                        orElse: () => CartItem(product: product, quantity: 0),
                                      );
                                      final qty = cartItem.quantity;

                                      return ListTile(
                                        onTap: () {
                                          if (product.variations.isNotEmpty) {
                                            _showVariationDialog(product);
                                          } else {
                                            _addToCart(product);
                                          }
                                        },
                                        tileColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (product.code != null && product.code!.isNotEmpty)
                                              Text('SKU: ${product.code}', style: const TextStyle(fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Harga: ${currencyFormatter.format(product.price)}  |  Stok: ${product.stock}',
                                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        trailing: product.variations.isNotEmpty 
                                          ? ElevatedButton(
                                              onPressed: () => _showVariationDialog(product),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                              ),
                                              child: const Text('Pilih Variasi'),
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline),
                                                  color: qty > 0 ? primaryColor : Colors.grey,
                                                  onPressed: qty > 0 ? () => cart.decrementQuantity(cartItem) : null,
                                                ),
                                                Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle),
                                                  color: primaryColor,
                                                  onPressed: () => cart.addToCart(product),
                                                ),
                                              ],
                                            ),
                                      );
                                    },
                                  );
                                },
                              );

                          productContent = Expanded(child: _isRetailMode ? productList() : productGrid());
                        }

                        if (isTablet) {
                          return Row(
                            children: [
                              Expanded(
                                  flex: 7,
                                  child: Column(
                                    children: [
                                      orderInfoBar,
                                      categoryBar,
                                      productContent,
                                    ],
                                  )),
                              const VerticalDivider(width: 1),
                              const Expanded(
                                flex: 4,
                                child: CartScreen(isEmbedded: true),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            orderInfoBar,
                            categoryBar,
                            productContent,
                          ],
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: !shiftProvider.isShiftOpen
          ? null
          : LayoutBuilder(builder: (context, constraints) {
              final isTablet = MediaQuery.of(context).size.width > 600;
              if (isTablet) return const SizedBox.shrink();

              return Consumer<CartProvider>(
                builder: (context, cart, child) {
                  if (cart.items.isEmpty) return const SizedBox.shrink();
                  return FloatingActionButton.extended(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useSafeArea: true,
                        builder: (_) => DraggableScrollableSheet(
                          initialChildSize: 0.8,
                          minChildSize: 0.5,
                          maxChildSize: 0.95,
                          expand: false,
                          builder: (_, controller) => const CartScreen(),
                        ),
                      );
                    },
                    label: Text('${cart.items.length} Item - ${currencyFormatter.format(cart.totalAmount)}'),
                    icon: const Icon(Icons.shopping_cart),
                  );
                },
              );
            }),
    );
  }
}
