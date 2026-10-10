import '../models/transaction_model.dart';

class InstallmentItem {
  final String transactionId;
  final String title;
  final double monthlyAmount;
  final int currentInstallment;
  final int totalInstallments;
  final DateTime date;
  final String categoryId;

  const InstallmentItem({
    required this.transactionId,
    required this.title,
    required this.monthlyAmount,
    required this.currentInstallment,
    required this.totalInstallments,
    required this.date,
    required this.categoryId,
  });

  int get remainingInstallments => (totalInstallments - currentInstallment).clamp(0, totalInstallments);
  double get remainingDebt => monthlyAmount * remainingInstallments;
  double get progress => totalInstallments > 0 ? (currentInstallment / totalInstallments).clamp(0.0, 1.0) : 1.0;
  bool get isCompleted => currentInstallment >= totalInstallments;

  /// Estimated completion date
  DateTime get estimatedEndDate {
    final year = date.year + ((date.month + remainingInstallments - 1) ~/ 12);
    final month = ((date.month + remainingInstallments - 1) % 12) + 1;
    return DateTime(year, month, date.day);
  }
}

class InstallmentService {
  /// Scans transactions, cleans titles, and extracts unique installment plans
  static List<InstallmentItem> detectInstallments(List<TransactionModel> transactions) {
    final Map<String, InstallmentItem> planMap = {};

    // Pattern 1: Bank formula: "6.000,00x5=30.000,00 4.Taksit" or "746,31x3=2.238,94 3.Taksit" or "x3 1.Taksit"
    final bankMultiplierRegex = RegExp(
      r'x\s*(\d+)(?:=[\d\.,]+)?\s+(\d+)\s*\.?\s*Taksit',
      caseSensitive: false,
    );
    // Pattern 2: "(1/3)" or "2/6 Taksit"
    final fractionRegex = RegExp(r'\(?\s*(\d+)\s*/\s*(\d+)(?:\s*Taksit)?\s*\)?', caseSensitive: false);
    // Pattern 3: "3 Taksit" or "1.Taksit"
    final singleTaksitRegex = RegExp(r'(\d+)\s*\.?\s*Taksit', caseSensitive: false);

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;

      int current = 1;
      int total = 1;
      bool matched = false;

      final multMatch = bankMultiplierRegex.firstMatch(tx.title);
      final fracMatch = fractionRegex.firstMatch(tx.title);

      if (multMatch != null) {
        total = int.tryParse(multMatch.group(1) ?? '1') ?? 1;
        current = int.tryParse(multMatch.group(2) ?? '1') ?? 1;
        matched = true;
      } else if (fracMatch != null) {
        current = int.tryParse(fracMatch.group(1) ?? '1') ?? 1;
        total = int.tryParse(fracMatch.group(2) ?? '1') ?? 1;
        matched = true;
      } else {
        final singleMatch = singleTaksitRegex.firstMatch(tx.title);
        if (singleMatch != null) {
          final num = int.tryParse(singleMatch.group(1) ?? '1') ?? 1;
          if (tx.title.contains('Toplam') || tx.title.contains('Ay')) {
            total = num;
            current = 1;
          } else {
            current = num;
            final xMatch = RegExp(r'x\s*(\d+)', caseSensitive: false).firstMatch(tx.title);
            if (xMatch != null) {
              total = int.tryParse(xMatch.group(1) ?? '1') ?? num;
            } else {
              total = num;
            }
          }
          matched = true;
        }
      }

      if (matched && total > 1) {
        // Clean title from installment tags, formulas and city/market suffixes
        String cleanTitle = tx.title
            .replaceAll(RegExp(r'\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?\s*x\s*\d+\s*(?:=\s*\d{1,3}(?:\.\d{3})*(?:,\d{1,2})?)?', caseSensitive: false), '')
            .replaceAll(RegExp(r'\d+\s*\.?\s*Taksit', caseSensitive: false), '')
            .replaceAll(bankMultiplierRegex, '')
            .replaceAll(fractionRegex, '')
            .replaceAll(singleTaksitRegex, '')
            .replaceAll(RegExp(r'\s*(İSTANBUL|ISTANBUL|ANKARA|BURSA|İZMİR|IZMIR|MSBILL\.INFO)?\s*(Market|Sağlık / Bakım|Saglik / Bakim|Yeme / İçme|Yeme / Icme|Ev / Dekorasyon|Giyim / Aksesuar|Eğlence / Hobi|Eglence / Hobi|Vergi|Diğer|Diger|Alışveriş|Alısveris|Kurum Ödemesi|Para Transferi|Para Çekme|Para Yatırma|Kart Ödemesi|Kart Odemesi|Faiz / Komisyon|Faiz/Komisyon)\s*$', caseSensitive: false), '')
            .replaceAll(RegExp(r'[()]+'), '')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        if (cleanTitle.isEmpty) cleanTitle = 'Taksitli Harcama';

        final item = InstallmentItem(
          transactionId: tx.id,
          title: cleanTitle,
          monthlyAmount: tx.amount,
          currentInstallment: current,
          totalInstallments: total,
          date: tx.date,
          categoryId: tx.categoryId,
        );

        // Group same installment plan across monthly statements:
        // Match merchant name, total installment count, and amount with ±2 TL tolerance (for bank odd-cent distribution e.g. .34 vs .33)
        final normalizedTitle = cleanTitle.toLowerCase().replaceAll(' ', '');
        String? matchedKey;

        for (final entry in planMap.entries) {
          final existing = entry.value;
          final existingNormalizedTitle = existing.title.toLowerCase().replaceAll(' ', '');
          if (existing.totalInstallments == total &&
              existingNormalizedTitle == normalizedTitle &&
              (existing.monthlyAmount - item.monthlyAmount).abs() <= 2.0) {
            matchedKey = entry.key;
            break;
          }
        }

        if (matchedKey != null) {
          final existing = planMap[matchedKey]!;
          if (item.currentInstallment > existing.currentInstallment ||
              (item.currentInstallment == existing.currentInstallment && item.date.isAfter(existing.date))) {
            planMap[matchedKey] = item;
          }
        } else {
          final newKey = '${normalizedTitle}_${total}_${tx.amount.round()}';
          planMap[newKey] = item;
        }
      }
    }

    final items = planMap.values.toList();

    // Sort active first, ordered by highest remaining debt
    items.sort((a, b) {
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      return b.remainingDebt.compareTo(a.remainingDebt);
    });
    return items;
  }

  /// Calculates total committed installment payments for the upcoming month
  static double calculateNextMonthLiability(List<InstallmentItem> installments) {
    return installments
        .where((item) => !item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.monthlyAmount);
  }

  /// Calculates total future debt remaining across all installments
  static double calculateTotalFutureDebt(List<InstallmentItem> installments) {
    return installments
        .where((item) => !item.isCompleted)
        .fold(0.0, (sum, item) => sum + item.remainingDebt);
  }
}
