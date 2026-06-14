import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/services/sync_service.dart';

class ShiftProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _activeShift;
  bool _isLoading = false;

  Map<String, dynamic>? get activeShift => _activeShift;
  bool get isLoading => _isLoading;
  bool get isShiftOpen => _activeShift != null;

  Future<void> checkActiveShift(String cashierName) async {
    _isLoading = true;
    notifyListeners();

    final db = await _db.database;
    final results = await db.query(
      'shifts',
      where: 'status = ? AND (cashier_name = ? OR cashier_name IS NULL)',
      whereArgs: ['Open', cashierName],
      limit: 1,
    );

    if (results.isNotEmpty) {
      _activeShift = results.first;
    } else {
      _activeShift = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> openShift(double startCash, String cashierName) async {
    final db = await _db.database;
    final id = await db.insert('shifts', {
      'start_time': DateTime.now().toIso8601String(),
      'start_cash': startCash,
      'status': 'Open',
      'cashier_name': cashierName,
      'is_synced': 0,
    });
    DatabaseService.hasUnsyncedChanges = true;

    final results = await db.query('shifts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (results.isNotEmpty) {
      _activeShift = results.first;
      notifyListeners();
    }
  }

  Future<Map<String, double>> getShiftSummary() async {
    if (_activeShift == null) return {'start_cash': 0.0, 'cash_sales': 0.0, 'total_expenses': 0.0, 'expected_cash': 0.0};
    
    final db = await _db.database;
    final shiftId = _activeShift!['id'] as int;
    final startTimeStr = _activeShift!['start_time'] as String;

    // Get total cash sales
    final salesResult = await db.rawQuery('''
      SELECT SUM(
        t.total_amount - COALESCE(
          (SELECT SUM(COALESCE(ti.returned_qty, 0) * ti.price_at_sale) 
           FROM transaction_items ti 
           WHERE ti.transaction_id = t.id), 0
        )
      ) as total_cash
      FROM transactions t
      WHERE t.shift_id = ? AND t.payment_method = 'Tunai'
    ''', [shiftId]);

    // Get total expenses during this shift
    final expensesResult = await db.rawQuery('''
      SELECT SUM(amount) as total_expenses
      FROM expenses
      WHERE date >= ?
    ''', [startTimeStr]);

    final startCash = (_activeShift!['start_cash'] as num).toDouble();
    final cashSales = (salesResult.first['total_cash'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (expensesResult.first['total_expenses'] as num?)?.toDouble() ?? 0.0;
    
    // Actual expected cash in drawer = start_cash + cash_sales - expenses
    final expectedCash = startCash + cashSales - totalExpenses;

    return {
      'start_cash': startCash,
      'cash_sales': cashSales,
      'total_expenses': totalExpenses,
      'expected_cash': expectedCash,
    };
  }

  Future<void> closeShift(double actualCash) async {
    if (_activeShift == null) return;

    final db = await _db.database;
    final shiftId = _activeShift!['id'] as int;
    final summary = await getShiftSummary();
    final expectedCash = summary['expected_cash']!;

    await db.update(
      'shifts',
      {
        'end_time': DateTime.now().toIso8601String(),
        'end_cash_expected': expectedCash,
        'end_cash_actual': actualCash,
        'status': 'Closed',
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
    
    // Reset meja yang terpakai (Draft) di shift ini agar kosong kembali
    int updatedRows = await db.update(
      'transactions',
      {'table_number': '', 'is_synced': 0},
      where: "status = 'Draft'",
    );
    debugPrint('Reset $updatedRows meja yang belum dibayar.');
    
    DatabaseService.hasUnsyncedChanges = true;

    _activeShift = null;
    notifyListeners();
    SyncService().uploadLocalChanges();
  }
}
