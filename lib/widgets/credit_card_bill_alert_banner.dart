import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/finance_provider.dart';
import '../core/utils/formatters.dart';

class CreditCardBillAlertBanner extends StatelessWidget {
  const CreditCardBillAlertBanner({super.key});

  void _showMarkAsPaidDialog(BuildContext context, FinanceProvider provider, double debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 10),
            Text('Borcu Ödediniz mi?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Text(
          'Garanti Bonus kredi kartınızın ${Formatters.formatCurrency(debt)} tutarındaki dönem borcunu kapattıysanız, kart bakiyesini sıfırlayabilirsiniz.',
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              await provider.setOfficialWalletBalance('wallet_credit', 0.0);
              await provider.setCreditCardDueDate(null);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Kredi kartı borcunuz ödendi olarak güncellendi! 🎉'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Evet, Ödedim', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<FinanceProvider>(
      builder: (context, provider, _) {
        final dueDate = provider.creditCardDueDate;
        final creditDebt = provider.creditWallet?.balance ?? 0.0;
        final bankBalance = provider.bankWallet?.balance ?? 0.0;
        final minPayment = provider.creditCardMinPayment;

        if (dueDate == null || creditDebt <= 0) {
          return const SizedBox.shrink();
        }

        final daysLeft = provider.daysUntilCreditCardDue ?? 0;
        final isUrgent = daysLeft <= 1;
        final isOverdue = daysLeft < 0;

        Color bgGradientStart;
        Color bgGradientEnd;
        Color accentColor;
        String headerTitle;
        String badgeText;
        IconData headerIcon;

        if (isOverdue) {
          bgGradientStart = const Color(0xFF7F1D1D);
          bgGradientEnd = const Color(0xFF450A0A);
          accentColor = const Color(0xFFFCA5A5);
          headerTitle = 'Son Ödeme Tarihi Geçti!';
          badgeText = '${daysLeft.abs()} Gün Gecikti';
          headerIcon = Icons.warning_rounded;
        } else if (daysLeft == 0) {
          bgGradientStart = const Color(0xFF991B1B);
          bgGradientEnd = const Color(0xFF7F1D1D);
          accentColor = const Color(0xFFFECACA);
          headerTitle = '🚨 BUGÜN SON ÖDEME GÜNÜ!';
          badgeText = 'Son Gün';
          headerIcon = Icons.notification_important_rounded;
        } else if (daysLeft == 1) {
          bgGradientStart = const Color(0xFFC2410C);
          bgGradientEnd = const Color(0xFF9A3412);
          accentColor = const Color(0xFFFFEDD5);
          headerTitle = '⏰ YARIN SON ÖDEME GÜNÜ!';
          badgeText = 'Yarın';
          headerIcon = Icons.alarm_rounded;
        } else {
          bgGradientStart = const Color(0xFF1E293B);
          bgGradientEnd = const Color(0xFF0F172A);
          accentColor = const Color(0xFF38BDF8);
          headerTitle = 'Yaklaşan Kart Borcu';
          badgeText = '$daysLeft Gün Kaldı';
          headerIcon = Icons.event_available_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [bgGradientStart, bgGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: bgGradientStart.withValues(alpha: isUrgent ? 0.4 : 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isUrgent ? Colors.white.withValues(alpha: 0.25) : Colors.white10,
              width: isUrgent ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(headerIcon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            headerTitle,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                          Text(
                            'Son Gün: ${DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(dueDate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrgent ? Colors.white : Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isUrgent ? bgGradientStart : accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Info Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dönem Borcu', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatCurrency(creditDebt),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                    if (minPayment != null && minPayment > 0) ...[
                      Container(width: 1, height: 26, color: Colors.white24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Asgari Ödeme', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                          const SizedBox(height: 2),
                          Text(
                            Formatters.formatCurrency(minPayment),
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
                          ),
                        ],
                      ),
                    ],
                    Container(width: 1, height: 26, color: Colors.white24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Banka Hesabı', style: TextStyle(fontSize: 10.5, color: Colors.white70)),
                        const SizedBox(height: 2),
                        Text(
                          Formatters.formatCurrency(bankBalance),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: bankBalance >= creditDebt ? const Color(0xFF34D399) : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Bottom action row
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ).buildWith(
                      context,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, size: 16),
                          SizedBox(width: 6),
                          Text('Borcu Ödedim / Sıfırla', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ],
                      ),
                      onPressed: () => _showMarkAsPaidDialog(context, provider, creditDebt),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

extension on ButtonStyle {
  Widget buildWith(BuildContext context, {required Widget child, required VoidCallback onPressed}) {
    return ElevatedButton(
      style: this,
      onPressed: onPressed,
      child: child,
    );
  }
}
