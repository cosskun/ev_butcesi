import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BudgetService {
  static const String _storageKey = 'kurusu_kurusuna_category_budgets';

  /// Default suggested budgets if none exist
  static final Map<String, double> defaultBudgets = {
    'market': 10000.0,
    'eglence': 4000.0,
    'fatura': 3000.0,
    'ulasim': 3000.0,
  };

  /// Loads all category budgets from storage
  static Future<Map<String, double>> loadBudgets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> decoded = jsonDecode(raw);
        return decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
      }
    } catch (_) {}
    return Map<String, double>.from(defaultBudgets);
  }

  /// Saves a budget limit for a specific category
  static Future<void> setBudget(String categoryId, double limit) async {
    final current = await loadBudgets();
    if (limit <= 0) {
      current.remove(categoryId);
    } else {
      current[categoryId] = limit;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(current));
  }

  /// Removes budget limit for a category
  static Future<void> removeBudget(String categoryId) async {
    final current = await loadBudgets();
    current.remove(categoryId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(current));
  }
}
