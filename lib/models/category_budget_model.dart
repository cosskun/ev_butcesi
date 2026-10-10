import 'package:flutter/material.dart';

enum BudgetStatus {
  safe,
  warning,
  exceeded,
}

class CategoryBudgetModel {
  final String categoryId;
  final double monthlyLimit;

  const CategoryBudgetModel({
    required this.categoryId,
    required this.monthlyLimit,
  });

  double getProgress(double spent) {
    if (monthlyLimit <= 0) return 0.0;
    return (spent / monthlyLimit).clamp(0.0, 2.0);
  }

  double getRemaining(double spent) {
    return monthlyLimit - spent;
  }

  BudgetStatus getStatus(double spent) {
    if (monthlyLimit <= 0) return BudgetStatus.safe;
    final ratio = spent / monthlyLimit;
    if (ratio >= 1.0) return BudgetStatus.exceeded;
    if (ratio >= 0.75) return BudgetStatus.warning;
    return BudgetStatus.safe;
  }

  Color getStatusColor(double spent) {
    switch (getStatus(spent)) {
      case BudgetStatus.safe:
        return const Color(0xFF10B981); // Green
      case BudgetStatus.warning:
        return const Color(0xFFF59E0B); // Amber / Yellow
      case BudgetStatus.exceeded:
        return const Color(0xFFEF4444); // Red
    }
  }

  Map<String, dynamic> toMap() => {
        'category_id': categoryId,
        'monthly_limit': monthlyLimit,
      };

  factory CategoryBudgetModel.fromMap(Map<String, dynamic> map) {
    return CategoryBudgetModel(
      categoryId: map['category_id'] as String,
      monthlyLimit: (map['monthly_limit'] as num).toDouble(),
    );
  }
}
