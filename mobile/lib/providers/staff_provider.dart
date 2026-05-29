import 'package:flutter/material.dart';
import 'package:mobile/services/database_service.dart';
import 'package:mobile/models/staff.dart';

class StaffProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<Staff> _staffs = [];
  bool _isLoading = false;

  List<Staff> get staffs => _staffs;
  bool get isLoading => _isLoading;

  Future<void> fetchStaffs() async {
    _isLoading = true;
    notifyListeners();
    
    final maps = await _db.getAll('staff', orderBy: 'id DESC');
    _staffs = maps.map((map) => Staff.fromMap(map)).toList();
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addStaff(Staff staff) async {
    await _db.insert('staff', staff.toMap()..remove('id'));
    await fetchStaffs();
  }

  Future<void> updateStaff(Staff staff) async {
    if (staff.id == null) return;
    await _db.update('staff', staff.toMap(), staff.id!);
    await fetchStaffs();
  }

  Future<void> deleteStaff(int id) async {
    await _db.delete('staff', id);
    await fetchStaffs();
  }
}
