import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/formatters.dart';
import '../models/category_model.dart';
import '../models/transaction_model.dart';
import 'receipt_view_modal.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final category = CategoryModel.findById(transaction.categoryId);
    final isIncome = transaction.type == TransactionType.income;
    final isCash = transaction.type == TransactionType.cashWithdrawal;

    final Color amountColor = isIncome
        ? AppTheme.incomeColor
        : (isCash ? AppTheme.cashColor : AppTheme.expenseColor);

    final String prefix = isIncome ? '+' : (isCash ? '🏧 ' : '-');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border.withValues(alpha: 0.7)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Category Icon with soft tinted rounded box
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: isCash ? AppTheme.cashBg : category.bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isCash ? Icons.local_atm_rounded : category.icon,
                    color: isCash ? AppTheme.cashColor : category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),

                // Title, Subtitle, Payment Method & Note
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              transaction.title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (transaction.imagePath != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () {
                                ReceiptViewModal.show(
                                  context,
                                  transaction.imagePath!,
                                  transaction.title,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.photo_camera_rounded, size: 12, color: Theme.of(context).colorScheme.primary),
                                    const SizedBox(width: 3),
                                    Text(
                                      'Fiş',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            transaction.date.hour == 0 && transaction.date.minute == 0
                                ? DateFormat('d MMMM yyyy', 'tr_TR').format(transaction.date)
                                : '${DateFormat("d MMM", "tr_TR").format(transaction.date)}, ${DateFormat("HH:mm").format(transaction.date)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMuted,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 3,
                            height: 3,
                            decoration: const BoxDecoration(
                              color: AppTheme.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.paymentMethod.displayName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 3,
                              height: 3,
                              decoration: const BoxDecoration(
                                color: AppTheme.textMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                transaction.note!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Amount
                Text(
                  '$prefix${Formatters.formatCurrency(transaction.amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
