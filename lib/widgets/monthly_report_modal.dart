import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../providers/finance_provider.dart';
import '../services/financial_report_service.dart';

class MonthlyReportModal extends StatefulWidget {
  const MonthlyReportModal({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const MonthlyReportModal(),
    );
  }

  @override
  State<MonthlyReportModal> createState() => _MonthlyReportModalState();
}

class _MonthlyReportModalState extends State<MonthlyReportModal> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final summary = FinancialReportService.generateSummary(
      period: finance.selectedDate,
      monthTransactions: finance.currentMonthTransactions,
      categoryBreakdown: finance.expenseCategoryBreakdown,
      installmentTotal: finance.nextMonthInstallmentLiability,
      subscriptionTotal: finance.monthlySubscriptionTotal,
    );

    final monthName = DateFormat('MMMM yyyy', 'tr_TR').format(summary.period);

    Color scoreColor;
    if (summary.healthScore >= 75) {
      scoreColor = AppTheme.incomeColor;
    } else if (summary.healthScore >= 50) {
      scoreColor = Colors.amber.shade700;
    } else {
      scoreColor = AppTheme.expenseColor;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Finansal Karne & Skor',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        monthName,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Health Score Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          scoreColor.withValues(alpha: 0.12),
                          scoreColor.withValues(alpha: 0.03),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: scoreColor.withValues(alpha: 0.3), width: 1.5),
                    ),
                    child: Row(
                      children: [
                        // Score Circle
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: scoreColor.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: scoreColor, width: 3),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${summary.healthScore}',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: scoreColor,
                                    height: 1.0,
                                  ),
                                ),
                                const Text(
                                  '/ 100',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Title & Desc
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                summary.statusTitle,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                summary.statusDescription,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Metrics Grid (4 items)
                  const Text(
                    'Aylık Performans Özeti',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Toplam Gelir',
                          value: Formatters.formatCurrency(summary.totalIncome),
                          color: AppTheme.incomeColor,
                          icon: Icons.arrow_downward_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Toplam Gider',
                          value: Formatters.formatCurrency(summary.totalExpense),
                          color: AppTheme.expenseColor,
                          icon: Icons.arrow_upward_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Net Tasarruf',
                          value: Formatters.formatCurrency(summary.netSavings),
                          subtitle: '%${summary.savingsRate.toStringAsFixed(1)} birikim oranı',
                          color: summary.netSavings >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                          icon: Icons.savings_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Taksit & Abonelik',
                          value: Formatters.formatCurrency(summary.installmentTotal + summary.subscriptionTotal),
                          subtitle: 'Sabit taahhüt',
                          color: Colors.blueGrey.shade700,
                          icon: Icons.repeat_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 3. Top Spending Categories
                  if (summary.topCategories.isNotEmpty) ...[
                    const Text(
                      'En Çok Harcanan Kategoriler',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...summary.topCategories.take(4).map((entry) {
                      final cat = entry.key;
                      final amount = entry.value;
                      final ratio = summary.totalExpense > 0 ? (amount / summary.totalExpense * 100) : 0.0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.divider.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: cat.bgColor,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cat.name,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    'Giderlerin %${ratio.toStringAsFixed(0)}\'i',
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(amount),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                  ],

                  // 4. Largest Transactions
                  if (summary.topExpenses.isNotEmpty) ...[
                    const Text(
                      'Ayın En Yüksek Harcamaları',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 12),
                    ...summary.topExpenses.take(3).map((tx) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    DateFormat('dd MMMM yyyy', 'tr_TR').format(tx.date),
                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Formatters.formatCurrency(tx.amount),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.expenseColor),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),

          // Bottom Action Button: PDF Export
          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _handleExportPdf(summary),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_rounded, size: 22),
                label: Text(
                  _isExporting ? 'PDF Hazırlanıyor...' : 'PDF Finansal Raporu İndir & Kaydet',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.divider.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleExportPdf(MonthlyHealthSummary summary) async {
    setState(() => _isExporting = true);
    try {
      final File pdfFile = await FinancialReportService.generatePdfReport(summary);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.incomeColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'PDF Raporu kaydedildi:\n${pdfFile.path.split(Platform.pathSeparator).last}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.expenseColor,
          content: Text('PDF oluşturulurken hata: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }
}
