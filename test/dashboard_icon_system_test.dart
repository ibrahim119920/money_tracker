import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/core/constants/app_design_tokens.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/icons/app_icons.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/screens/dashboard/dashboard_screen.dart';

const _dashboardCaptureKey = ValueKey<String>('dashboard-capture');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    await _loadMaterialIconsFont();
  });

  testWidgets('Dashboard icon system remains stable in light and dark themes', (
    tester,
  ) async {
    for (final brightness in Brightness.values) {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(_dashboardApp(brightness: brightness));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(AppIcons.dashboardSelected), findsOneWidget);
      expect(find.byIcon(AppIcons.transactions), findsOneWidget);
      expect(find.byIcon(AppIcons.reports), findsOneWidget);
      expect(find.byIcon(AppIcons.settings), findsOneWidget);
      expect(find.byIcon(AppIcons.cashWallet), findsOneWidget);
      expect(find.byIcon(AppIcons.bankWallet), findsOneWidget);
      // The third wallet is intentionally lazy and starts off-screen in the
      // horizontal carousel. Its mapping is covered by app_icons_test.dart.
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'Dashboard remains layout-safe at target widths and text scales',
    (tester) async {
      for (final width in [360.0, 393.0, 412.0]) {
        for (final textScale in [1.0, 1.3]) {
          await tester.binding.setSurfaceSize(Size(width, 852));
          await tester.pumpWidget(
            _dashboardApp(brightness: Brightness.light, textScale: textScale),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Cashbook switcher exposes tooltip, semantics, and pressed state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(_dashboardApp(brightness: Brightness.light));
      await tester.pumpAndSettle();

      expect(find.byTooltip('Pilih buku kas'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Pilih buku kas. Saat ini Buku Kas Keluarga'),
        findsOneWidget,
      );
      expect(find.byType(InkWell), findsWidgets);

      semantics.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('Transaction actions use direct icons without tonal containers', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    await tester.pumpWidget(_dashboardApp(brightness: Brightness.light));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Transaksi Baru'));
    await tester.pumpAndSettle();

    expect(find.byIcon(AppIcons.income), findsOneWidget);
    expect(find.byIcon(AppIcons.expense), findsOneWidget);
    expect(find.byIcon(AppIcons.transfer), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(CircleAvatar),
      ),
      findsNothing,
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('Dashboard screenshots cover light and dark icon treatments', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));

    await tester.pumpWidget(_dashboardApp(brightness: Brightness.light));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard_icons_light.png'),
    );

    await tester.pumpWidget(_dashboardApp(brightness: Brightness.dark));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(DashboardScreen),
      matchesGoldenFile('goldens/dashboard_icons_dark.png'),
    );

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'Dashboard transaction sheet screenshots cover direct action glyphs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_dashboardApp(brightness: brightness));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Transaksi Baru'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(
          find.byWidgetPredicate(
            (widget) => widget.runtimeType.toString() == '_DragHandle',
            description: 'global bottom sheet drag handle',
          ),
          findsOneWidget,
        );
        expect(find.byIcon(AppIcons.income), findsOneWidget);
        expect(find.byIcon(AppIcons.expense), findsOneWidget);
        expect(find.byIcon(AppIcons.transfer), findsOneWidget);
        expect(
          tester.widget<Icon>(find.byIcon(AppIcons.income)).size,
          AppIconSize.regular,
        );
        expect(
          tester.widget<Icon>(find.byIcon(AppIcons.expense)).size,
          AppIconSize.regular,
        );
        expect(
          tester.widget<Icon>(find.byIcon(AppIcons.transfer)).size,
          AppIconSize.regular,
        );
        await expectLater(
          find.byKey(_dashboardCaptureKey),
          matchesGoldenFile(
            'goldens/dashboard_transaction_sheet_${brightness.name}.png',
          ),
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      }

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Dashboard cashbook picker screenshots cover selected and manage glyphs',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(_dashboardApp(brightness: brightness));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Pilih buku kas'));
        await tester.pumpAndSettle();

        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.byIcon(AppIcons.selected), findsOneWidget);
        expect(find.byIcon(AppIcons.manageCashbooks), findsOneWidget);
        await expectLater(
          find.byKey(_dashboardCaptureKey),
          matchesGoldenFile(
            'goldens/dashboard_cashbook_picker_${brightness.name}.png',
          ),
        );
        Navigator.of(tester.element(find.byType(BottomSheet))).pop();
        await tester.pumpAndSettle();
      }

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Dashboard empty onboarding screenshots cover cashbook and wallet fallback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 1000));

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _dashboardApp(brightness: brightness, emptyOnboarding: true),
        );
        await tester.pumpAndSettle();

        expect(find.byIcon(AppIcons.cashbook), findsOneWidget);
        expect(find.byIcon(AppIcons.walletFallback), findsOneWidget);
        expect(
          tester.widget<Icon>(find.byIcon(AppIcons.cashbook)).size,
          AppIconSize.hero,
        );
        expect(
          tester.widget<Icon>(find.byIcon(AppIcons.walletFallback)).size,
          AppIconSize.object,
        );
        await expectLater(
          find.byKey(_dashboardCaptureKey),
          matchesGoldenFile(
            'goldens/dashboard_empty_onboarding_${brightness.name}.png',
          ),
        );
      }

      await tester.binding.setSurfaceSize(null);
    },
  );
}

