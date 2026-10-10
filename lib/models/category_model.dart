import 'package:flutter/material.dart';

enum CategoryType { expense, income, both }

class CategoryModel {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final CategoryType type;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.type = CategoryType.expense,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon_code': icon.codePoint,
      'color_value': color.value,
      'bg_color_value': bgColor.value,
      'type': type.name,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      icon: IconData(map['icon_code'] as int, fontFamily: 'MaterialIcons'),
      color: Color(map['color_value'] as int),
      bgColor: Color(map['bg_color_value'] as int),
      type: CategoryType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => CategoryType.expense,
      ),
    );
  }

  static List<CategoryModel> get defaultExpenseCategories => [
    const CategoryModel(
      id: 'market',
      name: 'Mutfak & Market',
      icon: Icons.shopping_basket_rounded,
      color: Color(0xFFE65100),
      bgColor: Color(0xFFFFE0B2),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'manav',
      name: 'Manav & Meyve/Sebze',
      icon: Icons.eco_rounded,
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFC8E6C9),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'fatura',
      name: 'Faturalar & Aidat',
      icon: Icons.receipt_long_rounded,
      color: Color(0xFF1565C0),
      bgColor: Color(0xFFBBDEFB),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'kira',
      name: 'Kira & Ev Gideri',
      icon: Icons.home_rounded,
      color: Color(0xFF6A1B9A),
      bgColor: Color(0xFFE1BEE7),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'ulasim',
      name: 'Ulaşım & Yakıt',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF00838F),
      bgColor: Color(0xFFB2EBF2),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'saglik',
      name: 'Sağlık & Eczane',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFC2185B),
      bgColor: Color(0xFFF8BBD0),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'eglence',
      name: 'Yeme & İçme / Kafe',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFD84315),
      bgColor: Color(0xFFFFCCBC),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'giyim',
      name: 'Giyim & Alışveriş',
      icon: Icons.checkroom_rounded,
      color: Color(0xFF4527A0),
      bgColor: Color(0xFFD1C4E9),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'egitim',
      name: 'Eğitim & Çocuk',
      icon: Icons.school_rounded,
      color: Color(0xFF00695C),
      bgColor: Color(0xFFB2DFDB),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'kisisel_bakim',
      name: 'Kişisel Bakım & Kozmetik',
      icon: Icons.face_retouching_natural_rounded,
      color: Color(0xFFD81B60),
      bgColor: Color(0xFFFCE4EC),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'alisveris',
      name: 'E-Ticaret & Online',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFFFF6F00),
      bgColor: Color(0xFFFFECB3),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'nakit_cekildi',
      name: 'ATM / Nakit Çekim',
      icon: Icons.local_atm_rounded,
      color: Color(0xFF4E342E),
      bgColor: Color(0xFFD7CCC8),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'birikim',
      name: 'Birikim & Tasarruf (Eminevim)',
      icon: Icons.savings_rounded,
      color: Color(0xFF00897B),
      bgColor: Color(0xFFE0F2F1),
      type: CategoryType.expense,
    ),
    const CategoryModel(
      id: 'diger_gider',
      name: 'Diğer Harcamalar',
      icon: Icons.category_rounded,
      color: Color(0xFF546E7A),
      bgColor: Color(0xFFCFD8DC),
      type: CategoryType.expense,
    ),
  ];

  static List<CategoryModel> get defaultIncomeCategories => [
    const CategoryModel(
      id: 'maas',
      name: 'Maaş Geliri',
      icon: Icons.payments_rounded,
      color: Color(0xFF2E7D32),
      bgColor: Color(0xFFC8E6C9),
      type: CategoryType.income,
    ),
    const CategoryModel(
      id: 'ek_gelir',
      name: 'Ek Gelir & Prim',
      icon: Icons.trending_up_rounded,
      color: Color(0xFF00897B),
      bgColor: Color(0xFFB2DFDB),
      type: CategoryType.income,
    ),
    const CategoryModel(
      id: 'yatirim',
      name: 'Yatırım / Faiz',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF1565C0),
      bgColor: Color(0xFFBBDEFB),
      type: CategoryType.income,
    ),
    const CategoryModel(
      id: 'kira_gelir',
      name: 'Kira Geliri',
      icon: Icons.apartment_rounded,
      color: Color(0xFF6A1B9A),
      bgColor: Color(0xFFE1BEE7),
      type: CategoryType.income,
    ),
    const CategoryModel(
      id: 'harclik_hediye',
      name: 'Hediye / Harçlık',
      icon: Icons.card_giftcard_rounded,
      color: Color(0xFFAD1457),
      bgColor: Color(0xFFF8BBD0),
      type: CategoryType.income,
    ),
    const CategoryModel(
      id: 'diger_gelir',
      name: 'Diğer Gelirler',
      icon: Icons.add_circle_outline_rounded,
      color: Color(0xFF455A64),
      bgColor: Color(0xFFCFD8DC),
      type: CategoryType.income,
    ),
  ];

  static CategoryModel findById(String id) {
    final all = [...defaultExpenseCategories, ...defaultIncomeCategories];
    return all.firstWhere(
      (cat) => cat.id == id,
      orElse: () => const CategoryModel(
        id: 'diger',
        name: 'Genel',
        icon: Icons.receipt_rounded,
        color: Color(0xFF546E7A),
        bgColor: Color(0xFFCFD8DC),
      ),
    );
  }
}
