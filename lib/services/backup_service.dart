import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/transaction_model.dart';
import '../models/investment_model.dart';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';
import 'budget_service.dart';

class BackupResult {
  final bool success;
  final String message;
  final int transactionCount;
  final int investmentCount;
  final String? filePath;

  const BackupResult({
    required this.success,
    required this.message,
    this.transactionCount = 0,
    this.investmentCount = 0,
    this.filePath,
  });
}

class BackupService {
  static final DatabaseService _db = DatabaseService();

  /// Exports all data into a JSON string
  static Future<String> generateBackupJson() async {
    final transactions = await _db.getAllTransactions();
    final wallets = await _db.getAllWallets();
    final investments = await _db.getAllInvestments();
    final budgets = await BudgetService.loadBudgets();

    final Map<String, dynamic> backupData = {
      'app': 'kurusu_kurusuna',
      'version': '1.0.0',
      'timestamp': DateTime.now().toIso8601String(),
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'wallets': wallets.map((w) => w.toMap()).toList(),
      'investments': investments.map((i) => i.toMap()).toList(),
      'category_budgets': budgets,
    };

    return const JsonEncoder.withIndent('  ').convert(backupData);
  }

  /// Saves backup to a file in documents/downloads directory
  static Future<BackupResult> exportToFile() async {
    try {
      final jsonString = await generateBackupJson();
      final now = DateTime.now();
      final fileName = 'kurusu_kurusuna_yedek_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}_${now.hour}${now.minute}.json';

      if (kIsWeb) {
        return BackupResult(
          success: true,
          message: 'Yedek verisi hazırlandı.',
          filePath: fileName,
        );
      }

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      final txs = await _db.getAllTransactions();
      final invs = await _db.getAllInvestments();

      return BackupResult(
        success: true,
        message: 'Yedek başarıyla oluşturuldu: $fileName',
        transactionCount: txs.length,
        investmentCount: invs.length,
        filePath: file.path,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Yedekleme başarısız: $e',
      );
    }
  }

  /// Restores data from JSON string
  static Future<BackupResult> restoreFromJson(String jsonContent) async {
    try {
      final Map<String, dynamic> data = jsonDecode(jsonContent);

      if (data['app'] != 'kurusu_kurusuna' || !data.containsKey('transactions')) {
        return const BackupResult(
          success: false,
          message: 'Geçersiz veya uyumsuz yedek dosyası formatı.',
        );
      }

      final List<dynamic> txList = data['transactions'] ?? [];
      final List<dynamic> invList = data['investments'] ?? [];
      final Map<String, dynamic>? budgets = data['category_budgets'];

      final db = await _db.database;

      // Insert or replace transactions
      int restoredTx = 0;
      for (final raw in txList) {
        try {
          final tx = TransactionModel.fromMap(raw as Map<String, dynamic>);
          await db.insert(
            'transactions',
            tx.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          restoredTx++;
        } catch (_) {}
      }

      // Insert or replace investments
      int restoredInv = 0;
      for (final raw in invList) {
        try {
          final inv = InvestmentModel.fromMap(raw as Map<String, dynamic>);
          await db.insert(
            'investments',
            inv.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          restoredInv++;
        } catch (_) {}
      }

      // Restore category budgets
      if (budgets != null) {
        for (final entry in budgets.entries) {
          final limit = (entry.value as num?)?.toDouble() ?? 0.0;
          if (limit > 0) {
            await BudgetService.setBudget(entry.key, limit);
          }
        }
      }

      return BackupResult(
        success: true,
        message: 'Yedek başarıyla geri yüklendi.',
        transactionCount: restoredTx,
        investmentCount: restoredInv,
      );
    } catch (e) {
      return BackupResult(
        success: false,
        message: 'Geri yükleme hatası: $e',
      );
    }
  }
}
