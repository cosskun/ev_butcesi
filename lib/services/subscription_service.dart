import 'package:flutter/material.dart';
import '../models/transaction_model.dart';

class SubscriptionItem {
  final String id;
  final String name;
  final double monthlyAmount;
  final IconData icon;
  final Color color;
  final DateTime lastBilledDate;
  final int frequencyCount;

  const SubscriptionItem({
    required this.id,
    required this.name,
    required this.monthlyAmount,
    required this.icon,
    required this.color,
    required this.lastBilledDate,
    this.frequencyCount = 1,
  });

  /// Yearly projected cost
  double get yearlyAmount => monthlyAmount * 12;

  /// Estimated next billing date
  DateTime get nextBillingDate {
    final year = lastBilledDate.year + (lastBilledDate.month == 12 ? 1 : 0);
    final month = (lastBilledDate.month % 12) + 1;
    final day = lastBilledDate.day.clamp(1, 28);
    return DateTime(year, month, day);
  }
}

class SubscriptionService {
  static const Map<String, ({IconData icon, Color color, String cleanName})> _knownSubscriptions = {
    'NETFLIX': (icon: Icons.movie_filter_rounded, color: Color(0xFFE50914), cleanName: 'Netflix'),
    'SPOTIFY': (icon: Icons.music_note_rounded, color: Color(0xFF1DB954), cleanName: 'Spotify'),
    'YOUTUBE': (icon: Icons.play_circle_filled_rounded, color: Color(0xFFFF0000), cleanName: 'YouTube Premium'),
    'ICLOUD': (icon: Icons.cloud_circle_rounded, color: Color(0xFF007AFF), cleanName: 'Apple iCloud'),
    'APPLE.COM': (icon: Icons.apple, color: Color(0xFF000000), cleanName: 'Apple Services'),
    'AMAZON PRIME': (icon: Icons.shopping_bag_rounded, color: Color(0xFF00A8E1), cleanName: 'Amazon Prime'),
    'PRIME VIDEO': (icon: Icons.video_library_rounded, color: Color(0xFF00A8E1), cleanName: 'Prime Video'),
    'CHATGPT': (icon: Icons.smart_toy_rounded, color: Color(0xFF10A37F), cleanName: 'ChatGPT Plus'),
    'OPENAI': (icon: Icons.smart_toy_rounded, color: Color(0xFF10A37F), cleanName: 'OpenAI'),
    'DISNEY': (icon: Icons.stars_rounded, color: Color(0xFF113CCF), cleanName: 'Disney+'),
    'BLUTV': (icon: Icons.live_tv_rounded, color: Color(0xFF00AEEF), cleanName: 'BluTV'),
    'EXXEN': (icon: Icons.tv_rounded, color: Color(0xFFFFCC00), cleanName: 'Exxen'),
    'GAIN': (icon: Icons.ondemand_video_rounded, color: Color(0xFFE5097F), cleanName: 'GAİN'),
    'BEIN': (icon: Icons.sports_soccer_rounded, color: Color(0xFF582C83), cleanName: 'beIN Connect'),
    'S SPORT': (icon: Icons.sports_basketball_rounded, color: Color(0xFFE31B23), cleanName: 'S Sport Plus'),
    'STORYTEL': (icon: Icons.auto_stories_rounded, color: Color(0xFFFF5A00), cleanName: 'Storytel'),
    'FITNESS': (icon: Icons.fitness_center_rounded, color: Color(0xFF4A90E2), cleanName: 'Spor Salonu Üyeliği'),
    'GYM': (icon: Icons.fitness_center_rounded, color: Color(0xFF4A90E2), cleanName: 'Spor Salonu'),
    'MACFIT': (icon: Icons.fitness_center_rounded, color: Color(0xFFD0021B), cleanName: 'MACFit'),
    'TURKCELL': (icon: Icons.phone_android_rounded, color: Color(0xFF003087), cleanName: 'Turkcell Fatura'),
    'VODAFONE': (icon: Icons.phone_iphone_rounded, color: Color(0xFFE60000), cleanName: 'Vodafone Fatura'),
    'TURKNET': (icon: Icons.wifi_rounded, color: Color(0xFF00A651), cleanName: 'TurkNet İnternet'),
    'TELEKOM': (icon: Icons.network_cell_rounded, color: Color(0xFF003366), cleanName: 'Türk Telekom'),
  };

  /// Scans user transactions and identifies active subscriptions
  static List<SubscriptionItem> detectSubscriptions(List<TransactionModel> transactions) {
    final Map<String, SubscriptionItem> detected = {};

    for (final tx in transactions) {
      if (tx.type != TransactionType.expense) continue;

      final upper = tx.title.toUpperCase();

      for (final entry in _knownSubscriptions.entries) {
        if (upper.contains(entry.key)) {
          final existing = detected[entry.key];
          if (existing == null || tx.date.isAfter(existing.lastBilledDate)) {
            detected[entry.key] = SubscriptionItem(
              id: tx.id,
              name: entry.value.cleanName,
              monthlyAmount: tx.amount,
              icon: entry.value.icon,
              color: entry.value.color,
              lastBilledDate: tx.date,
              frequencyCount: (existing?.frequencyCount ?? 0) + 1,
            );
          }
          break;
        }
      }
    }

    final list = detected.values.toList();
    list.sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
    return list;
  }

  /// Calculates total monthly subscription spending
  static double calculateMonthlyTotal(List<SubscriptionItem> subscriptions) {
    return subscriptions.fold(0.0, (sum, item) => sum + item.monthlyAmount);
  }

  /// Calculates total yearly subscription projection
  static double calculateYearlyProjection(List<SubscriptionItem> subscriptions) {
    return subscriptions.fold(0.0, (sum, item) => sum + item.yearlyAmount);
  }
}
