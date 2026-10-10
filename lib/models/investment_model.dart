import 'package:flutter/material.dart';

enum InvestmentType {
  stock,       // Hisse Senedi (BIST / Yabancı)
  gold,        // Altın & Kıymetli Madenler (Gram, Çeyrek, vb.)
  currency,    // Döviz (Dolar, Euro, vb.)
  fund,        // Yatırım Fonu / BES
  crypto,      // Kripto Varlıklar
  other,       // Diğer Varlıklar
}

extension InvestmentTypeExtension on InvestmentType {
  String get displayName {
    switch (this) {
      case InvestmentType.stock:
        return 'Hisse Senedi';
      case InvestmentType.gold:
        return 'Altın & Emtia';
      case InvestmentType.currency:
        return 'Döviz';
      case InvestmentType.fund:
        return 'Fon / BES';
      case InvestmentType.crypto:
        return 'Kripto';
      case InvestmentType.other:
        return 'Diğer';
    }
  }

  IconData get icon {
    switch (this) {
      case InvestmentType.stock:
        return Icons.show_chart_rounded;
      case InvestmentType.gold:
        return Icons.workspace_premium_rounded;
      case InvestmentType.currency:
        return Icons.currency_exchange_rounded;
      case InvestmentType.fund:
        return Icons.account_balance_wallet_rounded;
      case InvestmentType.crypto:
        return Icons.currency_bitcoin_rounded;
      case InvestmentType.other:
        return Icons.pie_chart_outline_rounded;
    }
  }

  Color get color {
    switch (this) {
      case InvestmentType.stock:
        return const Color(0xFF1976D2);
      case InvestmentType.gold:
        return const Color(0xFFD4AF37); // Gold
      case InvestmentType.currency:
        return const Color(0xFF2E7D32);
      case InvestmentType.fund:
        return const Color(0xFF7B1FA2);
      case InvestmentType.crypto:
        return const Color(0xFFF57C00);
      case InvestmentType.other:
        return const Color(0xFF546E7A);
    }
  }

  Color get bgColor {
    switch (this) {
      case InvestmentType.stock:
        return const Color(0xFFE3F2FD);
      case InvestmentType.gold:
        return const Color(0xFFFFF9E6);
      case InvestmentType.currency:
        return const Color(0xFFE8F5E9);
      case InvestmentType.fund:
        return const Color(0xFFF3E5F5);
      case InvestmentType.crypto:
        return const Color(0xFFFFF3E0);
      case InvestmentType.other:
        return const Color(0xFFECEFF1);
    }
  }

  String get unitLabel {
    switch (this) {
      case InvestmentType.stock:
        return 'Lot / Adet';
      case InvestmentType.gold:
        return 'Gram / Adet';
      case InvestmentType.currency:
        return 'Miktar';
      case InvestmentType.fund:
        return 'Pay Adedi';
      case InvestmentType.crypto:
        return 'Adet';
      case InvestmentType.other:
        return 'Birim';
    }
  }
}

class InvestmentModel {
  final String id;
  final String title;               // örn: "THYAO", "Gram Altın", "Amerikan Doları"
  final String symbol;              // örn: "THYAO", "GAU/TRY", "USD/TRY"
  final InvestmentType type;
  final double quantity;            // örn: 100 lot, 25.5 gram
  final double buyUnitPrice;        // Alış birim fiyatı
  final double currentUnitPrice;    // Güncel birim fiyatı
  final DateTime buyDate;
  final String? note;
  final String? sourceWalletId;

  const InvestmentModel({
    required this.id,
    required this.title,
    required this.symbol,
    required this.type,
    required this.quantity,
    required this.buyUnitPrice,
    required this.currentUnitPrice,
    required this.buyDate,
    this.note,
    this.sourceWalletId,
  });

  double get totalCost => quantity * buyUnitPrice;
  double get totalCurrentValue => quantity * currentUnitPrice;
  double get profitLoss => totalCurrentValue - totalCost;
  double get profitLossPercent => totalCost > 0 ? (profitLoss / totalCost) * 100 : 0.0;
  bool get isProfitable => profitLoss >= 0;

  InvestmentModel copyWith({
    String? id,
    String? title,
    String? symbol,
    InvestmentType? type,
    double? quantity,
    double? buyUnitPrice,
    double? currentUnitPrice,
    DateTime? buyDate,
    String? note,
    String? sourceWalletId,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      title: title ?? this.title,
      symbol: symbol ?? this.symbol,
      type: type ?? this.type,
      quantity: quantity ?? this.quantity,
      buyUnitPrice: buyUnitPrice ?? this.buyUnitPrice,
      currentUnitPrice: currentUnitPrice ?? this.currentUnitPrice,
      buyDate: buyDate ?? this.buyDate,
      note: note ?? this.note,
      sourceWalletId: sourceWalletId ?? this.sourceWalletId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'symbol': symbol,
      'type': type.name,
      'quantity': quantity,
      'buy_unit_price': buyUnitPrice,
      'current_unit_price': currentUnitPrice,
      'buy_date': buyDate.toIso8601String(),
      'note': note,
      'source_wallet_id': sourceWalletId,
    };
  }

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'],
      title: map['title'],
      symbol: map['symbol'] ?? map['title'],
      type: InvestmentType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => InvestmentType.stock,
      ),
      quantity: (map['quantity'] as num).toDouble(),
      buyUnitPrice: (map['buy_unit_price'] as num).toDouble(),
      currentUnitPrice: (map['current_unit_price'] as num).toDouble(),
      buyDate: DateTime.parse(map['buy_date']),
      note: map['note'],
      sourceWalletId: map['source_wallet_id'],
    );
  }
}
