import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transaction_model.dart';
import '../models/wallet_model.dart';
import '../models/category_model.dart';
import '../models/category_budget_model.dart';
import '../services/database_service.dart';
import '../services/installment_service.dart';
import '../services/subscription_service.dart';
import '../services/budget_service.dart';
import '../services/statement_parser_service.dart';

class FinanceProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<TransactionModel> _transactions = [];
  List<WalletModel> _wallets = WalletModel.defaultWallets;
  Map<String, double> _categoryBudgets = {};
  double? _officialBankBalance;
  double? _officialCreditDebt;
  DateTime? _creditCardDueDate;
  double? _creditCardMinPayment;
  double _largeTransferThreshold = 10000.0;
  bool _isLoading = true;

  DateTime _selectedDate = DateTime.now();
  TransactionType? _filterType;
  String? _filterCategoryId;

  // Getters
  bool get isLoading => _isLoading;
  List<TransactionModel> get transactions => _transactions;
  List<TransactionModel> get allTransactions => _transactions;
  List<WalletModel> get wallets => _wallets;
  Map<String, double> get categoryBudgets => _categoryBudgets;
  DateTime get selectedDate => _selectedDate;
  TransactionType? get filterType => _filterType;
  String? get filterCategoryId => _filterCategoryId;
  double get largeTransferThreshold => _largeTransferThreshold;
  DateTime? get creditCardDueDate => _creditCardDueDate;
  double? get creditCardMinPayment => _creditCardMinPayment;

  int? get daysUntilCreditCardDue {
    if (_creditCardDueDate == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(_creditCardDueDate!.year, _creditCardDueDate!.month, _creditCardDueDate!.day);
    return due.difference(today).inDays;
  }

  List<TransactionModel> get currentMonthLargeTransfers {
    return _transactions.where((t) {
      final matchesMonth = t.date.year == _selectedDate.year && t.date.month == _selectedDate.month;
      if (!matchesMonth) return false;
      return t.amount >= _largeTransferThreshold;
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  }

  // Installment Radar Getters
  List<InstallmentItem> get activeInstallments => InstallmentService.detectInstallments(_transactions);
  double get nextMonthInstallmentLiability => InstallmentService.calculateNextMonthLiability(activeInstallments);
  double get totalFutureDebt => InstallmentService.calculateTotalFutureDebt(activeInstallments);

  // Subscription Radar Getters
  List<SubscriptionItem> get activeSubscriptions => SubscriptionService.detectSubscriptions(_transactions);
  double get monthlySubscriptionTotal => SubscriptionService.calculateMonthlyTotal(activeSubscriptions);

  // Initialize and load
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadData();
    } catch (e) {
      debugPrint('FinanceProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadData() async {
    _transactions = await _db.getAllTransactions();
    _categoryBudgets = await BudgetService.loadBudgets();
    try {
      final prefs = await SharedPreferences.getInstance();
      _officialBankBalance = prefs.getDouble('official_bank_balance');
      _officialCreditDebt = prefs.getDouble('official_credit_debt');
      final rawDueDate = prefs.getString('credit_card_due_date');
      if (rawDueDate != null) {
        _creditCardDueDate = DateTime.tryParse(rawDueDate);
      }
      _creditCardMinPayment = prefs.getDouble('credit_card_min_payment');
      _largeTransferThreshold = prefs.getDouble('large_transfer_threshold') ?? 10000.0;
    } catch (_) {}

    final dbWallets = await _db.getAllWallets();
    if (dbWallets.isNotEmpty) {
      _wallets = dbWallets;
    }

    // Auto-clean any legacy fake card payment income transactions
    final legacyCardPayments = _transactions.where((t) {
      if (t.type != TransactionType.income) return false;
      final u = t.title.toUpperCase();
      return u.contains('ÖDEMENİZ İÇİN TEŞEKKÜR') ||
          u.contains('ODEMENIZ ICIN TESEKKUR') ||
          u.contains('KREDİ KARTI BORÇ ÖDEMESİ') ||
          u.contains('KREDI KARTI BORC ODEMESI') ||
          u.contains('K.KARTI ÖDEME') ||
          u.contains('K.KARTI ODEME');
    }).toList();

    for (final legacy in legacyCardPayments) {
      await _db.deleteTransaction(legacy.id);
      _transactions.removeWhere((tx) => tx.id == legacy.id);
    }

    // Auto-fix any misclassified transactions across all categories (e.g. Amazon/Trendyol -> Alışveriş, bank suffix cleanup)
    for (int i = 0; i < _transactions.length; i++) {
      final tx = _transactions[i];
      final isCash = tx.type == TransactionType.cashWithdrawal;
      final isIncome = tx.type == TransactionType.income;

      // Clean trailing bank tags if present
      String cleanTitle = tx.title
          .replaceAll(RegExp(r'\s*(İSTANBUL|ISTANBUL|ANKARA|BURSA|İZMİR|IZMIR|MSBILL\.INFO)?\s*(Market|Sağlık / Bakım|Saglik / Bakim|Yeme / İçme|Yeme / Icme|Ev / Dekorasyon|Giyim / Aksesuar|Eğlence / Hobi|Eglence / Hobi|Vergi|Diğer|Diger|Alışveriş|Alısveris|Kurum Ödemesi|Para Transferi|Para Çekme|Para Yatırma|Kart Ödemesi|Kart Odemesi|Faiz / Komisyon|Faiz/Komisyon)\s*(?=\s*\(\d+/\d+\)|\s*$)', caseSensitive: false), '')
          .trim();

      final predictedCat = StatementParserService.autoClassifyCategory(cleanTitle.isNotEmpty ? cleanTitle : tx.title, isIncome, isCash);
      
      // If current category needs updating:
      bool shouldUpdate = false;
      String newCategory = tx.categoryId;

      if (predictedCat != 'diger_gider' && tx.categoryId != predictedCat) {
        if (tx.categoryId == 'fatura' || 
            tx.categoryId == 'diger_gider' || 
            tx.categoryId == 'diger' || 
            (tx.categoryId == 'market' && (predictedCat == 'alisveris' || predictedCat == 'giyim' || predictedCat == 'kisisel_bakim' || predictedCat == 'saglik'))) {
          newCategory = predictedCat;
          shouldUpdate = true;
        }
      }

      if (cleanTitle != tx.title && cleanTitle.isNotEmpty) {
        shouldUpdate = true;
      }

      if (shouldUpdate) {
        final updated = tx.copyWith(
          title: cleanTitle.isNotEmpty ? cleanTitle : tx.title,
          categoryId: newCategory,
        );
        await _db.updateTransaction(updated);
        _transactions[i] = updated;
      }
    }

    _recalculateWalletBalances();
  }

  Future<void> setCreditCardDueDate(DateTime? dueDate, {double? minPayment}) async {
    _creditCardDueDate = dueDate;
    _creditCardMinPayment = minPayment;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (dueDate != null) {
        await prefs.setString('credit_card_due_date', dueDate.toIso8601String());
      } else {
        await prefs.remove('credit_card_due_date');
      }
      if (minPayment != null) {
        await prefs.setDouble('credit_card_min_payment', minPayment);
      } else {
        await prefs.remove('credit_card_min_payment');
      }
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setLargeTransferThreshold(double threshold) async {
    _largeTransferThreshold = threshold;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('large_transfer_threshold', threshold);
    } catch (_) {}
    notifyListeners();
  }

  Future<void> setOfficialWalletBalance(String walletId, double balance) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (walletId == 'wallet_bank') {
        _officialBankBalance = balance;
        await prefs.setDouble('official_bank_balance', balance);
      } else if (walletId == 'wallet_credit') {
        _officialCreditDebt = balance;
        await prefs.setDouble('official_credit_debt', balance);
      }
    } catch (_) {}
    _recalculateWalletBalances();
    notifyListeners();
  }

  Future<void> reloadAll() async {
    await _loadData();
    notifyListeners();
  }

  Future<void> setCategoryBudget(String categoryId, double limit) async {
    await BudgetService.setBudget(categoryId, limit);
    _categoryBudgets = await BudgetService.loadBudgets();
    notifyListeners();
  }

  CategoryBudgetModel? getBudgetForCategory(String categoryId) {
    final limit = _categoryBudgets[categoryId];
    if (limit == null || limit <= 0) return null;
    return CategoryBudgetModel(categoryId: categoryId, monthlyLimit: limit);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  void setFilterType(TransactionType? type) {
    _filterType = type;
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  // Transactions filtered by selected Month & Year
  List<TransactionModel> get currentMonthTransactions {
    return _transactions.where((t) {
      final matchesMonth = t.date.year == _selectedDate.year && t.date.month == _selectedDate.month;
      if (!matchesMonth) return false;

      if (_filterType != null && t.type != _filterType) return false;
      if (_filterCategoryId != null && t.categoryId != _filterCategoryId) return false;

      return true;
    }).toList();
  }

  // Grouped by day (Date without time)
  Map<DateTime, List<TransactionModel>> get dailyGroupedTransactions {
    final Map<DateTime, List<TransactionModel>> grouped = {};
    for (final tx in currentMonthTransactions) {
      final dayKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      if (!grouped.containsKey(dayKey)) {
        grouped[dayKey] = [];
      }
      grouped[dayKey]!.add(tx);
    }
    return grouped;
  }

  // Monthly totals
  double get monthlyIncome {
    return currentMonthTransactions
        .where((t) {
          if (t.type != TransactionType.income) return false;
          final u = t.title.toUpperCase();
          if (u.contains('KREDİ KARTI') ||
              u.contains('KREDI KARTI') ||
              u.contains('K.KARTI') ||
              u.contains('ÖDEMENİZ İÇİN TEŞEKKÜR') ||
              u.contains('ODEMENIZ ICIN TESEKKUR') ||
              u.contains('KART ÖDEMESİ') ||
              u.contains('KART ODEMESI')) {
            return false;
          }
          return true;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyExpense {
    return currentMonthTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyCashWithdrawal {
    return currentMonthTransactions
        .where((t) => t.type == TransactionType.cashWithdrawal)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyNetSavings => monthlyIncome - monthlyExpense;

  // Wallet balances
  // Wallet Getters (Multi-Bank & Multi-Card)
  List<WalletModel> get bankWallets => _wallets.where((w) => w.type == WalletType.bank).toList();
  List<WalletModel> get creditWallets => _wallets.where((w) => w.type == WalletType.creditCard).toList();

  double get totalBankBalance {
    if (bankWallets.isEmpty) return 0.0;
    return bankWallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  double get totalCreditDebt {
    if (creditWallets.isEmpty) return 0.0;
    return creditWallets.fold(0.0, (sum, w) => sum + w.balance);
  }

  WalletModel? get bankWallet {
    if (_wallets.isEmpty) return null;
    try {
      return _wallets.firstWhere((w) => w.type == WalletType.bank);
    } catch (_) {
      return _wallets.first;
    }
  }

  WalletModel? get cashWallet {
    if (_wallets.isEmpty) return null;
    try {
      return _wallets.firstWhere((w) => w.id == 'wallet_cash' || w.type == WalletType.cash);
    } catch (_) {
      return _wallets.first;
    }
  }

  WalletModel? get creditWallet {
    if (_wallets.isEmpty) return null;
    try {
      return _wallets.firstWhere((w) => w.type == WalletType.creditCard);
    } catch (_) {
      return _wallets.first;
    }
  }

  double get totalNetWorth {
    final bank = totalBankBalance;
    final cash = cashWallet?.balance ?? 0.0;
    final credit = totalCreditDebt;
    return bank + cash - credit;
  }

  // Multi-wallet CRUD
  Future<void> addWallet(WalletModel wallet) async {
    await _db.insertWallet(wallet);
    _wallets.add(wallet);
    _recalculateWalletBalances();
    notifyListeners();
  }

  Future<void> updateWallet(WalletModel wallet) async {
    await _db.updateWallet(wallet);
    final idx = _wallets.indexWhere((w) => w.id == wallet.id);
    if (idx != -1) {
      _wallets[idx] = wallet;
    }
    _recalculateWalletBalances();
    notifyListeners();
  }

  Future<void> deleteWallet(String walletId) async {
    // Preserve default cash wallet
    if (walletId == 'wallet_cash') return;
    await _db.deleteWallet(walletId);
    _wallets.removeWhere((w) => w.id == walletId);
    _recalculateWalletBalances();
    notifyListeners();
  }

  // Category breakdown for statistics (Expense)
  Map<CategoryModel, double> get expenseCategoryBreakdown {
    final Map<String, double> categorySums = {};
    for (final tx in currentMonthTransactions.where((t) => t.type == TransactionType.expense)) {
      categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
    }

    final Map<CategoryModel, double> result = {};
    categorySums.forEach((catId, total) {
      final cat = CategoryModel.findById(catId);
      result[cat] = total;
    });

    return result;
  }

  // Category breakdown for income
  Map<CategoryModel, double> get incomeCategoryBreakdown {
    final Map<String, double> categorySums = {};
    for (final tx in currentMonthTransactions.where((t) => t.type == TransactionType.income)) {
      categorySums[tx.categoryId] = (categorySums[tx.categoryId] ?? 0.0) + tx.amount;
    }

    final Map<CategoryModel, double> result = {};
    categorySums.forEach((catId, total) {
      final cat = CategoryModel.findById(catId);
      result[cat] = total;
    });

    return result;
  }

  // Add transaction
  Future<void> addTransaction(TransactionModel tx) async {
    await _db.insertTransaction(tx);
    _transactions.insert(0, tx);
    _recalculateWalletBalances();
    notifyListeners();
  }

  // Batch import from statement
  Future<void> importTransactions(List<TransactionModel> txList) async {
    await _db.insertMultipleTransactions(txList);
    _transactions.addAll(txList);
    _transactions.sort((a, b) => b.date.compareTo(a.date));
    _recalculateWalletBalances();
    notifyListeners();
  }

  // Update transaction
  Future<void> updateTransaction(TransactionModel tx) async {
    await _db.updateTransaction(tx);
    final index = _transactions.indexWhere((item) => item.id == tx.id);
    if (index != -1) {
      _transactions[index] = tx;
    }
    _recalculateWalletBalances();
    notifyListeners();
  }

  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _transactions.removeWhere((tx) => tx.id == id);
    _recalculateWalletBalances();
    notifyListeners();
  }

  // Recalculate dynamic wallet balances based on transactions
  void _recalculateWalletBalances() {
    double bank = _officialBankBalance ?? 0.0;
    double cash = 0.0;
    double credit = _officialCreditDebt ?? 0.0;

    for (final tx in _transactions) {
      final isCardPayment = tx.title.toLowerCase().contains('k.kartı ödeme') ||
          tx.title.toLowerCase().contains('k.karti odeme') ||
          tx.title.toLowerCase().contains('kart ödemesi') ||
          tx.title.toLowerCase().contains('kart odemesi') ||
          tx.title.toLowerCase().contains('kredi kartı ödeme') ||
          tx.title.toLowerCase().contains('kredi karti odeme') ||
          tx.title.toLowerCase().contains('ödemeniz için teşekkür');

      if (tx.type == TransactionType.income) {
        if (tx.paymentMethod == PaymentMethod.cash) {
          cash += tx.amount;
        } else if (tx.paymentMethod == PaymentMethod.creditCard) {
          credit -= tx.amount;
        } else {
          if (_officialBankBalance == null) {
            bank += tx.amount;
          }
        }
      } else if (tx.type == TransactionType.expense) {
        if (tx.paymentMethod == PaymentMethod.cash) {
          cash -= tx.amount;
        } else if (tx.paymentMethod == PaymentMethod.creditCard) {
          if (_officialCreditDebt == null) {
            credit += tx.amount;
          }
        } else {
          if (_officialBankBalance == null) {
            bank -= tx.amount;
          }
          // If bank account paid credit card debt, reduce credit card debt
          if (isCardPayment) {
            credit -= tx.amount;
          }
        }
      } else if (tx.type == TransactionType.cashWithdrawal) {
        if (_officialBankBalance == null) {
          bank -= tx.amount;
        }
        // Nakit çekimleri harcandığı varsayılır, cüzdanda biriktirilmez
      }
    }

    if (credit < 0) credit = 0.0;

    _wallets = [
      WalletModel(
        id: 'wallet_bank',
        name: 'Banka Hesabı',
        type: WalletType.bank,
        balance: bank,
        icon: Icons.account_balance_rounded,
        color: const Color(0xFF1976D2),
      ),
      WalletModel(
        id: 'wallet_cash',
        name: 'Nakit Cüzdanı',
        type: WalletType.cash,
        balance: cash,
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFF43A047),
      ),
      WalletModel(
        id: 'wallet_credit',
        name: 'Kredi Kartı',
        type: WalletType.creditCard,
        balance: credit,
        icon: Icons.credit_card_rounded,
        color: const Color(0xFF8E24AA),
      ),
    ];
  }

  // Reset all transactions and wallet balances to clean state
  Future<void> resetAllData() async {
    await _db.resetAllData();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('official_bank_balance');
      await prefs.remove('official_credit_debt');
    } catch (_) {}
    _officialBankBalance = null;
    _officialCreditDebt = null;
    _transactions.clear();
    _recalculateWalletBalances();
    notifyListeners();
  }
}
