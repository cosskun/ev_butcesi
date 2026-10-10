import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/transaction_tile.dart';
import '../add_transaction/add_transaction_screen.dart';

enum SearchTimeScope { currentMonth, last3Months, thisYear, allTime }

class TimelineScreen extends StatefulWidget {
  const TimelineScreen({super.key});

  @override
  State<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends State<TimelineScreen> {
  bool _isSearchOpen = false;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  SearchTimeScope _timeScope = SearchTimeScope.allTime;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final finance = context.watch<FinanceProvider>();
    final isSearching = _searchQuery.trim().isNotEmpty;

    // Filter transactions based on search query and time scope
    List<TransactionModel> searchFilteredTxs = [];
    if (isSearching) {
      final queryLower = _searchQuery.trim().toLowerCase();
      final now = DateTime.now();

      searchFilteredTxs = finance.allTransactions.where((tx) {
        // Text Match (title, note, category)
        final titleMatch = tx.title.toLowerCase().contains(queryLower);
        final noteMatch = tx.note?.toLowerCase().contains(queryLower) ?? false;
        final catMatch = tx.categoryId.toLowerCase().contains(queryLower);
        if (!titleMatch && !noteMatch && !catMatch) return false;

        // Filter Type (income, expense, cash)
        if (finance.filterType != null && tx.type != finance.filterType) return false;

        // Time Scope Filter
        switch (_timeScope) {
          case SearchTimeScope.currentMonth:
            return tx.date.year == finance.selectedDate.year && tx.date.month == finance.selectedDate.month;
          case SearchTimeScope.last3Months:
            final threeMonthsAgo = now.subtract(const Duration(days: 90));
            return tx.date.isAfter(threeMonthsAgo);
          case SearchTimeScope.thisYear:
            return tx.date.year == now.year;
          case SearchTimeScope.allTime:
            return true;
        }
      }).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    }

    final groupedMap = finance.dailyGroupedTransactions;
    final sortedDays = groupedMap.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: _isSearchOpen
            ? TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: const TextStyle(fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Mağaza veya harcama ara (Migros, Trendyol)...',
                  hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (val) => setState(() => _searchQuery = val),
              )
            : const Text('Gün Gün Harcamalar'),
        actions: [
          IconButton(
            icon: Icon(_isSearchOpen ? Icons.close_rounded : Icons.search_rounded, color: primaryColor),
            tooltip: _isSearchOpen ? 'Aramayı Kapat' : 'Harcamalarda Ara',
            onPressed: () {
              setState(() {
                _isSearchOpen = !_isSearchOpen;
                if (!_isSearchOpen) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          if (!_isSearchOpen)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: MonthSelector(),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips (Hepsi, Giderler, Gelirler, Nakit Çekim)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip(
                    context,
                    label: 'Tüm Hareketler',
                    isSelected: finance.filterType == null,
                    activeColor: primaryColor,
                    onSelected: () => finance.setFilterType(null),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Sadece Giderler',
                    isSelected: finance.filterType == TransactionType.expense,
                    activeColor: AppTheme.expenseColor,
                    onSelected: () => finance.setFilterType(TransactionType.expense),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'Sadece Gelirler',
                    isSelected: finance.filterType == TransactionType.income,
                    activeColor: AppTheme.incomeColor,
                    onSelected: () => finance.setFilterType(TransactionType.income),
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    context,
                    label: 'ATM Çekimleri',
                    isSelected: finance.filterType == TransactionType.cashWithdrawal,
                    activeColor: AppTheme.cashColor,
                    onSelected: () => finance.setFilterType(TransactionType.cashWithdrawal),
                  ),
                ],
              ),
            ),
          ),

          // Search Scope Chips (When searching)
          if (isSearching)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildScopeChip('Tüm Zamanlar', SearchTimeScope.allTime, primaryColor),
                    const SizedBox(width: 6),
                    _buildScopeChip('Bu Yıl', SearchTimeScope.thisYear, primaryColor),
                    const SizedBox(width: 6),
                    _buildScopeChip('Son 3 Ay', SearchTimeScope.last3Months, primaryColor),
                    const SizedBox(width: 6),
                    _buildScopeChip('Seçili Ay', SearchTimeScope.currentMonth, primaryColor),
                  ],
                ),
              ),
            ),

          const Divider(height: 1, color: AppTheme.divider),

          // Search Mode vs Normal Day-by-Day Mode
          Expanded(
            child: isSearching
                ? _buildSearchResultsView(context, searchFilteredTxs, primaryColor)
                : _buildNormalTimelineView(context, sortedDays, groupedMap, primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultsView(BuildContext context, List<TransactionModel> txs, Color primaryColor) {
    if (txs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 52, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            Text(
              '"$_searchQuery" ile eşleşen işlem bulunamadı.',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
          ],
        ),
      );
    }

    // Compute Merchant / Store Analytics
    final totalCount = txs.length;
    final totalExpense = txs.where((t) => t.type == TransactionType.expense || t.type == TransactionType.cashWithdrawal).fold(0.0, (sum, t) => sum + t.amount);
    final totalIncome = txs.where((t) => t.type == TransactionType.income).fold(0.0, (sum, t) => sum + t.amount);
    final avgAmount = totalCount > 0 ? (totalExpense > 0 ? totalExpense / totalCount : totalIncome / totalCount) : 0.0;
    final lastDate = txs.first.date;
    final firstDate = txs.last.date;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Merchant Analytics Hero Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withValues(alpha: 0.1),
                primaryColor.withValues(alpha: 0.03),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: primaryColor.withValues(alpha: 0.22)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.analytics_rounded, color: primaryColor, size: 18),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '"$_searchQuery" Harcama Analizi',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: primaryColor),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$totalCount İşlem',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Toplam Harcama', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(totalExpense > 0 ? totalExpense : totalIncome),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: totalExpense > 0 ? AppTheme.expenseColor : AppTheme.incomeColor,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 26, color: AppTheme.divider),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('İşlem Başına Ort.', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      const SizedBox(height: 2),
                      Text(
                        Formatters.formatCurrency(avgAmount),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tarih Aralığı: ${Formatters.formatDate(firstDate)} - ${Formatters.formatDate(lastDate)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Result Transactions
        ...txs.map((tx) => TransactionTile(transaction: tx, onTap: () => _showTransactionDetail(context, tx))),
      ],
    );
  }

  Widget _buildNormalTimelineView(
    BuildContext context,
    List<DateTime> sortedDays,
    Map<DateTime, List<TransactionModel>> groupedMap,
    Color primaryColor,
  ) {
    if (sortedDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_rounded, size: 52, color: AppTheme.textMuted.withValues(alpha: 0.5)),
            const SizedBox(height: 14),
            const Text(
              'Bu ayda seçilen kriterde işlem bulunmuyor.',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni İşlem Ekle'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
                );
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final transactions = groupedMap[day]!;

        double dayExpense = 0;
        double dayIncome = 0;
        for (final tx in transactions) {
          if (tx.type == TransactionType.expense || tx.type == TransactionType.cashWithdrawal) {
            dayExpense += tx.amount;
          } else if (tx.type == TransactionType.income) {
            dayIncome += tx.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        Formatters.formatDate(day),
                        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (dayIncome > 0)
                        Text(
                          '+${Formatters.formatCurrency(dayIncome)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.incomeColor),
                        ),
                      if (dayIncome > 0 && dayExpense > 0) const SizedBox(width: 8),
                      if (dayExpense > 0)
                        Text(
                          '-${Formatters.formatCurrency(dayExpense)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.expenseColor),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            ...transactions.map(
              (tx) => TransactionTile(
                transaction: tx,
                onTap: () => _showTransactionDetail(context, tx),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required Color activeColor,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: activeColor,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? activeColor : AppTheme.border),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textSecondary,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildScopeChip(String label, SearchTimeScope scope, Color primaryColor) {
    final isSelected = _timeScope == scope;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: primaryColor.withValues(alpha: 0.15),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? primaryColor : AppTheme.border),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? primaryColor : AppTheme.textSecondary,
      ),
      onSelected: (_) => setState(() => _timeScope = scope),
    );
  }

  void _showTransactionDetail(BuildContext context, TransactionModel tx) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tx.title,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.formatCurrency(tx.amount)} • ${Formatters.formatDate(tx.date)}',
                  style: const TextStyle(fontSize: 13.5, color: AppTheme.textSecondary),
                ),
                const Divider(height: 24, color: AppTheme.divider),
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.expenseColor),
                  title: const Text('Bu İşlemi Sil', style: TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await context.read<FinanceProvider>().deleteTransaction(tx.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

