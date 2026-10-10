import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/investment_model.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    const dbName = 'kurusu_kurusuna.db';
    Database db;

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath;
    } else {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      path = join(documentsDirectory.path, dbName);
    }

    db = await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );

    // Auto purge any legacy mock/sample items
    try {
      await db.delete('transactions', where: "id LIKE 'sample_%'");
      await db.delete('investments', where: "id LIKE 'inv_%'");
    } catch (_) {}

    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    // Transactions table
    await db.execute('''
      CREATE TABLE transactions(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category_id TEXT NOT NULL,
        date TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        image_path TEXT,
        note TEXT,
        source_wallet_id TEXT,
        target_wallet_id TEXT
      )
    ''');

    // Wallets table
    await db.execute('''
      CREATE TABLE wallets(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        balance REAL NOT NULL,
        icon_code INTEGER NOT NULL,
        color_value INTEGER NOT NULL,
        bank_name TEXT,
        card_limit REAL,
        cutoff_day INTEGER,
        due_day INTEGER,
        last_four_digits TEXT
      )
    ''');

    // Investments table
    await db.execute('''
      CREATE TABLE investments(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        symbol TEXT NOT NULL,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        buy_unit_price REAL NOT NULL,
        current_unit_price REAL NOT NULL,
        buy_date TEXT NOT NULL,
        note TEXT,
        source_wallet_id TEXT
      )
    ''');

    // Insert clean initial wallets with 0.0 balance
    for (final wallet in WalletModel.defaultWallets) {
      await db.insert('wallets', {
        ...wallet.toMap(),
        'balance': 0.0,
      });
    }
  }

  // --- Web Storage Helpers (localStorage via SharedPreferences) ---
  Future<List<TransactionModel>> _getWebTransactions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_transactions');
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((m) => TransactionModel.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveWebTransactions(List<TransactionModel> txs) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(txs.map((t) => t.toMap()).toList());
      await prefs.setString('web_transactions', raw);
    } catch (_) {}
  }

  Future<List<InvestmentModel>> _getWebInvestments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_investments');
      if (raw == null || raw.isEmpty) return [];
      final List<dynamic> list = jsonDecode(raw);
      return list.map((m) => InvestmentModel.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveWebInvestments(List<InvestmentModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_investments', jsonEncode(list.map((i) => i.toMap()).toList()));
    } catch (_) {}
  }

  /// Completely wipes all user transactions and investments and resets wallet balances to 0
  Future<void> resetAllData() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('web_transactions');
      await prefs.remove('web_investments');
      await prefs.remove('web_wallets');
      return;
    }
    final db = await database;
    await db.delete('transactions');
    await db.delete('investments');
    await db.update('wallets', {'balance': 0.0});
  }

  // Transaction CRUD
  Future<List<TransactionModel>> getAllTransactions() async {
    if (kIsWeb) {
      final txs = await _getWebTransactions();
      txs.sort((a, b) => b.date.compareTo(a.date));
      return txs;
    }
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'transactions',
      orderBy: 'date DESC',
    );
    return List.generate(maps.length, (i) => TransactionModel.fromMap(maps[i]));
  }

  Future<void> insertTransaction(TransactionModel transaction) async {
    if (kIsWeb) {
      final txs = await _getWebTransactions();
      txs.removeWhere((t) => t.id == transaction.id);
      txs.insert(0, transaction);
      await _saveWebTransactions(txs);
      return;
    }
    final db = await database;
    await db.insert(
      'transactions',
      transaction.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertMultipleTransactions(List<TransactionModel> transactions) async {
    if (kIsWeb) {
      final existing = await _getWebTransactions();
      final Map<String, TransactionModel> map = {for (var t in existing) t.id: t};
      for (final tx in transactions) {
        map[tx.id] = tx;
      }
      final updated = map.values.toList();
      updated.sort((a, b) => b.date.compareTo(a.date));
      await _saveWebTransactions(updated);
      return;
    }

    final db = await database;
    final batch = db.batch();
    for (final tx in transactions) {
      batch.insert(
        'transactions',
        tx.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    if (kIsWeb) {
      final txs = await _getWebTransactions();
      final idx = txs.indexWhere((t) => t.id == transaction.id);
      if (idx != -1) {
        txs[idx] = transaction;
        await _saveWebTransactions(txs);
      }
      return;
    }
    final db = await database;
    await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    if (kIsWeb) {
      final txs = await _getWebTransactions();
      txs.removeWhere((t) => t.id == id);
      await _saveWebTransactions(txs);
      return;
    }
    final db = await database;
    await db.delete(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearAllTransactions() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('web_transactions');
      return;
    }
    final db = await database;
    await db.delete('transactions');
  }

  // Investments CRUD
  Future<List<InvestmentModel>> getAllInvestments() async {
    if (kIsWeb) {
      return _getWebInvestments();
    }
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query(
        'investments',
        orderBy: 'buy_date DESC',
      );
      return List.generate(maps.length, (i) => InvestmentModel.fromMap(maps[i]));
    } catch (_) {
      return [];
    }
  }

  Future<void> insertInvestment(InvestmentModel investment) async {
    if (kIsWeb) {
      final list = await _getWebInvestments();
      list.removeWhere((i) => i.id == investment.id);
      list.insert(0, investment);
      await _saveWebInvestments(list);
      return;
    }
    final db = await database;
    await db.insert(
      'investments',
      investment.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    if (kIsWeb) {
      final list = await _getWebInvestments();
      final idx = list.indexWhere((i) => i.id == investment.id);
      if (idx != -1) {
        list[idx] = investment;
        await _saveWebInvestments(list);
      }
      return;
    }
    final db = await database;
    await db.update(
      'investments',
      investment.toMap(),
      where: 'id = ?',
      whereArgs: [investment.id],
    );
  }

  Future<void> deleteInvestment(String id) async {
    if (kIsWeb) {
      final list = await _getWebInvestments();
      list.removeWhere((i) => i.id == id);
      await _saveWebInvestments(list);
      return;
    }
    final db = await database;
    await db.delete(
      'investments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Wallet operations
  Future<List<WalletModel>> getAllWallets() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('web_wallets');
      if (raw != null && raw.isNotEmpty) {
        try {
          final List<dynamic> list = jsonDecode(raw);
          return list.map((m) => WalletModel.fromMap(Map<String, dynamic>.from(m))).toList();
        } catch (_) {}
      }
      return WalletModel.defaultWallets;
    }
    final db = await database;
    try {
      // Ensure any missing columns exist via graceful alter table
      try {
        await db.execute('ALTER TABLE wallets ADD COLUMN bank_name TEXT');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE wallets ADD COLUMN card_limit REAL');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE wallets ADD COLUMN cutoff_day INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE wallets ADD COLUMN due_day INTEGER');
      } catch (_) {}
      try {
        await db.execute('ALTER TABLE wallets ADD COLUMN last_four_digits TEXT');
      } catch (_) {}

      final List<Map<String, dynamic>> maps = await db.query('wallets');
      if (maps.isEmpty) {
        for (final wallet in WalletModel.defaultWallets) {
          await db.insert('wallets', {
            ...wallet.toMap(),
            'balance': 0.0,
          });
        }
        final List<Map<String, dynamic>> newMaps = await db.query('wallets');
        return List.generate(newMaps.length, (i) => WalletModel.fromMap(newMaps[i]));
      }
      return List.generate(maps.length, (i) => WalletModel.fromMap(maps[i]));
    } catch (_) {
      return WalletModel.defaultWallets;
    }
  }

  Future<void> insertWallet(WalletModel wallet) async {
    if (kIsWeb) {
      final list = await getAllWallets();
      list.removeWhere((w) => w.id == wallet.id);
      list.add(wallet);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_wallets', jsonEncode(list.map((w) => w.toMap()).toList()));
      return;
    }
    final db = await database;
    await db.insert(
      'wallets',
      wallet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateWallet(WalletModel wallet) async {
    if (kIsWeb) {
      final list = await getAllWallets();
      final idx = list.indexWhere((w) => w.id == wallet.id);
      if (idx != -1) {
        list[idx] = wallet;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('web_wallets', jsonEncode(list.map((w) => w.toMap()).toList()));
      }
      return;
    }
    final db = await database;
    await db.update(
      'wallets',
      wallet.toMap(),
      where: 'id = ?',
      whereArgs: [wallet.id],
    );
  }

  Future<void> deleteWallet(String id) async {
    if (kIsWeb) {
      final list = await getAllWallets();
      list.removeWhere((w) => w.id == id);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('web_wallets', jsonEncode(list.map((w) => w.toMap()).toList()));
      return;
    }
    final db = await database;
    await db.delete(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    if (kIsWeb) {
      final wallets = await getAllWallets();
      final idx = wallets.indexWhere((w) => w.id == walletId);
      if (idx != -1) {
        wallets[idx] = wallets[idx].copyWith(balance: newBalance);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('web_wallets', jsonEncode(wallets.map((w) => w.toMap()).toList()));
      }
      return;
    }
    final db = await database;
    await db.update(
      'wallets',
      {'balance': newBalance},
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }
}
