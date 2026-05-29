import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';

class ShiftProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  Map<String, dynamic>? _activeShift;
  bool _isLoading = false;

  Map<String, dynamic>? get activeShift => _activeShift;
  bool get isLoading => _isLoading;
  bool get isShiftOpen => _activeShift != null;

  Future<void> checkActiveShift() async {
    _isLoading = true;
    notifyListeners();

    final db = await _db.database;
    final results = await db.query(
      'shifts',
      where: 'status = ?',
      whereArgs: ['Open'],
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

  Future<void> openShift(double startCash) async {
    final db = await _db.database;
    final id = await db.insert('shifts', {
      'start_time': DateTime.now().toIso8601String(),
      'start_cash': startCash,
      'status': 'Open',
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
    if (_activeShift == null) return {'start_cash': 0.0, 'cash_sales': 0.0, 'expected_cash': 0.0};
    
    final db = await _db.database;
    final shiftId = _activeShift!['id'] as int;

    // Get total cash sales
    final salesResult = await db.rawQuery('''
      SELECT SUM(total_amount) as total_cash
      FROM transactions
      WHERE shift_id = ? AND payment_method = 'Tunai'
    ''', [shiftId]);

    final startCash = (_activeShift!['start_cash'] as num).toDouble();
    final cashSales = (salesResult.first['total_cash'] as num?)?.toDouble() ?? 0.0;
    final expectedCash = startCash + cashSales;

    return {
      'start_cash': startCash,
      'cash_sales': cashSales,
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
    DatabaseService.hasUnsyncedChanges = true;

    _activeShift = null;
    notifyListeners();
  }
}
