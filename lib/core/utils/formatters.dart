import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormat = NumberFormat.currency(
    locale: 'tr_TR',
    symbol: '₺',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalFormat = NumberFormat('#,##0.00', 'tr_TR');

  static String formatNumber(double amount) {
    return _decimalFormat.format(amount);
  }

  static String formatCurrency(double amount, {bool showDecimals = true}) {
    if (!showDecimals || amount % 1 == 0) {
      return _compactCurrencyFormat.format(amount);
    }
    return _currencyFormat.format(amount);
  }

  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Bugün';
    } else if (checkDate == yesterday) {
      return 'Dün';
    } else {
      return DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(date);
    }
  }

  static String formatShortDate(DateTime date) {
    return DateFormat('d MMM yyyy', 'tr_TR').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'tr_TR').format(date);
  }
}
