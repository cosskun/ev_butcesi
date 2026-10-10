import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../core/utils/formatters.dart';

class LargeTransfersCard extends StatelessWidget {
  const LargeTransfersCard({super.key});

  void _showSetThresholdDialog(BuildContext context, FinanceProvider provider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = TextEditingController(text: provider.largeTransferThreshold.toInt().toString());
    final quickAmounts = [5000.0, 10000.0, 20000.0, 50000.0, 100000.0];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
                'Yüksek Transfer Limiti Belirle',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Bu tutarın üzerindeki tüm para transferleri radarda listelenir.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),

              // Quick Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: quickAmounts.map((amt) {
                    final isSelected = controller.text == amt.toInt().toString();
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(
                          Formatters.formatCurrency(amt),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          ),
                        ),
                        backgroundColor: isSelected ? theme.colorScheme.primary : (isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                        onPressed: () {
                          setSheetState(() {
                            controller.text = amt.toInt().toString();
                          });
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),

              // Input field
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B)),
                decoration: InputDecoration(
                  labelText: 'Özel Alt Limit Tutarı',
                  suffixText: '₺',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(height: 18),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    final parsed = double.tryParse(controller.text.replaceAll('.', '').replaceAll(',', '.'));
                    if (parsed != null && parsed > 0) {
                      await provider.setLargeTransferThreshold(parsed);
                      if (context.mounted) Navigator.pop(ctx);
                    }
                  },
                  child: const Text('Limiti Kaydet', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllTransfersSheet(BuildContext context, List<TransactionModel> items, double threshold, DateTime date) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yüksek Tutarlı Transferler',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: textPrimary),
                    ),
                    Text(
                      '${Formatters.formatCurrency(threshold)} ve Üzeri • ${DateFormat('MMMM yyyy', 'tr_TR').format(date)}',
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, _) => Divider(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                itemBuilder: (context, index) {
                  final tx = items[index];
                  final isIncome = tx.type == TransactionType.income;
                  final cat = CategoryModel.findById(tx.categoryId);
                  final amtColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: amtColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: amtColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(tx.date),
                                    style: TextStyle(fontSize: 11, color: textSecondary),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: cat.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: cat.color),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isIncome ? '+' : '-'}${Formatters.formatCurrency(tx.amount)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: amtColor),
                        ),
                      ],
                    ),
                  );
                },
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
    final cardBg = theme.colorScheme.surface;
    final primaryColor = theme.colorScheme.primary;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E293B);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final threshold = provider.largeTransferThreshold;
        final selectedDate = provider.selectedDate;
        final items = provider.currentMonthLargeTransfers;

        final totalOutflow = items
            .where((t) => t.type == TransactionType.expense)
            .fold(0.0, (sum, t) => sum + t.amount);
        final totalInflow = items
            .where((t) => t.type == TransactionType.income)
            .fold(0.0, (sum, t) => sum + t.amount);

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.swap_vert_circle_rounded, color: Color(0xFFF59E0B), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yüksek Transferler',
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${Formatters.formatCurrency(threshold)} ve Üzeri • ${DateFormat('MMMM yyyy', 'tr_TR').format(selectedDate)}',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showSetThresholdDialog(context, provider),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.tune_rounded, size: 13, color: primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Limit',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Summary stats row
              if (items.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 16, color: Color(0xFFEF4444)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Büyük Çıkış', style: TextStyle(fontSize: 10, color: textSecondary)),
                              Text(
                                Formatters.formatCurrency(totalOutflow),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Container(width: 1, height: 24, color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Büyük Giriş', style: TextStyle(fontSize: 10, color: textSecondary)),
                              Text(
                                Formatters.formatCurrency(totalInflow),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF10B981)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // Item List
              if (items.isEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Bu ay ${Formatters.formatCurrency(threshold)} üzerinde transfer bulunmuyor.',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                  ),
                ),
              ] else ...[
                ...items.take(3).map((tx) {
                  final isIncome = tx.type == TransactionType.income;
                  final cat = CategoryModel.findById(tx.categoryId);
                  final amtColor = isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: amtColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: amtColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tx.title,
                                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Row(
                                children: [
                                  Text(
                                    DateFormat('d MMMM', 'tr_TR').format(tx.date),
                                    style: TextStyle(fontSize: 10.5, color: textSecondary),
                                  ),
                                  const SizedBox(width: 6),
                                  Text('•', style: TextStyle(fontSize: 10, color: textSecondary)),
                                  const SizedBox(width: 6),
                                  Text(
                                    cat.name,
                                    style: TextStyle(fontSize: 10.5, color: cat.color, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isIncome ? '+' : '-'}${Formatters.formatCurrency(tx.amount)}',
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: amtColor),
                        ),
                      ],
                    ),
                  );
                }),

                if (items.length > 3) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      ),
                      icon: const Icon(Icons.list_alt_rounded, size: 16),
                      label: Text(
                        'Tüm Yüksek Transferleri Gör (${items.length})',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      onPressed: () => _showAllTransfersSheet(context, items, threshold, selectedDate),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }
}
