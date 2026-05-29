import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:intl/intl.dart';
import 'package:mobile/screens/debt_list_screen.dart';

class CashFlowScreen extends StatefulWidget {
  const CashFlowScreen({super.key});

  @override
  State<CashFlowScreen> createState() => _CashFlowScreenState();
}

class _CashFlowScreenState extends State<CashFlowScreen> {
  final DatabaseService _db = DatabaseService();
  late Future<List<Map<String, dynamic>>> _shiftsFuture;
  
  double _salesToday = 0.0;
  double _expensesToday = 0.0;
  bool _isStatsLoading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _shiftsFuture = _getClosedShifts();
      _loadTodayStats();
    });
  }

  Future<void> _loadTodayStats() async {
    setState(() {
      _isStatsLoading = true;
    });

    final db = await _db.database;
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // 1. Total sales today
    final salesResult = await db.rawQuery('''
      SELECT SUM(total_amount) as total_sales
      FROM transactions
      WHERE DATE(created_at) = ?
    ''', [todayStr]);
    final sales = (salesResult.first['total_sales'] as num?)?.toDouble() ?? 0.0;

    // 2. Total expenses today
    final expensesResult = await db.rawQuery('''
      SELECT SUM(amount) as total_expenses
      FROM expenses
      WHERE DATE(date) = ?
    ''', [todayStr]);
    final expenses = (expensesResult.first['total_expenses'] as num?)?.toDouble() ?? 0.0;

    if (mounted) {
      setState(() {
        _salesToday = sales;
        _expensesToday = expenses;
        _isStatsLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getClosedShifts() async {
    final db = await _db.database;
    return await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['Closed'],
      orderBy: 'id DESC',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('Keuangan & Kas', style: TextStyle(fontWeight: FontWeight.bold)),
          elevation: 0,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelStyle: TextStyle(fontWeight: FontWeight.bold),
            tabs: [
              Tab(text: 'Arus Kas'),
              Tab(text: 'Manajemen Hutang'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Arus Kas
            RefreshIndicator(
              onRefresh: () async => _refresh(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildTodaySummaryCard(currencyFormatter),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        'Riwayat Penutupan Shift',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                    ),
                  ),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: _shiftsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history_toggle_off, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Belum ada riwayat shift.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      }

                      final shifts = snapshot.data!;
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final s = shifts[index];
                              final startTime = DateTime.parse(s['start_time']);
                              final endTime = s['end_time'] != null ? DateTime.parse(s['end_time']) : null;
                              
                              final startCash = (s['start_cash'] as num).toDouble();
                              final expectedCash = (s['end_cash_expected'] as num?)?.toDouble() ?? 0.0;
                              final actualCash = (s['end_cash_actual'] as num?)?.toDouble() ?? 0.0;
                              final diff = actualCash - expectedCash;

                              final isMatch = diff == 0;
                              final isShort = diff < 0;

                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey[200]!),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          width: 4, 
                                          color: isMatch ? Colors.green : (isShort ? Colors.red : Colors.blue)
                                        )
                                      )
                                    ),
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                const Icon(Icons.storefront, color: Colors.grey, size: 20),
                                                const SizedBox(width: 8),
                                                Text('Shift #${s['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                              ],
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.grey[100],
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Text('Tutup', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            const Icon(Icons.play_circle_outline, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              DateFormat('dd MMM yyyy, HH:mm').format(startTime),
                                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        if (endTime != null)
                                          Row(
                                            children: [
                                              const Icon(Icons.stop_circle_outlined, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                DateFormat('dd MMM yyyy, HH:mm').format(endTime),
                                                style: const TextStyle(fontSize: 13, color: Colors.black87),
                                              ),
                                            ],
                                          ),
                                        const Divider(height: 24),
                                        _buildRowItem('Modal Awal', currencyFormatter.format(startCash), false),
                                        const SizedBox(height: 8),
                                        _buildRowItem('Seharusnya di Laci', currencyFormatter.format(expectedCash), false),
                                        const SizedBox(height: 8),
                                        _buildRowItem('Uang Aktual di Laci', currencyFormatter.format(actualCash), true),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: isMatch ? Colors.green[50] : (isShort ? Colors.red[50] : Colors.blue[50]),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Selisih Kas', style: TextStyle(fontWeight: FontWeight.bold, color: isMatch ? Colors.green[700] : (isShort ? Colors.red[700] : Colors.blue[700]))),
                                              Text(
                                                isMatch ? 'Cocok (Rp 0)' : (isShort ? '- ${currencyFormatter.format(diff.abs())}' : '+ ${currencyFormatter.format(diff)}'),
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isMatch ? Colors.green[700] : (isShort ? Colors.red[700] : Colors.blue[700]),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: shifts.length,
                          ),
                        ),
                      );
                    },
                  ),
                  const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                ],
              ),
            ),
            
            // Tab 2: Manajemen Hutang
            const DebtListScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }

  Widget _buildRowItem(String label, String value, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: Colors.black87)),
      ],
    );
  }

  Widget _buildTodaySummaryCard(NumberFormat formatter) {
    final double netBalance = _salesToday - _expensesToday;

    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.teal[700]!, Colors.teal[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 6)),
        ]
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const Text(
            'RINGKASAN KAS HARI INI',
            style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('dd MMMM yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),
          _isStatsLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : Row(
                  children: [
                    // Uang Masuk
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text('Masuk', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(_salesToday),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    // Uang Keluar
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text('Keluar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(_expensesToday),
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    Container(width: 1, height: 40, color: Colors.white24),
                    // Saldo Bersih
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                            child: const Icon(Icons.account_balance_wallet, color: Colors.cyanAccent, size: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text('Bersih', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            formatter.format(netBalance),
                            style: TextStyle(
                              color: netBalance >= 0 ? Colors.cyanAccent : Colors.amberAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}
