import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/category_model.dart';
import '../providers/finance_provider.dart';
import '../services/cash_flow_projection_service.dart';

class CashFlowProjectionCard extends StatelessWidget {
  const CashFlowProjectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final projection = CashFlowProjectionService.calculateProjection(
      allTransactions: finance.allTransactions,
      activeInstallments: finance.activeInstallments,
      activeSubscriptions: finance.activeSubscriptions,
    );

    final isPositive = projection.projectedFreeCash >= 0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showProjectionDetailModal(context, projection),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.15),
                            primaryColor.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.auto_graph_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'Gelecek Ay Tahmini',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'AI Simülasyon',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Maaş, taksit ve fatura projeksiyonu',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted, size: 22),
                  ],
                ),
                const SizedBox(height: 14),

                // Free Cash Highlight Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppTheme.incomeColor.withValues(alpha: 0.08)
                        : AppTheme.expenseColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isPositive
                          ? AppTheme.incomeColor.withValues(alpha: 0.25)
                          : AppTheme.expenseColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cepte Kalacak Net Tutar',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isPositive ? AppTheme.incomeColor : AppTheme.expenseColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatCurrency(projection.projectedFreeCash),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: isPositive ? AppTheme.incomeColor : AppTheme.expenseColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isPositive ? AppTheme.incomeColor : AppTheme.expenseColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          isPositive
                              ? '%${projection.savingsPotentialPercent.toStringAsFixed(0)} Tasarruf'
                              : 'Bütçe Aşımı Riski',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 3 Mini Pillars (Gelir - Zorunlu Gider - Taksitler)
                Row(
                  children: [
                    _buildMiniPillar(
                      title: 'Beklenen Gelir',
                      amount: projection.expectedIncome,
                      color: AppTheme.incomeColor,
                    ),
                    Container(width: 1, height: 26, color: AppTheme.divider),
                    _buildMiniPillar(
                      title: 'Gelecek Taksitler',
                      amount: projection.nextMonthInstallments,
                      color: const Color(0xFFF57C00),
                    ),
                    Container(width: 1, height: 26, color: AppTheme.divider),
                    _buildMiniPillar(
                      title: 'Sabit / Faturalar',
                      amount: projection.nextMonthSubscriptions + projection.nextMonthBills,
                      color: AppTheme.expenseColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniPillar({
    required String title,
    required double amount,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          children: [
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                Formatters.formatCurrency(amount),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProjectionDetailModal(BuildContext context, CashFlowProjectionResult projection) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.insights_rounded, color: primaryColor, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Gelecek Ay Nakit Akışı Detayı',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Otomatik simüle edilmiş harcama ve takvim',
                            style: TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppTheme.divider),

              // Content List
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Detailed breakdown card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.08),
                            primaryColor.withValues(alpha: 0.02),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Tahmini Net Gelir / Maaş', projection.expectedIncome, AppTheme.incomeColor, isBold: true),
                          const Divider(height: 16, color: AppTheme.divider),
                          _buildDetailRow('Gelecek Ayın Taksitleri', -projection.nextMonthInstallments, const Color(0xFFF57C00)),
                          const SizedBox(height: 6),
                          _buildDetailRow('Abonelikler (Netflix, Spotify vb.)', -projection.nextMonthSubscriptions, AppTheme.expenseColor),
                          const SizedBox(height: 6),
                          _buildDetailRow('Tahmini Düzenli Faturalar', -projection.nextMonthBills, AppTheme.expenseColor),
                          const Divider(height: 16, color: AppTheme.divider),
                          _buildDetailRow(
                            'Serbest Bütçe (Cepte Kalan)',
                            projection.projectedFreeCash,
                            projection.projectedFreeCash >= 0 ? AppTheme.incomeColor : AppTheme.expenseColor,
                            isBold: true,
                            isLarge: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Upcoming Payment Schedule Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ödeme Takvimi & Risk Günleri',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                        ),
                        Text(
                          '${projection.scheduledPayments.length} Ödeme',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (projection.scheduledPayments.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'Gelecek ay için planlanmış taksit veya abonelik ödemesi bulunmuyor.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: AppTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      ...projection.scheduledPayments.map((item) {
                        final cat = CategoryModel.findById(item.categoryId);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'GÜN',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: primaryColor),
                                      ),
                                      Text(
                                        '${item.dayOfMonth}',
                                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: primaryColor),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${item.typeLabel} • ${cat.name}',
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-${Formatters.formatCurrency(item.amount)}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.expenseColor,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, double amount, Color color, {bool isBold = false, bool isLarge = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isLarge ? 13.5 : 12.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: isBold ? AppTheme.textPrimary : AppTheme.textSecondary,
            ),
          ),
        ),
        Text(
          amount < 0 ? '-${Formatters.formatCurrency(amount.abs())}' : Formatters.formatCurrency(amount),
          style: TextStyle(
            fontSize: isLarge ? 16 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
