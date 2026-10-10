import '../models/transaction_model.dart';
import 'installment_service.dart';
import 'subscription_service.dart';

class ScheduledPaymentItem {
  final String title;
  final double amount;
  final int dayOfMonth;
  final String typeLabel; // 'Taksit', 'Abonelik', 'Fatura / Sabit'
  final String categoryId;

  const ScheduledPaymentItem({
    required this.title,
    required this.amount,
    required this.dayOfMonth,
    required this.typeLabel,
    required this.categoryId,
  });
}

class CashFlowProjectionResult {
  final double expectedIncome;
  final double nextMonthInstallments;
  final double nextMonthSubscriptions;
  final double nextMonthBills;
  final double totalCommittedExpenses;
  final double projectedFreeCash;
  final double savingsPotentialPercent;
  final List<ScheduledPaymentItem> scheduledPayments;
  final Map<int, double> dailyOutflowMap; // day -> total outflow

  const CashFlowProjectionResult({
    required this.expectedIncome,
    required this.nextMonthInstallments,
    required this.nextMonthSubscriptions,
    required this.nextMonthBills,
    required this.totalCommittedExpenses,
    required this.projectedFreeCash,
    required this.savingsPotentialPercent,
    required this.scheduledPayments,
    required this.dailyOutflowMap,
  });

  bool get isHealthy => projectedFreeCash > 0;
}

class CashFlowProjectionService {
  /// Calculates comprehensive next month cash flow simulation
  static CashFlowProjectionResult calculateProjection({
    required List<TransactionModel> allTransactions,
    required List<InstallmentItem> activeInstallments,
    required List<SubscriptionItem> activeSubscriptions,
    double? customExpectedIncome,
  }) {
    // 1. Calculate Expected Next Month Income
    double expectedIncome = customExpectedIncome ?? 0.0;
    if (expectedIncome <= 0) {
      // Find average regular income across the last 3 months with income records
      final Map<String, double> monthlyIncomes = {};
      for (final tx in allTransactions) {
        if (tx.type == TransactionType.income) {
          final u = tx.title.toUpperCase();
          if (u.contains('KREDİ KARTI') ||
              u.contains('KREDI KARTI') ||
              u.contains('K.KARTI') ||
              u.contains('ÖDEMENİZ İÇİN TEŞEKKÜR') ||
              u.contains('ODEMENIZ ICIN TESEKKUR') ||
              u.contains('KART ÖDEMESİ') ||
              u.contains('KART ODEMESI')) {
            continue;
          }
          final key = '${tx.date.year}-${tx.date.month}';
          monthlyIncomes[key] = (monthlyIncomes[key] ?? 0.0) + tx.amount;
        }
      }

      if (monthlyIncomes.isNotEmpty) {
        final recentIncomes = monthlyIncomes.values.toList();
        final sum = recentIncomes.fold(0.0, (prev, element) => prev + element);
        expectedIncome = sum / recentIncomes.length;
      }
    }

    // Default fallback if no income data exists yet
    if (expectedIncome <= 0) {
      expectedIncome = 45000.0; // standard baseline estimation
    }

    // 2. Next Month Installments Liability
    final nextMonthInstallments = InstallmentService.calculateNextMonthLiability(activeInstallments);

    // 3. Next Month Subscriptions Liability
    final nextMonthSubscriptions = SubscriptionService.calculateMonthlyTotal(activeSubscriptions);

    // 4. Next Month Estimated Recurring Bills (fatura, kira, aidat)
    double nextMonthBills = 0.0;
    final Map<String, double> recentBillSums = {};
    for (final tx in allTransactions) {
      if (tx.type == TransactionType.expense &&
          (tx.categoryId == 'fatura' ||
              tx.categoryId == 'kira' ||
              tx.categoryId == 'aidat' ||
              tx.title.toLowerCase().contains('fatura') ||
              tx.title.toLowerCase().contains('kira') ||
              tx.title.toLowerCase().contains('aidat') ||
              tx.title.toLowerCase().contains('turkcell') ||
              tx.title.toLowerCase().contains('vodafone') ||
              tx.title.toLowerCase().contains('turk telekom') ||
              tx.title.toLowerCase().contains('superonline') ||
              tx.title.toLowerCase().contains('enerjisa') ||
              tx.title.toLowerCase().contains('iski') ||
              tx.title.toLowerCase().contains('igdas'))) {
        final key = '${tx.date.year}-${tx.date.month}';
        recentBillSums[key] = (recentBillSums[key] ?? 0.0) + tx.amount;
      }
    }

    if (recentBillSums.isNotEmpty) {
      final bills = recentBillSums.values.toList();
      nextMonthBills = bills.fold(0.0, (a, b) => a + b) / bills.length;
    }

    // 5. Total Committed Expenses & Free Cash
    final totalCommittedExpenses = nextMonthInstallments + nextMonthSubscriptions + nextMonthBills;
    final projectedFreeCash = expectedIncome - totalCommittedExpenses;
    final savingsPotentialPercent = expectedIncome > 0
        ? ((projectedFreeCash / expectedIncome) * 100).clamp(-100.0, 100.0)
        : 0.0;

    // 6. Schedule Items Timeline
    final List<ScheduledPaymentItem> payments = [];
    final Map<int, double> dailyOutflows = {};

    // Add installments to schedule
    for (final inst in activeInstallments) {
      if (inst.isCompleted) continue;
      final day = inst.date.day.clamp(1, 28);
      payments.add(ScheduledPaymentItem(
        title: inst.title,
        amount: inst.monthlyAmount,
        dayOfMonth: day,
        typeLabel: 'Taksit (${inst.currentInstallment + 1}/${inst.totalInstallments})',
        categoryId: inst.categoryId,
      ));
      dailyOutflows[day] = (dailyOutflows[day] ?? 0.0) + inst.monthlyAmount;
    }

    // Add subscriptions to schedule
    for (final sub in activeSubscriptions) {
      final day = sub.lastBilledDate.day.clamp(1, 28);
      payments.add(ScheduledPaymentItem(
        title: sub.name,
        amount: sub.monthlyAmount,
        dayOfMonth: day,
        typeLabel: 'Abonelik',
        categoryId: 'fatura',
      ));
      dailyOutflows[day] = (dailyOutflows[day] ?? 0.0) + sub.monthlyAmount;
    }

    // Sort by day of month
    payments.sort((a, b) => a.dayOfMonth.compareTo(b.dayOfMonth));

    return CashFlowProjectionResult(
      expectedIncome: expectedIncome,
      nextMonthInstallments: nextMonthInstallments,
      nextMonthSubscriptions: nextMonthSubscriptions,
      nextMonthBills: nextMonthBills,
      totalCommittedExpenses: totalCommittedExpenses,
      projectedFreeCash: projectedFreeCash,
      savingsPotentialPercent: savingsPotentialPercent,
      scheduledPayments: payments,
      dailyOutflowMap: dailyOutflows,
    );
  }
}
