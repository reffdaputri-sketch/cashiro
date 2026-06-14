import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';

import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final DatabaseService _db = DatabaseService();
  final SyncService _sync = SyncService();
  
  List<Map<String, dynamic>> _draftOrders = [];
  Map<int, List<Map<String, dynamic>>> _orderItems = {};
  
  bool _isLoading = true;
  bool _isSyncing = false;
  Timer? _timer;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Set<int> _previousDraftIds = {};
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _startPolling();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _syncFromCloud();
    });
  }

  Future<void> _syncFromCloud() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final storeInfo = auth.storeInfo;
      final storeId = storeInfo['storeId'];
      final licenseKey = storeInfo['licenseKey'];
      
      if (storeId != null && licenseKey != null && storeId != 'DEMO-STORE-ID') {
        await _sync.downloadAllCloudData(storeId!, licenseKey!);
        await _loadData(); // Reload local DB after sync
      }
    } catch (e) {
      debugPrint('KDS Sync Error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _loadData() async {
    try {
      final db = await _db.database;
      // Get all Drafts
      final results = await db.query(
        'transactions',
        where: 'kitchen_status = ?',
        whereArgs: ['Pending'],
        orderBy: 'created_at ASC', // Oldest first for kitchen
      );
      
      Map<int, List<Map<String, dynamic>>> itemsMap = {};
      Set<int> currentIds = {};
      
      for (var order in results) {
        final orderId = order['id'] as int;
        currentIds.add(orderId);
        final items = await db.rawQuery('''
          SELECT ti.*, 
                 p.name as p_name, 
                 pv.name as v_name 
          FROM transaction_items ti
          LEFT JOIN products p ON ti.product_id = p.id
          LEFT JOIN product_variations pv ON ti.variation_id = pv.id
          WHERE ti.transaction_id = ?
        ''', [orderId]);
        itemsMap[orderId] = items;
      }

      if (_isInitialized) {
        final newIds = currentIds.difference(_previousDraftIds);
        if (newIds.isNotEmpty) {
          _audioPlayer.play(AssetSource('sounds/notification.wav'));
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Pesanan Baru Masuk! 🔔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), 
              backgroundColor: Colors.blue,
              duration: Duration(seconds: 4),
            ));
          }
        }
      }
      _previousDraftIds = currentIds;
      _isInitialized = true;

      if (mounted) {
        setState(() {
          _draftOrders = results;
          _orderItems = itemsMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _markAsReady(int orderId) async {
    try {
      final db = await _db.database;
      // Update locally
      await db.update(
        'transactions',
        {
          'kitchen_status': 'Ready', 
          'is_synced': 0, // Force sync to upload this change
        },
        where: 'id = ?',
        whereArgs: [orderId],
      );
      
      // Upload changes so cashier knows it's ready
      _sync.uploadLocalChanges();
      
      // Reload UI
      _loadData();
      
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pesanan ditandai selesai!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      debugPrint('Mark ready error: $e');
    }
  }

  void _showOrderDetailDialog(Map<String, dynamic> order, List<dynamic> items, bool isLate, Duration duration, String formattedDate, String tableStr, String orderType, int orderId) {
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isLate ? Colors.red[700] : Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tableStr, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(orderType, style: const TextStyle(color: Colors.white70, fontSize: 14)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${duration.inMinutes} mnt', style: TextStyle(color: isLate ? Colors.yellow : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[300]),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final notes = item['notes'] as String?;
                      final pName = item['p_name'] as String? ?? 'Produk Terhapus';
                      final vName = item['v_name'] as String?;
                      final displayName = vName != null ? '$pName ($vName)' : pName;
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              alignment: Alignment.topLeft,
                              child: Text('${item['quantity']}x', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor)),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  if (notes != null && notes.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange[50],
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.orange[200]!)
                                      ),
                                      child: Text('Catatan: $notes', style: TextStyle(color: Colors.orange[900], fontSize: 12, fontStyle: FontStyle.italic)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)),
                          child: const Text('Tutup', style: TextStyle(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _markAsReady(orderId);
                          },
                          icon: const Icon(Icons.check_circle_outline, size: 20),
                          label: const Text('Selesai', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Layar Dapur (KDS)', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_isSyncing) 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Sync Manual',
              onPressed: _syncFromCloud,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _draftOrders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.soup_kitchen, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('Tidak ada pesanan aktif.', style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    int crossAxisCount = (constraints.maxWidth / 220).floor();
                    if (crossAxisCount < 1) crossAxisCount = 1;
                    final spacing = 12.0;
                    final itemWidth = (constraints.maxWidth - 32 - ((crossAxisCount - 1) * spacing)) / crossAxisCount;

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        alignment: WrapAlignment.start,
                        children: _draftOrders.map((order) {
                          final orderId = order['id'] as int;
                          final items = _orderItems[orderId] ?? [];
                          final date = DateTime.parse(order['created_at']);
                          final formattedDate = DateFormat('HH:mm').format(date);
                          final tableStr = order['table_number'] != null && order['table_number'].toString().isNotEmpty
                              ? 'Meja: ${order['table_number']}'
                              : 'Tanpa Meja';
                          final orderType = order['order_type'] ?? 'Dine In';
                          
                          // Hitung durasi tunggu
                          final duration = DateTime.now().difference(date);
                          final isLate = duration.inMinutes > 15; // Warning jika > 15 menit

                          return SizedBox(
                            width: itemWidth,
                            child: Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                onTap: () => _showOrderDetailDialog(order, items, isLate, duration, formattedDate, tableStr, orderType, orderId),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                            // Header Card
                            Container(
                              color: isLate ? Colors.red[700] : primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(tableStr, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                        Text(orderType, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                      Text('${duration.inMinutes} mnt', style: TextStyle(color: isLate ? Colors.yellow : Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            // List of Items
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...items.map((item) {
                                    final notes = item['notes'] as String?;
                                    final pName = item['p_name'] as String? ?? 'Produk Terhapus';
                                    final vName = item['v_name'] as String?;
                                    final displayName = vName != null ? '$pName ($vName)' : pName;
                                    
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 20,
                                            alignment: Alignment.topLeft,
                                            child: Text('${item['quantity']}x', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: primaryColor)),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(displayName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                                if (notes != null && notes.isNotEmpty)
                                                  Text('Catatan: $notes', style: TextStyle(color: Colors.orange, fontSize: 10, fontStyle: FontStyle.italic)),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          // Footer Button
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ElevatedButton.icon(
                              onPressed: () => _markAsReady(orderId),
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              label: const Text('Selesai Dimasak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ),
                            ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),
    );
  }
}
