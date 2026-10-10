enum TransactionType {
  expense,        // Normal gider (örn: 1000 TL muz)
  income,         // Gelir (örn: Maaş)
  cashWithdrawal, // ATM'den nakit çekme (Banka -> Nakit transferi)
}

enum PaymentMethod {
  bankCard,
  cash,
  creditCard,
}

extension PaymentMethodExtension on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.bankCard:
        return 'Banka Kartı';
      case PaymentMethod.cash:
        return 'Nakit';
      case PaymentMethod.creditCard:
        return 'Kredi Kartı';
    }
  }
}

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String categoryId;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? imagePath;
  final String? note;
  final String? sourceWalletId;
  final String? targetWalletId;

  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.date,
    this.paymentMethod = PaymentMethod.cash,
    this.imagePath,
    this.note,
    this.sourceWalletId,
    this.targetWalletId,
  });

  TransactionModel copyWith({
    String? id,
    String? title,
    double? amount,
    TransactionType? type,
    String? categoryId,
    DateTime? date,
    PaymentMethod? paymentMethod,
    String? imagePath,
    String? note,
    String? sourceWalletId,
    String? targetWalletId,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      imagePath: imagePath ?? this.imagePath,
      note: note ?? this.note,
      sourceWalletId: sourceWalletId ?? this.sourceWalletId,
      targetWalletId: targetWalletId ?? this.targetWalletId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type.name,
      'category_id': categoryId,
      'date': date.toIso8601String(),
      'payment_method': paymentMethod.name,
      'image_path': imagePath,
      'note': note,
      'source_wallet_id': sourceWalletId,
      'target_wallet_id': targetWalletId,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      title: map['title'],
      amount: (map['amount'] as num).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      categoryId: map['category_id'] ?? 'diger',
      date: DateTime.parse(map['date']),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == map['payment_method'],
        orElse: () => PaymentMethod.cash,
      ),
      imagePath: map['image_path'],
      note: map['note'],
      sourceWalletId: map['source_wallet_id'],
      targetWalletId: map['target_wallet_id'],
    );
  }

  String get signature {
    final d = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final cleanTitle = title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9ğüşıöç]'), '');
    final amt = amount.toStringAsFixed(2);
    return '$d|$amt|${type.name}|$cleanTitle';
  }
}
