import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/models/expense.dart';

class ExpenseProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Expense> _expenses = [];
  bool _isLoading = false;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;

  Future<void> fetchExpenses() async {
    _isLoading = true;
    notifyListeners();

    try {
      final maps = await _db.getAll('expenses', orderBy: 'date DESC');
      _expenses = maps.map((e) => Expense.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Error fetching expenses: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(Expense expense) async {
    await _db.insert('expenses', expense.toMap());
    await fetchExpenses();
  }

  Future<void> deleteExpense(int id) async {
    await _db.delete('expenses', id);
    await fetchExpenses();
  }
}
