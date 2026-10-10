import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/finance_provider.dart';
import 'providers/investment_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Suppress yellow-black zebra stripe overflow warnings across all devices
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const SizedBox.shrink();
  };

  await initializeDateFormatting('tr_TR', null);

  runApp(const KurusuKurusunaApp());
}

class KurusuKurusunaApp extends StatelessWidget {
  const KurusuKurusunaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ThemeProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => FinanceProvider()..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => InvestmentProvider()..init(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Kuruşu Kuruşuna',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
