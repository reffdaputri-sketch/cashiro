import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  static bool hasUnsyncedChanges = true; // Set to true initially to scan on launch

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'kiosly.db');
    return await openDatabase(
      path,
      version: 13,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE products ADD COLUMN image_path TEXT');
    }
    if (oldVersion < 3) {
      // Add cost_price and category to products
      await db.execute('ALTER TABLE products ADD COLUMN cost_price REAL DEFAULT 0.0');
      await db.execute('ALTER TABLE products ADD COLUMN category TEXT');

      // Create product_variations table
      await db.execute('''
        CREATE TABLE product_variations(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          stock INTEGER NOT NULL,
          sku TEXT,
          FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');
    }
    if (oldVersion < 4) {
      // Add cost_at_sale to transaction_items for profit calculation
      await db.execute('ALTER TABLE transaction_items ADD COLUMN cost_at_sale REAL DEFAULT 0.0');
    }
    if (oldVersion < 5) {
      // Create expenses table
      await db.execute('''
        CREATE TABLE expenses(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          description TEXT NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 6) {
      // Create customers table
      await db.execute('''
        CREATE TABLE customers(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT NOT NULL,
          created_at TEXT NOT NULL
        )
      ''');
      // Add customer_id to transactions
      await db.execute('ALTER TABLE transactions ADD COLUMN customer_id INTEGER');
    }
    if (oldVersion < 7) {
      // Create categories table
      await db.execute('''
        CREATE TABLE categories(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL UNIQUE
        )
      ''');
    }
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE staff(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          pin TEXT NOT NULL,
          role TEXT DEFAULT 'Cashier',
          permissions TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 9) {
      await db.execute("ALTER TABLE transactions ADD COLUMN payment_method TEXT DEFAULT 'Tunai'");
    }
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE shifts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          start_time TEXT NOT NULL,
          end_time TEXT,
          start_cash REAL NOT NULL,
          end_cash_expected REAL,
          end_cash_actual REAL,
          status TEXT DEFAULT 'Open'
        )
      ''');
      await db.execute('ALTER TABLE transactions ADD COLUMN shift_id INTEGER');
    }
    if (oldVersion < 11) {
      await db.execute('ALTER TABLE products ADD COLUMN min_stock INTEGER DEFAULT 5');
      await db.execute('''
        CREATE TABLE debt_payments(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          transaction_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          date TEXT NOT NULL,
          FOREIGN KEY(transaction_id) REFERENCES transactions(id)
        )
      ''');
    }
    if (oldVersion < 12) {
      final List<String> tables = [
        'products',
        'product_variations',
        'shifts',
        'transactions',
        'transaction_items',
        'expenses',
        'customers',
        'categories',
        'staff',
        'debt_payments'
      ];
      for (final table in tables) {
        try {
          await db.execute('ALTER TABLE $table ADD COLUMN is_synced INTEGER DEFAULT 0');
        } catch (e) {
          // ignore column already exists
        }
      }
    }
    if (oldVersion < 13) {
      await db.execute('ALTER TABLE products ADD COLUMN is_online INTEGER DEFAULT 0');
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE products(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        code TEXT,
        image_path TEXT,
        created_at TEXT NOT NULL,
        cost_price REAL DEFAULT 0.0,
        category TEXT,
        min_stock INTEGER DEFAULT 5,
        is_synced INTEGER DEFAULT 0,
        is_online INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE product_variations(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        sku TEXT,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        start_time TEXT NOT NULL,
        end_time TEXT,
        start_cash REAL NOT NULL,
        end_cash_expected REAL,
        end_cash_actual REAL,
        status TEXT DEFAULT 'Open',
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        total_amount REAL NOT NULL,
        paid_amount REAL NOT NULL,
        created_at TEXT NOT NULL,
        customer_id INTEGER,
        payment_method TEXT DEFAULT 'Tunai',
        shift_id INTEGER,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(shift_id) REFERENCES shifts(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE transaction_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        price_at_sale REAL NOT NULL,
        cost_at_sale REAL DEFAULT 0.0,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id),
        FOREIGN KEY(product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE customers(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT NOT NULL,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE staff(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        pin TEXT NOT NULL,
        role TEXT DEFAULT 'Cashier',
        permissions TEXT,
        created_at TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE debt_payments(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        transaction_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        is_synced INTEGER DEFAULT 0,
        FOREIGN KEY(transaction_id) REFERENCES transactions(id)
      )
    ''');
  }

  // Helper methods
  Future<int> insert(String table, Map<String, dynamic> data) async {
    final db = await database;
    hasUnsyncedChanges = true;
    return await db.insert(table, data);
  }

  Future<List<Map<String, dynamic>>> getAll(String table, {String? orderBy}) async {
    final db = await database;
    return await db.query(table, orderBy: orderBy);
  }

  Future<Map<String, dynamic>?> getById(String table, int id) async {
    final db = await database;
    final results = await db.query(table, where: 'id = ?', whereArgs: [id], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  Future<int> update(String table, Map<String, dynamic> data, int id) async {
    final db = await database;
    final Map<String, dynamic> mutableData = Map<String, dynamic>.from(data);
    final List<String> syncTables = [
      'categories',
      'products',
      'product_variations',
      'shifts',
      'transactions',
      'transaction_items',
      'expenses',
      'customers',
      'staff',
      'debt_payments'
    ];
    if (syncTables.contains(table) && !mutableData.containsKey('is_synced')) {
      mutableData['is_synced'] = 0;
      hasUnsyncedChanges = true;
    }
    return await db.update(table, mutableData, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> delete(String table, int id) async {
    final db = await database;
    hasUnsyncedChanges = true;
    return await db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  // Staff specific
  Future<Map<String, dynamic>?> getStaffByPin(String pin) async {
    final db = await database;
    final results = await db.query('staff', where: 'pin = ?', whereArgs: [pin], limit: 1);
    return results.isNotEmpty ? results.first : null;
  }
}
