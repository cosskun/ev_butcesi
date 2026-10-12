import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../models/investment_model.dart';
import '../../providers/investment_provider.dart';
import 'add_investment_screen.dart';

class InvestmentsScreen extends StatefulWidget {
  const InvestmentsScreen({super.key});

  @override
  State<InvestmentsScreen> createState() => _InvestmentsScreenState();
}

class _InvestmentsScreenState extends State<InvestmentsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<InvestmentProvider>();
      if (provider.investments.isNotEmpty) {
        provider.refreshAllPrices();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final investmentProvider = context.watch<InvestmentProvider>();
    final investments = investmentProvider.filteredInvestments;
    final totalVal = investmentProvider.totalPortfolioValue;
    final totalCost = investmentProvider.totalPortfolioCost;
    final totalPL = investmentProvider.totalProfitLoss;
    final totalPLPercent = investmentProvider.totalProfitLossPercent;
    final isProfitable = investmentProvider.isOverallProfitable;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final secondaryColor = theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Yatırımlar & Portföy'),
        actions: [
          IconButton(
            icon: investmentProvider.isRefreshingPrices
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : Icon(Icons.sync_rounded, size: 24, color: primaryColor),
            tooltip: 'Canlı Piyasa Fiyatlarını Güncelle',
            onPressed: investmentProvider.isRefreshingPrices
                ? null
                : () async {
                    final updatedCount = await context.read<InvestmentProvider>().refreshAllPrices();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white),
                              const SizedBox(width: 10),
                              Text('$updatedCount varlığın fiyatı canlı piyasadan güncellendi!'),
                            ],
                          ),
                          backgroundColor: primaryColor,
                        ),
                      );
                    }
                  },
          ),
          IconButton(
            icon: Icon(Icons.add_circle_outline_rounded, size: 26, color: primaryColor),
            tooltip: 'Yeni Yatırım Ekle',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<InvestmentProvider>().refreshAllPrices(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Live Market Update Status / Loading Banner
              if (investmentProvider.isRefreshingPrices)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: 0.12),
                        secondaryColor.withValues(alpha: 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: primaryColor.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.0,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Canlı piyasa kurları güncelleniyor...',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (investmentProvider.lastPriceRefreshTime != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppTheme.incomeColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.incomeColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: AppTheme.incomeColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Canlı Piyasa Senkronize • ${Formatters.formatTime(investmentProvider.lastPriceRefreshTime!)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.incomeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () => context.read<InvestmentProvider>().refreshAllPrices(),
                        child: const Row(
                          children: [
                            Icon(Icons.refresh_rounded, size: 13, color: AppTheme.incomeColor),
                            SizedBox(width: 3),
                            Text(
                              'Yenile',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.incomeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Portfolio Summary Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryColor, secondaryColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
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
                            'TOPLAM PORTFÖY DEĞERİ',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: isProfitable
                                ? AppTheme.incomeColor.withValues(alpha: 0.85)
                                : AppTheme.expenseColor.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isProfitable ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${isProfitable ? '+' : ''}%${totalPLPercent.toStringAsFixed(1)}',
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
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        Formatters.formatCurrency(totalVal),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Toplam Maliyet',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                                const SizedBox(height: 1),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    Formatters.formatCurrency(totalCost),
                                    style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 22, color: Colors.white24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Net Kâr / Zarar',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.8)),
                                ),
                                const SizedBox(height: 1),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${isProfitable ? '+' : ''}${Formatters.formatCurrency(totalPL)}',
                                    style: TextStyle(
                                      color: isProfitable ? const Color(0xFFA5D6A7) : const Color(0xFFFFAB91),
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips (Hepsi, Altın, Hisse, Döviz, Fon, Kripto)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      context,
                      label: 'Tüm Varlıklar (${investmentProvider.investments.length})',
                      isSelected: investmentProvider.filterType == null,
                      onSelected: () => investmentProvider.setFilterType(null),
                    ),
                    const SizedBox(width: 8),
                    ...InvestmentType.values.map((type) {
                      final count = investmentProvider.investments.where((i) => i.type == type).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterChip(
                          context,
                          label: '${type.displayName} ($count)',
                          icon: type.icon,
                          isSelected: investmentProvider.filterType == type,
                          activeColor: type.color,
                          onSelected: () => investmentProvider.setFilterType(type),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Assets List Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Varlık Listesi (${investments.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 17),
                    label: const Text('Varlık Ekle', style: TextStyle(fontSize: 13)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Investments List
              if (investments.isEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.show_chart_rounded, size: 36, color: AppTheme.textMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 6),
                        const Text(
                          'Bu kategoride henüz yatırım kaydı yok.',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: const Icon(Icons.add_rounded, size: 18),
                          label: const Text('Altın / Hisse Ekle', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AddInvestmentScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                ...investments.map((inv) => _buildInvestmentCard(context, inv)),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    IconData? icon,
    Color? activeColor,
  }) {
    final effectiveActiveColor = activeColor ?? Theme.of(context).colorScheme.primary;
    return ChoiceChip(
      avatar: icon != null ? Icon(icon, size: 14, color: isSelected ? Colors.white : effectiveActiveColor) : null,
      label: Text(label),
      selected: isSelected,
      selectedColor: effectiveActiveColor,
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? effectiveActiveColor : AppTheme.border),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected ? Colors.white : AppTheme.textSecondary,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildInvestmentCard(BuildContext context, InvestmentModel inv) {
    final isProfitable = inv.isProfitable;
    final plColor = isProfitable ? AppTheme.incomeColor : AppTheme.expenseColor;
    final plBg = isProfitable ? AppTheme.incomeBg : AppTheme.expenseBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
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
          onTap: () => _showInvestmentOptions(context, inv),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header: Icon + Title + Total Value
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: inv.type.bgColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(inv.type.icon, color: inv.type.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${inv.quantity} ${inv.type.unitLabel} • ${inv.symbol}',
                            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Formatters.formatCurrency(inv.totalCurrentValue),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: plBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${isProfitable ? '+' : ''}%${inv.profitLossPercent.toStringAsFixed(1)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: plColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 20, color: AppTheme.divider),

                // Bottom row: Buy Price vs Current Price & Profit Amount
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Alış: ${Formatters.formatCurrency(inv.buyUnitPrice)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 12, color: AppTheme.textMuted),
                        const SizedBox(width: 8),
                        Text(
                          'Güncel: ${Formatters.formatCurrency(inv.currentUnitPrice)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                        ),
                      ],
                    ),
                    Text(
                      '${isProfitable ? '+' : ''}${Formatters.formatCurrency(inv.profitLoss)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: plColor,
                      ),
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

  void _showInvestmentOptions(BuildContext context, InvestmentModel inv) {
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
                  inv.title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                ),
                Text(
                  '${inv.quantity} ${inv.type.unitLabel} • ${Formatters.formatCurrency(inv.totalCurrentValue)}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
                ),
                const Divider(height: 24, color: AppTheme.divider),

                // Quick update current price
                ListTile(
                  leading: Icon(Icons.price_change_rounded, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Güncel Fiyatı Güncelle', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('Şu anki: ${Formatters.formatCurrency(inv.currentUnitPrice)}'),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _showPriceUpdateDialog(context, inv);
                  },
                ),

                // Edit full investment
                ListTile(
                  leading: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary),
                  title: const Text('Yatırımı Düzenle', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => AddInvestmentScreen(editInvestment: inv),
                      ),
                    );
                  },
                ),

                // Delete investment
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: AppTheme.expenseColor),
                  title: const Text('Bu Yatırımı Sil', style: TextStyle(color: AppTheme.expenseColor, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    await context.read<InvestmentProvider>().deleteInvestment(inv.id);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPriceUpdateDialog(BuildContext context, InvestmentModel inv) {
    final controller = TextEditingController(text: inv.currentUnitPrice.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${inv.title} Güncel Fiyatı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Yeni birim fiyatını girerek kâr/zarar durumunuzu anlık güncelleyin:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(
                prefixText: '₺ ',
                labelText: 'Güncel Birim Fiyat',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPrice = double.tryParse(controller.text.replaceAll(',', '.').trim());
              if (newPrice != null && newPrice > 0) {
                await context.read<InvestmentProvider>().updateCurrentPrice(inv.id, newPrice);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('Güncelle'),
          ),
        ],
      ),
    );
  }
}
