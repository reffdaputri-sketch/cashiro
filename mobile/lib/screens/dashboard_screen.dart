import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mobile/providers/auth_provider.dart';
import 'package:mobile/screens/staff_list_screen.dart';
import 'package:mobile/screens/report_screen.dart';
import 'package:mobile/screens/history_screen.dart';
import 'package:mobile/screens/master_data_screen.dart';
import 'package:mobile/screens/stock_report_screen.dart';
import 'package:mobile/screens/online_store_screen.dart';
import 'package:mobile/screens/cash_flow_screen.dart';
import 'package:mobile/screens/expense_screen.dart';
import 'package:mobile/screens/referral_management_screen.dart';
import 'package:mobile/screens/edit_store_screen.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/services/report_service.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {

  final Color bgLight = const Color(0xFFF4F9F6);
  final DatabaseService _db = DatabaseService();
  final ReportService _reportService = ReportService();

  List<Map<String, dynamic>> _recentTransactions = [];
  List<Map<String, dynamic>> _lowStockProducts = [];
  bool _isLoadingData = true;

  double _todaySales = 0;
  int _todayTxCount = 0;
  double _todayProfit = 0;
  int _totalStock = 0;
  List<Map<String, dynamic>> _chartData = [];
  int _chartDays = 7;
  String _metricPeriod = 'Hari Ini';

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    try {
      final txns = await _db.getAll('transactions', orderBy: 'id DESC');
      final prods = await _db.getAll('products', where: 'is_deleted = 0 OR is_deleted IS NULL');
      
      DateTime now = DateTime.now();
      DateTime startOfDay = DateTime(now.year, now.month, now.day);
      DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      DateTime startMetricDate;
      DateTime endMetricDate;

      if (_metricPeriod == 'Hari Ini') {
        startMetricDate = startOfDay;
        endMetricDate = endOfDay;
      } else if (_metricPeriod == 'Bulan Ini') {
        startMetricDate = DateTime(now.year, now.month, 1);
        endMetricDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      } else {
        startMetricDate = DateTime(now.year, 1, 1);
        endMetricDate = DateTime(now.year, 12, 31, 23, 59, 59);
      }
      
      DateTime startChartDays = startOfDay.subtract(Duration(days: _chartDays - 1));
      
      final profitLossToday = await _reportService.getProfitLoss(startMetricDate, endMetricDate);
      
      final dbInstance = await _db.database;
      final txCountResult = await dbInstance.rawQuery("SELECT COUNT(*) as cnt FROM transactions WHERE created_at BETWEEN ? AND ?", [startMetricDate.toIso8601String(), endMetricDate.toIso8601String()]);
      int txCount = (txCountResult.first['cnt'] as num?)?.toInt() ?? 0;

      final stockResult = await dbInstance.rawQuery("SELECT SUM(stock) as total_stock FROM products WHERE is_deleted = 0 OR is_deleted IS NULL");
      int totalStock = (stockResult.first['total_stock'] as num?)?.toInt() ?? 0;
      
      final chartData = await _reportService.getDailyProfitLoss(startChartDays, endOfDay);
      
      final lowStock = prods.where((p) => (p['stock'] as int) > 0 && (p['stock'] as int) <= 10).toList();
      lowStock.sort((a, b) => (a['stock'] as int).compareTo(b['stock'] as int));

      if (mounted) {
        setState(() {
          _recentTransactions = txns.take(5).toList();
          _lowStockProducts = lowStock.take(5).toList();
          
          _todaySales = profitLossToday['revenue'] ?? 0;
          _todayProfit = profitLossToday['netProfit'] ?? 0;
          _todayTxCount = txCount;
          _totalStock = totalStock;
          _chartData = chartData;
          
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final userName = auth.currentStaff?.name ?? auth.storeInfo['ownerName'] ?? 'Andi';
    final storeName = auth.storeInfo['storeName'] ?? 'Toko Sejahtera';
    final storePhone = auth.storeInfo['phone'] ?? '-';
    final Color primaryGreen = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: bgLight,
      body: RefreshIndicator(
        color: primaryGreen,
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // HEADER
                Container(
                  height: 250,
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront, color: Colors.white, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(storeName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                  Row(
                                    children: [
                                      const Icon(Icons.phone, color: Colors.white70, size: 12),
                                      const SizedBox(width: 4),
                                      Text(storePhone, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              InkWell(
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStoreScreen())),
                                child: const CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white24,
                                  child: Icon(Icons.person, color: Colors.white, size: 20),
                                ),
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text('Welcome, $userName! 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 4),
                                const Text('Semangat jualannya hari ini!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            initialValue: _metricPeriod,
                            onSelected: (val) {
                              if (_metricPeriod != val) {
                                setState(() { _metricPeriod = val; });
                                _loadDashboardData();
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 14),
                                  const SizedBox(width: 6),
                                  Text(_metricPeriod, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 14),
                                ],
                              ),
                            ),
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'Hari Ini', child: Text('Hari Ini')),
                              PopupMenuItem(value: 'Bulan Ini', child: Text('Bulan Ini')),
                              PopupMenuItem(value: 'Tahun Ini', child: Text('Tahun Ini')),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // METRIC CARDS
                Positioned(
                  top: 180,
                  left: 0,
                  right: 0,
                  child: SizedBox(
                    height: 110,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      children: [
                        _buildMetricCard('Penjualan', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_todaySales), _metricPeriod, Icons.shopping_bag, Colors.green, true),
                        const SizedBox(width: 12),
                        _buildMetricCard('Total Transaksi', '$_todayTxCount', _metricPeriod, Icons.shopping_cart_outlined, Colors.blue, true),
                        const SizedBox(width: 12),
                        _buildMetricCard('Laba Bersih', NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0).format(_todayProfit), _metricPeriod, Icons.trending_up, Colors.green, true),
                        const SizedBox(width: 12),
                        _buildMetricCard('Total Stok Item', '$_totalStock', 'Seluruh Produk', Icons.inventory_2_outlined, Colors.orange, false),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20), // Spacer for overlapping cards + 8px gap

            // MENUS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.1,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildMenuBtn(context, 'Produk', Icons.inventory_2_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MasterDataScreen()))),
                  _buildMenuBtn(context, 'Toko Online', Icons.shopping_bag_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineStoreScreen()))),
                  _buildMenuBtn(context, 'Laba Rugi', Icons.bar_chart, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen(initialTabIndex: 0)))),
                  _buildMenuBtn(context, 'Terlaris', Icons.trending_up, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen(initialTabIndex: 1)))),
                  _buildMenuBtn(context, 'Stok Barang', Icons.warehouse_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockReportScreen()))),
                  _buildMenuBtn(context, 'Riwayat', Icons.history, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))),
                  _buildMenuBtn(context, 'Arus Kas', Icons.account_balance_wallet_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashFlowScreen()))),
                  _buildMenuBtn(context, 'Staf', Icons.people_outline, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StaffListScreen()))),
                  _buildMenuBtn(context, 'Referral', Icons.group_add_outlined, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralManagementScreen()))),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // CHART SECTION
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Tren Penjualan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      PopupMenuButton<int>(
                        initialValue: _chartDays,
                        onSelected: (val) {
                          if (_chartDays != val) {
                            setState(() {
                              _chartDays = val;
                            });
                            _loadDashboardData();
                          }
                        },
                        child: Row(
                          children: [
                            Text(_chartDays == 1 ? 'Hari Ini' : '$_chartDays Hari Terakhir', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                            const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.black54),
                          ],
                        ),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 1, child: Text('Hari Ini')),
                          PopupMenuItem(value: 7, child: Text('7 Hari Terakhir')),
                          PopupMenuItem(value: 30, child: Text('30 Hari Terakhir')),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 160,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 22,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                int index = value.toInt();
                                if (index >= 0 && index < _chartData.length) {
                                  DateTime date = DateTime.parse(_chartData[index]['date']);
                                  return Text(DateFormat('dd MMM').format(date), style: const TextStyle(color: Colors.black54, fontSize: 10));
                                }
                                return const Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                if (value == 0) return const Text('', style: TextStyle(fontSize: 10));
                                String text;
                                if (value >= 1000000) {
                                  text = '${(value / 1000000).toStringAsFixed(1)}jt';
                                } else if (value >= 1000) {
                                  text = '${(value / 1000).toStringAsFixed(0)}rb';
                                } else {
                                  text = value.toInt().toString();
                                }
                                return Text(text, style: const TextStyle(color: Colors.black54, fontSize: 10));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0, 
                        maxX: (_chartData.length > 1 ? _chartData.length - 1 : 1).toDouble(), 
                        minY: 0, 
                        lineBarsData: [
                          LineChartBarData(
                            spots: _chartData.isEmpty 
                              ? const [FlSpot(0, 0)] 
                              : _chartData.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value['profit'] as double);
                                }).toList(),
                            isCurved: true,
                            color: primaryGreen,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(radius: 4, color: primaryGreen, strokeWidth: 2, strokeColor: Colors.white),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [primaryGreen.withOpacity(0.2), primaryGreen.withOpacity(0.0)],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),



            // BOTTOM BANNER (Moved up)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A3B20), // very dark green
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), shape: BoxShape.circle),
                    child: const Icon(Icons.point_of_sale, color: Colors.greenAccent, size: 30),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Kelola toko makin mudah', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        SizedBox(height: 4),
                        Text('Semua fitur penting ada di tangan Anda.', style: TextStyle(color: Colors.white70, fontSize: 11)),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnlineStoreScreen())),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        children: const [
                          Text('Pelajari Fitur', style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right, size: 14),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2 COLUMNS: TRANSAKSI & STOK
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TRANSAKSI TERBARU
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Transaksi Terbaru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text('Lihat semua', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingData)
                          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                        else if (_recentTransactions.isEmpty)
                          const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Belum ada transaksi', style: TextStyle(fontSize: 12, color: Colors.grey))))
                        else
                          ..._recentTransactions.map((tx) {
                            final formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                            final amount = formatCurrency.format(tx['total_amount'] ?? 0);
                            final dateStr = tx['created_at'] as String? ?? '';
                            final date = DateTime.tryParse(dateStr);
                            final formattedDate = date != null ? DateFormat('dd MMM yyyy • HH:mm').format(date) : dateStr;
                            return _buildTransactionItem(tx['receipt_number'] ?? 'INV', amount, formattedDate);
                          }).toList(),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Text('Lihat semua transaksi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right, size: 14),
                              ],
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // STOK MENIPIS
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Stok Menipis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red)),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockReportScreen())),
                              child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Text('Lihat semua', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_isLoadingData)
                          const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator()))
                        else if (_lowStockProducts.isEmpty)
                          const Padding(padding: EdgeInsets.all(20), child: Center(child: Text('Stok dalam kondisi aman', style: TextStyle(fontSize: 12, color: Colors.grey))))
                        else
                          ..._lowStockProducts.map((p) {
                            return _buildStockItem(p['name'] ?? 'Produk', p['stock'].toString(), Colors.orange.shade100, Icons.inventory_2);
                          }).toList(),
                      ],
                    ),
                  )
                ],
              ),
            ),



            const SizedBox(height: 40),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String subtitle, IconData icon, Color iconColor, bool isUp) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Spacer(),
          Row(
            children: [
              Icon(isUp ? Icons.arrow_upward : Icons.info_outline, size: 12, color: isUp ? Colors.green : Colors.grey),
              const SizedBox(width: 4),
              Expanded(child: Text(subtitle, style: TextStyle(fontSize: 10, color: isUp ? Colors.green : Colors.grey), overflow: TextOverflow.ellipsis)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMenuBtn(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 4)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Theme.of(context).primaryColor, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(String id, String amount, String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.receipt_long, color: Theme.of(context).primaryColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(id, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                const SizedBox(height: 2),
                Text(date, style: const TextStyle(color: Colors.grey, fontSize: 9)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: Theme.of(context).primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text('Selesai', style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 8, fontWeight: FontWeight.bold)),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStockItem(String name, String stock, Color bgColor, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 16, color: Colors.black54),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text('Stok: $stock', style: const TextStyle(color: Colors.grey, fontSize: 9)),
              ],
            ),
          ),
          Container(
            width: 20, height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
            child: Text(stock, style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }
}
