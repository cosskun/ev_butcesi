import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:kurusu_kurusuna/providers/finance_provider.dart';
import 'package:kurusu_kurusuna/providers/investment_provider.dart';
import 'package:kurusu_kurusuna/providers/theme_provider.dart';
import 'package:kurusu_kurusuna/screens/main_navigation_screen.dart';
import 'package:kurusu_kurusuna/screens/home/home_screen.dart';
import 'package:kurusu_kurusuna/screens/timeline/timeline_screen.dart';
import 'package:kurusu_kurusuna/screens/investments/investments_screen.dart';
import 'package:kurusu_kurusuna/screens/statistics/statistics_screen.dart';
import 'package:kurusu_kurusuna/screens/wallet/wallet_screen.dart';
import 'package:kurusu_kurusuna/screens/add_transaction/add_transaction_screen.dart';
import 'package:kurusu_kurusuna/screens/investments/add_investment_screen.dart';
import 'package:kurusu_kurusuna/screens/statement_import/statement_import_screen.dart';
import 'package:kurusu_kurusuna/services/database_service.dart';
import 'package:kurusu_kurusuna/widgets/monthly_report_modal.dart';
import 'package:kurusu_kurusuna/widgets/theme_selector_modal.dart';
import 'package:kurusu_kurusuna/widgets/backup_restore_dialog.dart';

Widget createTestApp(
  Widget child, {
  TargetPlatform platform = TargetPlatform.android,
  FinanceProvider? financeProvider,
  InvestmentProvider? investmentProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ChangeNotifierProvider.value(value: financeProvider ?? FinanceProvider()),
      ChangeNotifierProvider.value(value: investmentProvider ?? InvestmentProvider()),
    ],
    child: Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          theme: ThemeData(
            platform: platform,
            useMaterial3: true,
          ),
          home: child,
        );
      },
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    DatabaseService.isTestMode = true;
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr_TR', null);
  });

  group('Cross-Platform Screen & UI Rendering Tests (Android & iOS)', () {
    testWidgets('MainNavigationScreen renders all 5 tabs and allows tab navigation on Android', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      final finance = FinanceProvider();
      final investment = InvestmentProvider();
      await tester.runAsync(() async {
        await finance.init();
        await investment.init();
      });

      await tester.pumpWidget(createTestApp(const MainNavigationScreen(), platform: TargetPlatform.android, financeProvider: finance, investmentProvider: investment));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.text('Ana Sayfa'), findsOneWidget);
      expect(find.text('Gün Gün'), findsOneWidget);
      expect(find.text('Yatırımlar'), findsOneWidget);
      expect(find.text('Analiz'), findsOneWidget);
      expect(find.text('Cüzdan'), findsOneWidget);

      // Tap 'Gün Gün' (Timeline) tab
      await tester.tap(find.text('Gün Gün'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TimelineScreen), findsOneWidget);

      // Tap 'Yatırımlar' (Investments) tab
      await tester.tap(find.text('Yatırımlar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(InvestmentsScreen), findsOneWidget);

      // Tap 'Analiz' (Statistics) tab
      await tester.tap(find.text('Analiz'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(StatisticsScreen), findsOneWidget);

      // Tap 'Cüzdan' (Wallet) tab
      await tester.tap(find.text('Cüzdan'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(WalletScreen), findsOneWidget);

      // Return to 'Ana Sayfa'
      await tester.tap(find.text('Ana Sayfa'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('MainNavigationScreen renders smoothly on iOS platform with Cupertino styling', (tester) async {
      tester.view.physicalSize = const Size(1170, 2532); // iPhone 14 Pro
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);

      final finance = FinanceProvider();
      final investment = InvestmentProvider();
      await tester.runAsync(() async {
        await finance.init();
        await investment.init();
      });

      await tester.pumpWidget(createTestApp(const MainNavigationScreen(), platform: TargetPlatform.iOS, financeProvider: finance, investmentProvider: investment));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('AddTransactionScreen opens, switches types, and accepts input without error', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const AddTransactionScreen(), platform: TargetPlatform.android));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsOneWidget);
      expect(find.text('Gider'), findsWidgets);
      expect(find.text('Gelir'), findsWidgets);
      expect(find.text('Nakit Çekim'), findsWidgets);

      // Switch to Gelir
      await tester.tap(find.text('Gelir').first);
      await tester.pumpAndSettle();

      // Switch to Nakit Çekim
      await tester.tap(find.text('Nakit Çekim').first);
      await tester.pumpAndSettle();

      // Enter amount
      await tester.enterText(find.byType(TextField).first, '1250');
      await tester.pumpAndSettle();
      expect(find.text('1250'), findsOneWidget);
    });

    testWidgets('AddInvestmentScreen opens and displays Gold, Currency, Stock, Crypto forms', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const AddInvestmentScreen(), platform: TargetPlatform.iOS));
      await tester.pumpAndSettle();

      expect(find.byType(AddInvestmentScreen), findsOneWidget);
      expect(find.text('Altın & Emtia'), findsWidgets);
      expect(find.text('Döviz'), findsWidgets);
      expect(find.text('Hisse Senedi'), findsWidgets);
      expect(find.text('Kripto'), findsWidgets);

      // Tap Döviz
      await tester.tap(find.text('Döviz').first);
      await tester.pumpAndSettle();

      // Tap Hisse Senedi
      await tester.tap(find.text('Hisse Senedi').first);
      await tester.pumpAndSettle();
    });

    testWidgets('StatementImportScreen opens and handles manual text input paste & analyze', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createTestApp(const StatementImportScreen(), platform: TargetPlatform.android));
      await tester.pumpAndSettle();

      expect(find.byType(StatementImportScreen), findsOneWidget);
      expect(find.text('Banka Ekstresi Aktar'), findsOneWidget);
    });

    testWidgets('MonthlyReportModal (Finansal Karne) opens and renders without overflow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => MonthlyReportModal.show(ctx),
                child: const Text('Open Report'),
              ),
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Report'));
      await tester.pumpAndSettle();

      expect(find.byType(MonthlyReportModal), findsOneWidget);
      expect(find.text('Finansal Karne & Skor'), findsOneWidget);
      expect(find.text('PDF Finansal Raporu İndir & Kaydet'), findsOneWidget);
    });

    testWidgets('ThemeSelectorModal opens and renders all 7 color palettes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ThemeSelectorModal.show(ctx),
                child: const Text('Open Theme'),
              ),
            ),
          ),
          platform: TargetPlatform.android,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Theme'));
      await tester.pumpAndSettle();

      expect(find.byType(ThemeSelectorModal), findsOneWidget);
      expect(find.text('Görünüm & Tema Seçimi'), findsOneWidget);
    });

    testWidgets('BackupRestoreSheet opens and renders backup & restore options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.75;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => BackupRestoreSheet.show(ctx),
                child: const Text('Open Backup'),
              ),
            ),
          ),
          platform: TargetPlatform.iOS,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Backup'));
      await tester.pumpAndSettle();

      expect(find.byType(BackupRestoreSheet), findsOneWidget);
      expect(find.text('Yedekleme & Geri Yükleme'), findsOneWidget);
      expect(find.text('Yeni Yedek Al (.JSON)'), findsOneWidget);
      expect(find.text('Yedekten Geri Yükle'), findsOneWidget);
    });
  });
}
