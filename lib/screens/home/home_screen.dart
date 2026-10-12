import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/transaction_model.dart';
import '../../providers/finance_provider.dart';
import '../../providers/investment_provider.dart';
import '../../widgets/month_selector.dart';
import '../../widgets/transaction_tile.dart';
import '../add_transaction/add_transaction_screen.dart';
import '../statement_import/statement_import_screen.dart';
import '../../widgets/theme_selector_modal.dart';
import '../../widgets/installment_radar_card.dart';
import '../../widgets/subscription_radar_card.dart';
import '../../widgets/category_budget_card.dart';
import '../../widgets/large_transfers_card.dart';
import '../../widgets/cash_flow_projection_card.dart';
import '../../widgets/credit_card_bill_alert_banner.dart';
import '../../widgets/backup_restore_dialog.dart';

class HomeScreen extends StatelessWidget {
  final Function(int)? onNavigateTab;

  const HomeScreen({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Consumer<FinanceProvider>(
      builder: (context, finance, child) {
        if (finance.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: () async {
                await finance.init();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top App Bar - Fully Responsive
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Screen Title & Icon
                        Expanded(
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(Icons.wallet_rounded, size: 20, color: primaryColor),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Ev Ekonomisi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Right: Theme & Backup Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: const Icon(Icons.cloud_sync_outlined, size: 18, color: Color(0xFF64748B)),
                              ),
                              tooltip: 'Yedekle / Geri Yükle',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => BackupRestoreSheet.show(context),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.border),
                                ),
                                child: Icon(Icons.palette_outlined, size: 18, color: primaryColor),
                              ),
                              tooltip: 'Tema & Renk Değiştir',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => ThemeSelectorModal.show(context),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Period Selector Bar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 16, color: primaryColor),
                              const SizedBox(width: 6),
                              const Flexible(
                                child: Text(
                                  'Dönem Özeti',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const MonthSelector(),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Net Worth & Balance Hero Card (Dynamic Theme Gradient)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'TOPLAM NET VARLIK',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.85),
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.savings_rounded, color: Colors.white, size: 13),
                                    const SizedBox(width: 4),
                                    Text(
                                      finance.monthlyNetSavings >= 0
                                          ? '+${Formatters.formatCurrency(finance.monthlyNetSavings)} Net'
                                          : '${Formatters.formatCurrency(finance.monthlyNetSavings)} Net',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              Formatters.formatCurrency(finance.totalNetWorth),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.account_balance_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Banka: ${Formatters.formatCurrency(finance.totalBankBalance)}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (finance.totalCreditDebt > 0) ...[
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 6),
                                    width: 1,
                                    height: 14,
                                    color: Colors.white30,
                                  ),
                                  Expanded(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.credit_card_rounded, color: Colors.white70, size: 14),
                                        const SizedBox(width: 5),
                                        Flexible(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              'Kart Borcu: ${Formatters.formatCurrency(finance.totalCreditDebt)}',
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Income & Expense Summary Cards
                    Row(
                      children: [
                        // Income Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.incomeBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.incomeColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.arrow_upward_rounded, color: AppTheme.incomeColor, size: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        'Bu Ay Gelir',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.incomeColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '+${Formatters.formatCurrency(finance.monthlyIncome)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.incomeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Expense Card
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.expenseBg,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppTheme.expenseColor.withValues(alpha: 0.2)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.arrow_downward_rounded, color: AppTheme.expenseColor, size: 14),
                                    ),
                                    const SizedBox(width: 6),
                                    const Flexible(
                                      child: Text(
                                        'Bu Ay Gider',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.expenseColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '-${Formatters.formatCurrency(finance.monthlyExpense)}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.expenseColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Quick Action Buttons
                    const Text(
                      'Hızlı İşlemler',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            label: 'Gider',
                            icon: Icons.remove_circle_outline_rounded,
                            color: AppTheme.expenseColor,
                            bgColor: AppTheme.expenseBg,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(initialType: TransactionType.expense),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            label: 'Gelir',
                            icon: Icons.add_circle_outline_rounded,
                            color: AppTheme.incomeColor,
                            bgColor: AppTheme.incomeBg,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(initialType: TransactionType.income),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            label: 'Nakit Çek',
                            icon: Icons.local_atm_rounded,
                            color: AppTheme.cashColor,
                            bgColor: AppTheme.cashBg,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const AddTransactionScreen(initialType: TransactionType.cashWithdrawal),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildQuickActionButton(
                            context,
                            label: 'Ekstre',
                            icon: Icons.document_scanner_rounded,
                            color: AppTheme.bankColor,
                            bgColor: AppTheme.bankBg,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const StatementImportScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Investment Portfolio Banner
                    Consumer<InvestmentProvider>(
                      builder: (context, invProvider, _) {
                        final totalVal = invProvider.totalPortfolioValue;
                        final totalPL = invProvider.totalProfitLoss;
                        final isProfitable = invProvider.isOverallProfitable;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: primaryColor.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.trending_up_rounded, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Yatırım & Varlık Portföyü',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            Formatters.formatCurrency(totalVal),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${isProfitable ? '+' : ''}${Formatters.formatCurrency(totalPL)})',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: isProfitable ? AppTheme.incomeColor : AppTheme.expenseColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () {
                                  if (onNavigateTab != null) {
                                    onNavigateTab!(2); // Navigate to Investments tab
                                  }
                                },
                                child: Row(
                                  children: [
                                    Text('İncele', style: TextStyle(color: primaryColor, fontWeight: FontWeight.w700, fontSize: 12)),
                                    Icon(Icons.chevron_right_rounded, color: primaryColor, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Kredi Kartı Son Ödeme Hatırlatıcısı
                    const CreditCardBillAlertBanner(),

                    // Akıllı Gelecek Ay & Nakit Akışı Tahmini
                    const CashFlowProjectionCard(),
                    const SizedBox(height: 14),

                    // Taksit Radarı (Gelecek Ay Taksit Takvimi)
                    const InstallmentRadarCard(),

                    // Kategori Bütçe Hedefleri (İlerleme Çubuğu)
                    const CategoryBudgetCard(),

                    // Yüksek Tutarlı Transferler Radarı
                    const LargeTransfersCard(),

                    // Unutulan Abonelik Dedektörü
                    const SubscriptionRadarCard(),

                    const SizedBox(height: 10),

                    // Recent Transactions Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Son İşlemler',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            if (onNavigateTab != null) {
                              onNavigateTab!(1); // Go to Timeline tab
                            }
                          },
                          child: Text('Tümünü Gör', style: TextStyle(color: primaryColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Recent Transactions List
                    if (finance.currentMonthTransactions.isEmpty) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.receipt_long_rounded, size: 44, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                              const SizedBox(height: 10),
                              const Text(
                                'Bu ay henüz işlem kaydınız yok.',
                                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      ...finance.currentMonthTransactions.take(5).map(
                        (tx) => TransactionTile(
                          transaction: tx,
                          onTap: () {
                            _showTransactionOptions(context, tx);
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTransactionOptions(BuildContext context, TransactionModel tx) {
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '${Formatters.formatCurrency(tx.amount)} • ${Formatters.formatDate(tx.date)}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
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
