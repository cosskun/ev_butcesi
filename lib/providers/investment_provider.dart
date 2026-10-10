import 'package:flutter/material.dart';
import '../models/investment_model.dart';
import '../services/database_service.dart';
import '../services/market_price_service.dart';

class InvestmentProvider with ChangeNotifier {
  final DatabaseService _db = DatabaseService();

  List<InvestmentModel> _investments = [];
  bool _isLoading = true;
  bool _isRefreshingPrices = false;
  DateTime? _lastPriceRefreshTime;
  InvestmentType? _filterType;

  bool get isLoading => _isLoading;
  bool get isRefreshingPrices => _isRefreshingPrices;
  DateTime? get lastPriceRefreshTime => _lastPriceRefreshTime;
  List<InvestmentModel> get investments => _investments;
  InvestmentType? get filterType => _filterType;

  List<InvestmentModel> get filteredInvestments {
    if (_filterType == null) return _investments;
    return _investments.where((inv) => inv.type == _filterType).toList();
  }

  double get totalPortfolioValue {
    return _investments.fold(0.0, (sum, item) => sum + item.totalCurrentValue);
  }

  double get totalPortfolioCost {
    return _investments.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  double get totalProfitLoss => totalPortfolioValue - totalPortfolioCost;

  double get totalProfitLossPercent {
    if (totalPortfolioCost <= 0) return 0.0;
    return (totalProfitLoss / totalPortfolioCost) * 100;
  }

  bool get isOverallProfitable => totalProfitLoss >= 0;

  Map<InvestmentType, double> get portfolioTypeBreakdown {
    final Map<InvestmentType, double> breakdown = {};
    for (final inv in _investments) {
      breakdown[inv.type] = (breakdown[inv.type] ?? 0.0) + inv.totalCurrentValue;
    }
    return breakdown;
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _loadData();
    } catch (e) {
      debugPrint('InvestmentProvider init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadData() async {
    _investments = await _db.getAllInvestments();
  }

  void setFilterType(InvestmentType? type) {
    _filterType = type;
    notifyListeners();
  }

  Future<void> addInvestment(InvestmentModel investment) async {
    await _db.insertInvestment(investment);
    _investments.insert(0, investment);
    notifyListeners();
  }

  Future<void> updateInvestment(InvestmentModel investment) async {
    await _db.updateInvestment(investment);
    final index = _investments.indexWhere((i) => i.id == investment.id);
    if (index != -1) {
      _investments[index] = investment;
    }
    notifyListeners();
  }

  Future<void> updateCurrentPrice(String id, double newPrice) async {
    final index = _investments.indexWhere((i) => i.id == id);
    if (index != -1) {
      final updated = _investments[index].copyWith(currentUnitPrice: newPrice);
      await _db.updateInvestment(updated);
      _investments[index] = updated;
      notifyListeners();
    }
  }

  /// Automatically fetches live prices from market APIs and updates all assets
  Future<int> refreshAllPrices() async {
    if (_isRefreshingPrices) return 0;
    _isRefreshingPrices = true;
    notifyListeners();

    int updatedCount = 0;
    for (int i = 0; i < _investments.length; i++) {
      final inv = _investments[i];
      try {
        final livePrice = await MarketPriceService.fetchLivePrice(inv);
        if (livePrice != null && livePrice > 0) {
          final updated = inv.copyWith(currentUnitPrice: livePrice);
          await _db.updateInvestment(updated);
          _investments[i] = updated;
          updatedCount++;
        }
      } catch (_) {}
    }

    _lastPriceRefreshTime = DateTime.now();
    _isRefreshingPrices = false;
    notifyListeners();
    return updatedCount;
  }

  Future<void> deleteInvestment(String id) async {
    await _db.deleteInvestment(id);
    _investments.removeWhere((i) => i.id == id);
    notifyListeners();
  }

  Future<void> resetAllData() async {
    _investments.clear();
    notifyListeners();
  }
}
