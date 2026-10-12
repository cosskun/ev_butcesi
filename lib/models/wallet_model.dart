import 'package:flutter/material.dart';

enum WalletType { bank, cash, creditCard }

class WalletModel {
  final String id;
  final String name;
  final WalletType type;
  final double balance;
  final IconData icon;
  final Color color;
  final String? bankName;
  final double? cardLimit;
  final int? cutoffDay;
  final int? dueDay;
  final String? lastFourDigits;

  const WalletModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
    required this.color,
    this.bankName,
    this.cardLimit,
    this.cutoffDay,
    this.dueDay,
    this.lastFourDigits,
  });

  WalletModel copyWith({
    String? id,
    String? name,
    WalletType? type,
    double? balance,
    IconData? icon,
    Color? color,
    String? bankName,
    double? cardLimit,
    int? cutoffDay,
    int? dueDay,
    String? lastFourDigits,
  }) {
    return WalletModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      bankName: bankName ?? this.bankName,
      cardLimit: cardLimit ?? this.cardLimit,
      cutoffDay: cutoffDay ?? this.cutoffDay,
      dueDay: dueDay ?? this.dueDay,
      lastFourDigits: lastFourDigits ?? this.lastFourDigits,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'balance': balance,
      'icon_code': icon.codePoint,
      'color_value': color.toARGB32(),
      'bank_name': bankName,
      'card_limit': cardLimit,
      'cutoff_day': cutoffDay,
      'due_day': dueDay,
      'last_four_digits': lastFourDigits,
    };
  }

  factory WalletModel.fromMap(Map<String, dynamic> map) {
    return WalletModel(
      id: map['id'],
      name: map['name'],
      type: WalletType.values.firstWhere((e) => e.name == map['type'], orElse: () => WalletType.bank),
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon_code'] != null ? IconData(map['icon_code'] as int, fontFamily: 'MaterialIcons') : Icons.account_balance_wallet_rounded,
      color: map['color_value'] != null ? Color(map['color_value'] as int) : const Color(0xFF1976D2),
      bankName: map['bank_name'] as String?,
      cardLimit: (map['card_limit'] as num?)?.toDouble(),
      cutoffDay: map['cutoff_day'] as int?,
      dueDay: map['due_day'] as int?,
      lastFourDigits: map['last_four_digits'] as String?,
    );
  }

  static List<WalletModel> get defaultWallets => [
    const WalletModel(
      id: 'wallet_bank',
      name: 'Ana Banka Hesabı',
      bankName: 'Vadesiz TL',
      type: WalletType.bank,
      balance: 0.0,
      icon: Icons.account_balance_rounded,
      color: Color(0xFF1976D2),
    ),
    const WalletModel(
      id: 'wallet_cash',
      name: 'Nakit Cüzdanı',
      type: WalletType.cash,
      balance: 0.0,
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF43A047),
    ),
    const WalletModel(
      id: 'wallet_credit',
      name: 'Ana Kredi Kartı',
      bankName: 'Kredi Kartı',
      type: WalletType.creditCard,
      balance: 0.0,
      cardLimit: 100000.0,
      icon: Icons.credit_card_rounded,
      color: Color(0xFF8E24AA),
    ),
  ];
}
