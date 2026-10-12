import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/monthly_report_modal.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _touchedIndex = -1;
  bool _showExpense = true;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final breakdown = _showExpense ? finance.expenseCategoryBreakdown : finance.incomeCategoryBreakdown;
    final totalAmount = _showExpense ? finance.monthlyExpense : finance.monthlyIncome;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar & Analiz'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: MonthSelector(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Financial Score & PDF Report Action Banner
            InkWell(
              onTap: () => MonthlyReportModal.show(context),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.12),
                      AppTheme.primary.withValues(alpha: 0.04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.primary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.assessment_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Aylık Finansal Karne & PDF',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sağlık skoru ve detaylı PDF raporu',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'İncele',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Segmented Switch (Gider Dağılımı | Gelir Dağılımı)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.divider,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      title: 'Gider Dağılımı',
                      isSelected: _showExpense,
                      onTap: () => setState(() => _showExpense = true),
                      color: AppTheme.expenseColor,
                    ),
                  ),
                  Expanded(
                    child: _buildTabButton(
                      title: 'Gelir Dağılımı',
                      isSelected: !_showExpense,
                      onTap: () => setState(() => _showExpense = false),
                      color: AppTheme.incomeColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pie Chart Card
            if (breakdown.isEmpty || totalAmount <= 0) ...[
              CustomCard(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.pie_chart_outline_rounded, size: 54, color: AppTheme.textMuted.withOpacity(0.5)),
                      const SizedBox(height: 12),
                      Text(
                        _showExpense ? 'Bu ay için henüz gider kaydı yok.' : 'Bu ay için henüz gelir kaydı yok.',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              CustomCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _showExpense ? 'Kategori Bazlı Giderler' : 'Kategori Bazlı Gelirler',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Toplam: ${Formatters.formatCurrency(totalAmount)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _showExpense ? AppTheme.expenseColor : AppTheme.incomeColor,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Pie Chart
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedIndex = -1;
                                  return;
                                }
                                _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 3,
                          centerSpaceRadius: 46,
                          sections: _generatePieSections(breakdown, totalAmount),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Category Details List
            if (breakdown.isNotEmpty) ...[
              const Text(
                'Kategori Listesi & Oranlar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              ...breakdown.entries.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = (amount / totalAmount) * 100;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: category.bgColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(category.icon, color: category.color, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  '%${percentage.toStringAsFixed(1)} pay',
                                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(amount),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0),
                          backgroundColor: AppTheme.divider,
                          color: category.color,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            const SizedBox(height: 20),

            // Cash vs Card breakdown card
            _buildPaymentMethodStats(finance),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? color : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<CategoryModel, double> breakdown, double total) {
    int index = 0;
    return breakdown.entries.map((entry) {
      final isTouched = index == _touchedIndex;
      final fontSize = isTouched ? 14.0 : 11.0;
      final radius = isTouched ? 58.0 : 50.0;
      final percentage = (entry.value / total) * 100;
      index++;

      return PieChartSectionData(
        color: entry.key.color,
        value: entry.value,
        title: '%${percentage.toStringAsFixed(0)}',
        radius: radius,
        titleStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildPaymentMethodStats(FinanceProvider finance) {
    double cashSpent = 0;
    double cardSpent = 0;

    for (final tx in finance.currentMonthTransactions.where((t) => t.type == TransactionType.expense)) {
      if (tx.paymentMethod == PaymentMethod.cash) {
        cashSpent += tx.amount;
      } else {
        cardSpent += tx.amount;
      }
    }

    final total = cashSpent + cardSpent;
    final cashPercent = total > 0 ? (cashSpent / total) * 100 : 0;
    final cardPercent = total > 0 ? (cardSpent / total) * 100 : 0;

    return CustomCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.compare_arrows_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Ödeme Yöntemi Dağılımı',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nakit Harcama', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text(Formatters.formatCurrency(cashSpent), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('%${cashPercent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.cashColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kart ile Harcama', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    const SizedBox(height: 4),
                    Text(Formatters.formatCurrency(cardSpent), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    Text('%${cardPercent.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: AppTheme.bankColor, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
