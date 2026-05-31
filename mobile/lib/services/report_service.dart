import 'package:mobile/services/database_service.dart';

class ReportService {
  final DatabaseService _db = DatabaseService();

  Future<List<Map<String, dynamic>>> getStockReport() async {
    final db = await _db.database;
    // Get products with low stock (e.g., < 5) or just all products ordered by stock ASC
    // Filter out soft-deleted products
    return await db.query(
      'products',
      where: 'is_deleted = 0 OR is_deleted IS NULL',
      orderBy: 'stock ASC',
    );
  }

  /// Ambil daftar produk yang sudah dihapus (soft-delete) agar bisa
  /// dihapus permanen dari menu stok.
  Future<List<Map<String, dynamic>>> getDeletedProducts() async {
    final db = await _db.database;
    return await db.query(
      'products',
      where: 'is_deleted = 1',
      orderBy: 'name ASC',
    );
  }

  Future<Map<String, double>> getProfitLoss(DateTime start, DateTime end) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // 1. Get total revenue directly from transactions table (avoids duplicates from JOIN)
    final revenueResult = await db.rawQuery('''
      SELECT SUM(total_amount) as total_revenue
      FROM transactions
      WHERE created_at BETWEEN ? AND ?
    ''', [startStr, endStr]);

    // 2. Get total COGS (modal) from transaction_items table
    final cogsResult = await db.rawQuery('''
      SELECT SUM(ti.quantity * ti.cost_at_sale) as total_cogs
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.created_at BETWEEN ? AND ?
    ''', [startStr, endStr]);

    double revenue = (revenueResult.first['total_revenue'] as num?)?.toDouble() ?? 0.0;
    double cogs = (cogsResult.first['total_cogs'] as num?)?.toDouble() ?? 0.0;
    
    // Calculate Expenses
    final expensesResult = await db.rawQuery('''
      SELECT SUM(amount) as total_expenses
      FROM expenses
      WHERE date BETWEEN ? AND ?
    ''', [startStr, endStr]);
    
    double totalExpenses = (expensesResult.first['total_expenses'] as num?)?.toDouble() ?? 0.0;
    
    double grossProfit = revenue - cogs;
    double netProfit = grossProfit - totalExpenses;

    return {
      'revenue': revenue,
      'cogs': cogs,
      'grossProfit': grossProfit,
      'expenses': totalExpenses,
      'netProfit': netProfit,
    };
  }

  Future<List<Map<String, dynamic>>> getBestSellers(DateTime start, DateTime end) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    return await db.rawQuery('''
      SELECT 
        p.name,
        SUM(ti.quantity) as total_qty,
        SUM(ti.price_at_sale * ti.quantity) as total_sales
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      JOIN products p ON p.id = ti.product_id
      WHERE t.created_at BETWEEN ? AND ?
      GROUP BY p.id
      ORDER BY total_qty DESC
      LIMIT 10
    ''', [startStr, endStr]);
  }

  Future<List<Map<String, dynamic>>> getDailyProfitLoss(DateTime start, DateTime end) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    // Query daily revenue directly from transactions (no duplicate multiplication due to join)
    final revenueResult = await db.rawQuery('''
      SELECT 
        DATE(created_at) as date,
        SUM(total_amount) as revenue
      FROM transactions
      WHERE created_at BETWEEN ? AND ?
      GROUP BY DATE(created_at)
    ''', [startStr, endStr]);

    // Query daily COGS (modal) from transaction_items
    final cogsResult = await db.rawQuery('''
      SELECT 
        DATE(t.created_at) as date,
        SUM(ti.quantity * ti.cost_at_sale) as cogs
      FROM transaction_items ti
      JOIN transactions t ON t.id = ti.transaction_id
      WHERE t.created_at BETWEEN ? AND ?
      GROUP BY DATE(t.created_at)
    ''', [startStr, endStr]);

    // Query daily expenses
    final expenseResult = await db.rawQuery('''
      SELECT 
        DATE(date) as date,
        SUM(amount) as expenses
      FROM expenses
      WHERE date BETWEEN ? AND ?
      GROUP BY DATE(date)
      ORDER BY DATE(date) ASC
    ''', [startStr, endStr]);

    // Merge results
    Map<String, Map<String, double>> dailyData = {};

    for (var row in revenueResult) {
      String date = row['date'] as String;
      dailyData[date] = {
        'revenue': (row['revenue'] as num?)?.toDouble() ?? 0.0,
        'cogs': 0.0,
        'expenses': 0.0,
      };
    }

    for (var row in cogsResult) {
      String date = row['date'] as String;
      if (!dailyData.containsKey(date)) {
        dailyData[date] = {'revenue': 0.0, 'cogs': 0.0, 'expenses': 0.0};
      }
      dailyData[date]!['cogs'] = (row['cogs'] as num?)?.toDouble() ?? 0.0;
    }

    for (var row in expenseResult) {
      String date = row['date'] as String;
      if (!dailyData.containsKey(date)) {
        dailyData[date] = {'revenue': 0.0, 'cogs': 0.0, 'expenses': 0.0};
      }
      dailyData[date]!['expenses'] = (row['expenses'] as num?)?.toDouble() ?? 0.0;
    }

    // Convert map to sorted list
    List<Map<String, dynamic>> result = dailyData.entries.map((e) {
      double revenue = e.value['revenue']!;
      double cogs = e.value['cogs']!;
      double expenses = e.value['expenses']!;
      double netProfit = (revenue - cogs) - expenses;

      return {
        'date': e.key,
        'profit': netProfit,
      };
    }).toList();

    result.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    return result;
  }

  Future<List<Map<String, dynamic>>> getPaymentMethodsReport(DateTime start, DateTime end) async {
    final db = await _db.database;
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();

    return await db.rawQuery('''
      SELECT 
        payment_method,
        COUNT(id) as transaction_count,
        SUM(total_amount) as total_amount
      FROM transactions
      WHERE created_at BETWEEN ? AND ?
      GROUP BY payment_method
      ORDER BY total_amount DESC
    ''', [startStr, endStr]);
  }
}
