import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';

class CategoryProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;

  Future<void> fetchCategories() async {
    _isLoading = true;
    notifyListeners();
    
    final db = await _db.database;
    _categories = await db.query('categories', orderBy: 'name ASC');
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name) async {
    await _db.insert('categories', {'name': name});
    await fetchCategories();
  }

  Future<void> updateCategory(int id, String name) async {
    await _db.update('categories', {'name': name}, id);
    await fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await _db.delete('categories', id);
    await fetchCategories();
  }
}
