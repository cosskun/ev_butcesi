import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/category_model.dart';
import '../models/category_budget_model.dart';
import '../models/transaction_model.dart';
import '../core/utils/formatters.dart';

class CategoryBudgetCard extends StatelessWidget {
  const CategoryBudgetCard({super.key});

  void _showSetBudgetDialog(BuildContext context, FinanceProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _BudgetSettingsSheet(provider: provider),
    );
  }

  void _showCategoryTransactionsSheet(
    BuildContext context,
    FinanceProvider provider,
    String categoryId,
    DateTime date,
    double limit,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CategoryTransactionsSheet(
        provider: provider,
        categoryId: categoryId,
        date: date,
        limit: limit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final budgets = provider.categoryBudgets;
        final selectedDate = provider.selectedDate;
        final txs = provider.transactions.where((t) {
          return t.date.year == selectedDate.year && t.date.month == selectedDate.month;
        }).toList();

        if (budgets.isEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.track_changes_rounded, color: primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aylık Bütçe Hedefi Koyun',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      Text(
                        'Market, Restoran harcamalarınıza limit koyarak tasarruf edin.',
                        style: TextStyle(fontSize: 11, color: textSecondary),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => _showSetBudgetDialog(context, provider),
                  child: const Text('Hedef Koy', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.track_changes_rounded, color: Color(0xFF10B981), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kategori Bütçe Hedefleri',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Limitler • ${DateFormat('MMMM yyyy', 'tr_TR').format(selectedDate)}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.tune_rounded, size: 20, color: textSecondary),
                    onPressed: () => _showSetBudgetDialog(context, provider),
                    tooltip: 'Limitleri Düzenle',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Budget Bars
              ...budgets.entries.map((entry) {
                final catId = entry.key;
                final limit = entry.value;
                final cat = CategoryModel.findById(catId);
                final budgetModel = CategoryBudgetModel(categoryId: catId, monthlyLimit: limit);

                final spent = txs
                    .where((t) => t.categoryId == catId && t.type == TransactionType.expense)
                    .fold(0.0, (sum, t) => sum + t.amount);

                final progress = budgetModel.getProgress(spent);
                final statusColor = budgetModel.getStatusColor(spent);
                final status = budgetModel.getStatus(spent);
                final remaining = budgetModel.getRemaining(spent);

                return InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showCategoryTransactionsSheet(context, provider, catId, selectedDate, limit),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 14, color: cat.color),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    cat.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${Formatters.formatCurrency(spent)} / ${Formatters.formatCurrency(limit)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 6,
                          backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              status == BudgetStatus.exceeded
                                  ? '⚠️ Bütçe ${Formatters.formatCurrency(-remaining)} aşıldı!'
                                  : (status == BudgetStatus.warning
                                      ? '⚡ Sınıra yaklaşıldı (${Formatters.formatCurrency(remaining)} kaldı)'
                                      : '${Formatters.formatCurrency(remaining)} bütçe kaldı'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '%${(progress * 100).toInt()}',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
            ],
          ),
        );
      },
    );
  }
}

class _BudgetSettingsSheet extends StatefulWidget {
  final FinanceProvider provider;
  const _BudgetSettingsSheet({required this.provider});