Future<void> _loadMaterialIconsFont() async {
  final fontPath = _materialIconsFontPath();
  if (fontPath == null) {
    throw StateError(
      'Material Icons font was not found. Set FLUTTER_ROOT or run with a '
      'Flutter SDK that contains materialicons-regular.otf.',
    );
  }

  final bytes = await File(fontPath).readAsBytes();
  await (FontLoader(
    'MaterialIcons',
  )..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)))).load();
}

String? _materialIconsFontPath() {
  final roots = <String>[];
  final environmentRoot = Platform.environment['FLUTTER_ROOT'];
  if (environmentRoot != null && environmentRoot.isNotEmpty) {
    roots.add(environmentRoot);
  }

  var executableDirectory = File(Platform.resolvedExecutable).parent;
  for (var index = 0; index < 4; index++) {
    executableDirectory = executableDirectory.parent;
  }
  roots.add(executableDirectory.path);

  for (final root in roots) {
    final candidate = [
      root,
      'bin',
      'cache',
      'artifacts',
      'material_fonts',
      'materialicons-regular.otf',
    ].join(Platform.pathSeparator);
    if (File(candidate).existsSync()) {
      return candidate;
    }
  }
  return null;
}

Widget _dashboardApp({
  required Brightness brightness,
  double textScale = 1,
  bool emptyOnboarding = false,
}) {
  final now = DateTime(2026, 8, 3);
  final cashbook = CashbookEntity(
    cashbookId: 'cashbook-1',
    userId: 'user-1',
    cashbookName: 'Buku Kas Keluarga',
    isDefault: true,
    createdAt: now,
  );
  final populatedWallets = [
    WalletEntity(
      walletId: 'wallet-cash',
      cashbookId: cashbook.cashbookId,
      type: WalletType.cash,
      walletName: 'Uang Tunai Harian',
      initialBalance: 1250000,
      currentBalance: 1250000,
      createdAt: now,
    ),
    WalletEntity(
      walletId: 'wallet-bank',
      cashbookId: cashbook.cashbookId,
      type: WalletType.bankAcc,
      walletName: 'Rekening Tabungan Keluarga Utama',
      initialBalance: 3500000,
      currentBalance: 3500000,
      createdAt: now,
    ),
    WalletEntity(
      walletId: 'wallet-digital',
      cashbookId: cashbook.cashbookId,
      type: WalletType.eWallet,
      walletName: 'Dompet Digital',
      initialBalance: 800000,
      currentBalance: 800000,
      createdAt: now,
    ),
  ];

  final cashbooks = emptyOnboarding ? <CashbookEntity>[] : [cashbook];
  final activeCashbook = emptyOnboarding ? null : cashbook;
  final wallets = emptyOnboarding ? <WalletEntity>[] : populatedWallets;

  return RepaintBoundary(
    key: _dashboardCaptureKey,
    child: ProviderScope(
      overrides: [
        currentUserProvider.overrideWith((ref) => null),
        activeCashbookProvider.overrideWith((ref) => activeCashbook),
        cashbooksProvider.overrideWith((ref) => cashbooks),
        defaultCashbookProvider.overrideWith((ref) => activeCashbook),
        walletsProvider.overrideWith((ref) => wallets),
        totalBalanceProvider.overrideWith(
          (ref) => emptyOnboarding ? 0 : 5550000,
        ),
        selectedMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
        monthlySummaryProvider.overrideWith(
          (ref) => emptyOnboarding
              ? {'income': 0, 'expense': 0}
              : {'income': 7500000, 'expense': 1950000},
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.getLightTheme(),
        darkTheme: AppTheme.getDarkTheme(),
        themeMode: brightness == Brightness.light
            ? ThemeMode.light
            : ThemeMode.dark,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: const DashboardScreen(),
      ),
    ),
  );
}
