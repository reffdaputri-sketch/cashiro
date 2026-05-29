import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';

class DebtProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  bool _isLoading = false;
  List<Map<String, dynamic>> _debtCustomers = [];

  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get debtCustomers => _debtCustomers;

  Future<void> fetchDebtCustomers() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await _db.database;
      _debtCustomers = await db.rawQuery('''
        SELECT c.id, c.name, c.phone, SUM(t.total_amount - t.paid_amount) as total_debt
        FROM customers c
        JOIN transactions t ON t.customer_id = c.id
        WHERE t.payment_method = 'Hutang / Tempo' AND t.paid_amount < t.total_amount
        GROUP BY c.id
        ORDER BY total_debt DESC
      ''');
    } catch (e) {
      debugPrint('Error fetching debt customers: $e');
      _debtCustomers = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getCustomerDebts(int customerId) async {
    try {
      final db = await _db.database;
      return await db.rawQuery('''
        SELECT id, total_amount, paid_amount, created_at, (total_amount - paid_amount) as remaining_debt
        FROM transactions
        WHERE customer_id = ? AND payment_method = 'Hutang / Tempo' AND paid_amount < total_amount
        ORDER BY created_at ASC
      ''', [customerId]);
    } catch (e) {
      debugPrint('Error fetching customer debts: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getDebtPaymentsHistory(int transactionId) async {
    try {
      final db = await _db.database;
      return await db.query(
        'debt_payments',
        where: 'transaction_id = ?',
        whereArgs: [transactionId],
        orderBy: 'date DESC',
      );
    } catch (e) {
      debugPrint('Error fetching debt payments history: $e');
      return [];
    }
  }

  Future<void> payDebt(int transactionId, double amount) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // 1. Insert payment record
      await txn.insert('debt_payments', {
        'transaction_id': transactionId,
        'amount': amount,
        'date': DateTime.now().toIso8601String(),
        'is_synced': 0,
      });

      // 2. Update transaction paid_amount
      await txn.execute('''
        UPDATE transactions
        SET paid_amount = paid_amount + ?, is_synced = 0
        WHERE id = ?
      ''', [amount, transactionId]);
    });
    DatabaseService.hasUnsyncedChanges = true;

    await fetchDebtCustomers();
  }
}
