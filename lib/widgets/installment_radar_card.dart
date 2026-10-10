import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../models/category_model.dart';
import '../services/installment_service.dart';
import '../core/utils/formatters.dart';

class InstallmentRadarCard extends StatelessWidget {
  const InstallmentRadarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final installments = provider.activeInstallments;
        if (installments.isEmpty) return const SizedBox.shrink();

        final ongoingInstallments = installments.where((i) => !i.isCompleted).toList();
        final nextMonthTotal = provider.nextMonthInstallmentLiability;
        final totalFutureDebt = provider.totalFutureDebt;
        final previewItems = ongoingInstallments.isNotEmpty
            ? ongoingInstallments.take(3).toList()
            : installments.take(3).toList();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 5),
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
                      color: primaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.radar_rounded, color: primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Taksit Radarı',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Gelecek Ay Taksit Takvimi',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${ongoingInstallments.length} Devam Eden',
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Total Highlight Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Önümüzdeki Ay Kesin Taksit:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatCurrency(nextMonthTotal),
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: primaryColor),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Kalan Toplam Borç:',
                          style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatCurrency(totalFutureDebt),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Installment Items (Top 3 items)
              ...previewItems.map((item) {
                final cat = CategoryModel.findById(item.categoryId);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Icon(cat.icon, size: 14, color: const Color(0xFF94A3B8)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${Formatters.formatCurrency(item.monthlyAmount)} /ay',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFF1F5F9)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.progress,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(alpha: 0.1),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  item.isCompleted ? const Color(0xFF10B981) : primaryColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.isCompleted
                                ? '${item.totalInstallments}/${item.totalInstallments} (Bitti)'
                                : '${item.currentInstallment}/${item.totalInstallments} (${item.remainingInstallments} kaldı)',
                            style: TextStyle(
                              fontSize: 10,
                              color: item.isCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              if (installments.length > 3) ...[
                const SizedBox(height: 6),
                Center(
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: const Icon(Icons.list_alt_rounded, size: 16),
                    label: Text('Tüm Taksitleri Gör (${installments.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    onPressed: () => _showAllInstallmentsSheet(context, installments, primaryColor),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showAllInstallmentsSheet(BuildContext context, List<InstallmentItem> installments, Color primaryColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        int selectedTabIndex = 0; // 0: Devam Edenler, 1: Bitmiş Taksitler, 2: Tümü

        return StatefulBuilder(
          builder: (context, setSheetState) {
            final ongoingInstallments = installments.where((i) => !i.isCompleted).toList();
            final completedInstallments = installments.where((i) => i.isCompleted).toList();

            List<InstallmentItem> displayList;
            if (selectedTabIndex == 0) {
              displayList = ongoingInstallments;
            } else if (selectedTabIndex == 1) {
              displayList = completedInstallments;
            } else {
              displayList = installments;
            }

            final totalRemainingDebt = ongoingInstallments.fold(0.0, (sum, i) => sum + i.remainingDebt);
            final totalMonthlyCommitment = ongoingInstallments.fold(0.0, (sum, i) => sum + i.monthlyAmount);

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFF0F172A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.credit_card_rounded, color: Colors.white, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Taksitli Harcamalar',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${ongoingInstallments.length} Devam Eden',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Quick Stats Summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Aylık Taksit Yükü:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${Formatters.formatCurrency(totalMonthlyCommitment)} /ay',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: primaryColor),
                            ),
                          ],
                        ),
                        Container(width: 1, height: 28, color: Colors.white12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Kalan Toplam Borç:',
                              style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              Formatters.formatCurrency(totalRemainingDebt),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Segmented Tabs: Devam Edenler | Bitmiş Taksitler | Tümü
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabButton(
                          title: 'Devam Edenler (${ongoingInstallments.length})',
                          isSelected: selectedTabIndex == 0,
                          primaryColor: primaryColor,
                          onTap: () => setSheetState(() => selectedTabIndex = 0),
                        ),
                        _buildTabButton(
                          title: 'Bitmiş (${completedInstallments.length})',
                          isSelected: selectedTabIndex == 1,
                          primaryColor: const Color(0xFF10B981),
                          onTap: () => setSheetState(() => selectedTabIndex = 1),
                        ),
                        _buildTabButton(
                          title: 'Tümü (${installments.length})',
                          isSelected: selectedTabIndex == 2,
                          primaryColor: primaryColor,
                          onTap: () => setSheetState(() => selectedTabIndex = 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // List Content
                  Expanded(
                    child: displayList.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  selectedTabIndex == 1 ? Icons.check_circle_outline_rounded : Icons.credit_score_rounded,
                                  size: 48,
                                  color: Colors.white24,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  selectedTabIndex == 1
                                      ? 'Henüz tamamlanmış bir taksit bulunmuyor.'
                                      : 'Devam eden aktif bir taksit bulunmuyor.',
                                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: displayList.length,
                            separatorBuilder: (_, _) => const Divider(color: Colors.white10, height: 12),
                            itemBuilder: (context, index) {
                              final item = displayList[index];
                              final cat = CategoryModel.findById(item.categoryId);
                              final isCompleted = item.isCompleted;

                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? const Color(0xFF10B981).withValues(alpha: 0.05)
                                      : Colors.white.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCompleted
                                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.06),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isCompleted
                                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                : Colors.white.withValues(alpha: 0.08),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Icon(
                                            isCompleted ? Icons.check_circle_rounded : cat.icon,
                                            size: 18,
                                            color: isCompleted ? const Color(0xFF10B981) : Colors.white70,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.title,
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Row(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                    decoration: BoxDecoration(
                                                      color: isCompleted
                                                          ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                                          : primaryColor.withValues(alpha: 0.15),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '${item.currentInstallment}/${item.totalInstallments} Taksit',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.w700,
                                                        color: isCompleted ? const Color(0xFF10B981) : primaryColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    isCompleted
                                                        ? 'Tamamlandı'
                                                        : '${item.remainingInstallments} ay kaldı',
                                                    style: TextStyle(
                                                      fontSize: 11,
                                                      color: isCompleted ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                                      fontWeight: isCompleted ? FontWeight.w700 : FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(
                                              '${Formatters.formatCurrency(item.monthlyAmount)} /ay',
                                              style: const TextStyle(
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            if (!isCompleted)
                                              Text(
                                                'Kalan: ${Formatters.formatCurrency(item.remainingDebt)}',
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF94A3B8),
                                                ),
                                              )
                                            else
                                              Text(
                                                'Toplam: ${Formatters.formatCurrency(item.monthlyAmount * item.totalInstallments)}',
                                                style: const TextStyle(
                                                  fontSize: 10.5,
                                                  color: Color(0xFF10B981),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    if (!isCompleted) ...[
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: item.progress,
                                          minHeight: 5,
                                          backgroundColor: Colors.white.withValues(alpha: 0.08),
                                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