  @override
  State<_BudgetSettingsSheet> createState() => _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends State<_BudgetSettingsSheet> {
  late Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final cat in CategoryModel.defaultExpenseCategories) {
      final currentLimit = widget.provider.categoryBudgets[cat.id];
      _controllers[cat.id] = TextEditingController(
        text: currentLimit != null && currentLimit > 0 ? currentLimit.toInt().toString() : '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() async {
    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      final val = double.tryParse(text) ?? 0.0;
      await widget.provider.setCategoryBudget(entry.key, val);
    }
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bütçe limitleri başarıyla kaydedildi!'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sheetBg = theme.colorScheme.surface;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aylık Kategori Bütçeleri',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
              ),
              IconButton(
                icon: Icon(Icons.close_rounded, color: textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          Text(
            'Harcamalarınız bu limitlere yaklaştığında sistem sizi uyarır.',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: ListView(
              shrinkWrap: true,
              children: CategoryModel.defaultExpenseCategories.map((cat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: cat.bgColor, borderRadius: BorderRadius.circular(8)),
                        child: Icon(cat.icon, size: 16, color: cat.color),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(cat.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                      ),
                      SizedBox(
                        width: 110,
                        height: 38,
                        child: TextField(
                          controller: _controllers[cat.id],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.end,
                          style: TextStyle(color: textPrimary),
                          decoration: InputDecoration(
                            suffixText: '₺',
                            hintText: 'Limitsiz',
                            hintStyle: TextStyle(color: textSecondary.withValues(alpha: 0.6)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: _save,
              child: const Text('Limitleri Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryTransactionsSheet extends StatefulWidget {
  final FinanceProvider provider;
  final String categoryId;
  final DateTime date;
  final double limit;

  const _CategoryTransactionsSheet({
    required this.provider,
    required this.categoryId,
    required this.date,
    required this.limit,
  });

  @override
  State<_CategoryTransactionsSheet> createState() => _CategoryTransactionsSheetState();
}

class _CategoryTransactionsSheetState extends State<_CategoryTransactionsSheet> {
  void _changeCategory(TransactionModel tx) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kategoriyi Değiştir',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '"${tx.title}" işlemini taşımak istediğiniz kategoriyi seçin:',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: CategoryModel.defaultExpenseCategories.map((cat) {
                  final isCurrent = cat.id == tx.categoryId;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cat.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(cat.icon, color: cat.color, size: 20),
                    ),
                    title: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                        color: isCurrent ? theme.colorScheme.primary : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    trailing: isCurrent
                        ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final updatedTx = tx.copyWith(categoryId: cat.id);
                      await widget.provider.updateTransaction(updatedTx);
                      if (mounted) {
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('İşlem "${cat.name}" kategorisine aktarıldı.'),
                            backgroundColor: const Color(0xFF10B981),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cat = CategoryModel.findById(widget.categoryId);
    final primaryColor = theme.colorScheme.primary;
    final cardBg = theme.colorScheme.surface;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final txs = widget.provider.transactions.where((t) {
      return t.categoryId == widget.categoryId &&
          t.type == TransactionType.expense &&
          t.date.year == widget.date.year &&
          t.date.month == widget.date.month;
    }).toList();
    txs.sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = txs.fold(0.0, (sum, t) => sum + t.amount);
    final remaining = widget.limit - totalSpent;
    final isExceeded = remaining < 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(cat.icon, color: cat.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cat.name,
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                      ),
                      Text(
                        '${DateFormat('MMMM yyyy', 'tr_TR').format(widget.date)} Harcamaları',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Summary Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Toplam Harcama', style: TextStyle(fontSize: 11, color: textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(totalSpent),
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: textPrimary),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      isExceeded ? 'Aşılan Tutar' : 'Kalan Bütçe',
                      style: TextStyle(fontSize: 11, color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF10B981)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      Formatters.formatCurrency(remaining.abs()),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Hint Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'İşlemin yanındaki "Kategoriyi Değiştir" butonuna dokunarak başka kategoriye aktarabilirsiniz.',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : const Color(0xFF334155)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Transaction Count Header
          Text(
            '${txs.length} İşlem Kaydı',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textSecondary),
          ),
          const SizedBox(height: 6),

          // List
          Expanded(
            child: txs.isEmpty
                ? Center(
                    child: Text(
                      'Bu ay için bu kategoride harcama kaydı bulunmuyor.',
                      style: TextStyle(color: textSecondary, fontSize: 13),
                    ),
                  )
                : ListView.separated(
                    itemCount: txs.length,
                    separatorBuilder: (_, _) => Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9), height: 1),
                    itemBuilder: (context, index) {
                      final tx = txs[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.title,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(tx.date),
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  Formatters.formatCurrency(tx.amount),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                InkWell(
                                  borderRadius: BorderRadius.circular(6),
                                  onTap: () => _changeCategory(tx),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.swap_horiz_rounded, size: 13, color: primaryColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Kategoriyi Değiştir',
                                          style: TextStyle(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w600,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
