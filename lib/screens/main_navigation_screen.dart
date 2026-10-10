import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/investment_provider.dart';
import 'home/home_screen.dart';
import 'timeline/timeline_screen.dart';
import 'investments/investments_screen.dart';
import 'investments/add_investment_screen.dart';
import 'statistics/statistics_screen.dart';
import 'wallet/wallet_screen.dart';
import 'add_transaction/add_transaction_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (index == 2) {
      // Auto-refresh investment prices whenever user enters the Investments tab
      context.read<InvestmentProvider>().refreshAllPrices();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final List<Widget> screens = [
      HomeScreen(onNavigateTab: _onTabTapped),
      const TimelineScreen(),
      const InvestmentsScreen(),
      const StatisticsScreen(),
      const WalletScreen(),
    ];

    final isInvestmentTab = _currentIndex == 2;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: FloatingActionButton(
        elevation: 4,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        tooltip: isInvestmentTab ? 'Yeni Yatırım & Varlık Ekle' : 'Yeni İşlem Ekle',
        child: const Icon(Icons.add_rounded, size: 28),
        onPressed: () {
          if (isInvestmentTab) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddInvestmentScreen(),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AddTransactionScreen(),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: 'Ana Sayfa',
                  primaryColor: primaryColor,
                ),
                _buildNavItem(
                  index: 1,
                  icon: Icons.calendar_today_rounded,
                  label: 'Gün Gün',
                  primaryColor: primaryColor,
                ),
                _buildNavItem(
                  index: 2,
                  icon: Icons.trending_up_rounded,
                  label: 'Yatırımlar',
                  primaryColor: primaryColor,
                ),
                _buildNavItem(
                  index: 3,
                  icon: Icons.pie_chart_rounded,
                  label: 'Analiz',
                  primaryColor: primaryColor,
                ),
                _buildNavItem(
                  index: 4,
                  icon: Icons.account_balance_wallet_rounded,
                  label: 'Cüzdan',
                  primaryColor: primaryColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required Color primaryColor,
  }) {
    final isSelected = _currentIndex == index;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final unselectedColor = isDark ? const Color(0xFF718096) : const Color(0xFFA0AEC0);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : unselectedColor,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? primaryColor : unselectedColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
