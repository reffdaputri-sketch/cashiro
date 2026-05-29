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
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('Keuangan'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Arus Kas'),
              Tab(text: 'Manajemen Hutang'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Arus Kas
            Column(
              children: [
                // 📊 Today's Summary Card
                _buildTodaySummaryCard(currencyFormatter),
                
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Riwayat Penutupan Shift',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                // 📜 Shifts List
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _shiftsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(child: Text('Belum ada riwayat penutupan shift.'));
                      }

                      final shifts = snapshot.data!;
                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                        itemCount: shifts.length,
                        itemBuilder: (context, index) {
                          final s = shifts[index];
                          final startTime = DateTime.parse(s['start_time']);
                          final endTime = s['end_time'] != null ? DateTime.parse(s['end_time']) : null;
                          
                          final startCash = (s['start_cash'] as num).toDouble();
                          final expectedCash = (s['end_cash_expected'] as num?)?.toDouble() ?? 0.0;
                          final actualCash = (s['end_cash_actual'] as num?)?.toDouble() ?? 0.0;
                          final diff = actualCash - expectedCash;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Shift #${s['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text('Closed', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Mulai: ${DateFormat('dd MMM yyyy, HH:mm').format(startTime)}',
                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  ),
                                  if (endTime != null)
                                    Text(
                                      'Selesai: ${DateFormat('dd MMM yyyy, HH:mm').format(endTime)}',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                    ),
                                  const Divider(height: 20),
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
                                      const Text('Seharusnya di Laci:'),
                                      Text(currencyFormatter.format(expectedCash)),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Uang Aktual di Laci:'),
                                      Text(currencyFormatter.format(actualCash), style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Selisih Kas:', style: TextStyle(fontWeight: FontWeight.bold)),
                                      Text(
                                        diff == 0 ? 'Cocok (Rp 0)' : currencyFormatter.format(diff),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: diff == 0
                                              ? Colors.green
                                              : diff > 0
                                                  ? Colors.blue
                                                  : Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
            
            // Tab 2: Manajemen Hutang
            const DebtListScreen(showAppBar: false),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryCard(NumberFormat formatter) {
    final double netBalance = _salesToday - _expensesToday;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.teal[800]!, Colors.teal[600]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Text(
              'RINGKASAN KAS HARI INI',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Divider(height: 24, color: Colors.white24),
            _isStatsLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : Row(
                    children: [
                      // Uang Masuk
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Uang Masuk', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(_salesToday),
                              style: const TextStyle(color: Colors.greenAccent, fontSize: 15, fontWeight: FontWeight.bold),
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
                            const Text('Uang Keluar', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              formatter.format(_expensesToday),
                              style: const TextStyle(color: Colors.redAccent, fontSize: 15, fontWeight: FontWeight.bold),
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
                            const Text('Saldo Bersih', style: TextStyle(color: Colors.white70, fontSize: 12)),
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
      ),
    );
  }
}
