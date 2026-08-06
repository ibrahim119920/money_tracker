import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:money_tracker/app/router.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:money_tracker/presentation/screens/report/monthly_report_screen.dart';
import 'package:money_tracker/presentation/screens/settings/settings_screen.dart';
import 'package:money_tracker/presentation/screens/transaction/transaction_list_screen.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
    'bottom navigation changes tabs in place and keeps the navigation bar',
    (tester) async {
      await tester.pumpWidget(_dashboardApp());
      await tester.pumpAndSettle();

      final navigationBar = find.byType(NavigationBar);
      expect(navigationBar, findsOneWidget);
      expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);

      final destinations = <({String label, Type screenType, int index})>[
        (label: 'Transaksi', screenType: TransactionListScreen, index: 1),
        (label: 'Laporan', screenType: MonthlyReportScreen, index: 2),
        (label: 'Pengaturan', screenType: SettingsScreen, index: 3),
      ];

      for (final destination in destinations) {
        await tester.tap(
          find.descendant(
            of: navigationBar,
            matching: find.text(destination.label),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(destination.screenType), findsOneWidget);
        expect(find.text('Total Saldo'), findsNothing);
        expect(
          tester.widget<NavigationBar>(navigationBar).selectedIndex,
          destination.index,
        );
      }

      await tester.tap(
        find.descendant(of: navigationBar, matching: find.text('Dashboard')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Saldo'), findsOneWidget);
      expect(tester.widget<NavigationBar>(navigationBar).selectedIndex, 0);
      expect(tester.takeException(), isNull);
    },
  );

  test('legacy protected deep-link route names remain registered', () {
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith((ref) => Stream.empty())],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);

    expect(router.namedLocation('transactions'), AppRoutes.transactions);
    expect(router.namedLocation('monthlyReport'), AppRoutes.monthlyReport);
    expect(router.namedLocation('settings'), AppRoutes.settings);
  });

  testWidgets('legacy screen defaults still render standalone scaffolds', (
    tester,
  ) async {
    for (final screen in const [
      TransactionListScreen(),
      MonthlyReportScreen(),
      SettingsScreen(),
    ]) {
      await tester.pumpWidget(_testApp(home: screen));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

Widget _dashboardApp() => _testApp(home: const DashboardScreen());

Widget _testApp({required Widget home}) {
  final now = DateTime(2026, 8, 6);
  final cashbook = CashbookEntity(
    cashbookId: 'cashbook-1',
    userId: 'user-1',
    cashbookName: 'Buku Kas Keluarga',
    isDefault: true,
    createdAt: now,
  );
  final wallet = WalletEntity(
    walletId: 'wallet-1',
    cashbookId: cashbook.cashbookId,
    type: WalletType.cash,
    walletName: 'Uang Tunai',
    initialBalance: 100000,
    currentBalance: 100000,
    createdAt: now,
  );

  return ProviderScope(
    overrides: [
      currentUserProvider.overrideWith((ref) => null),
      activeCashbookProvider.overrideWith((ref) => null),
      cashbooksProvider.overrideWith((ref) => [cashbook]),
      defaultCashbookProvider.overrideWith((ref) => null),
      walletsProvider.overrideWith((ref) => [wallet]),
      totalBalanceProvider.overrideWith((ref) => 0),
      selectedMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
      monthlySummaryProvider.overrideWith((ref) => {'income': 0, 'expense': 0}),
      transactionListItemsProvider.overrideWith(
        (ref) => AsyncData(<TransactionListItem>[]),
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      home: home,
    ),
  );
}
