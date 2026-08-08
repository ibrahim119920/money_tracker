import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/screens/transaction/transaction_add_flow_screen.dart';
import 'package:money_tracker/presentation/screens/transfer/transfer_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    await _loadMaterialIconsFont();
  });

  testWidgets(
    'sequential add flow initial screens are stable in light and dark themes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));

      for (final brightness in Brightness.values) {
        await tester.pumpWidget(
          _transactionApp(type: TransactionType.income, brightness: brightness),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(TransactionAddFlowScreen),
          matchesGoldenFile('goldens/sequential_income_${brightness.name}.png'),
        );

        await tester.pumpWidget(
          _transactionApp(
            type: TransactionType.expense,
            brightness: brightness,
          ),
        );
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(TransactionAddFlowScreen),
          matchesGoldenFile(
            'goldens/sequential_expense_${brightness.name}.png',
          ),
        );

        await tester.pumpWidget(_transferApp(brightness: brightness));
        await tester.pumpAndSettle();
        await expectLater(
          find.byType(TransferScreen),
          matchesGoldenFile(
            'goldens/sequential_transfer_${brightness.name}.png',
          ),
        );
      }

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'sequential add flow stays overflow-safe at Android widths and themes',
    (tester) async {
      for (final width in [360.0, 393.0, 412.0]) {
        for (final brightness in Brightness.values) {
          await tester.binding.setSurfaceSize(Size(width, 852));
          await tester.pumpWidget(
            _transactionApp(
              type: TransactionType.income,
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(
            _transactionApp(
              type: TransactionType.expense,
              brightness: brightness,
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          await tester.pumpWidget(_transferApp(brightness: brightness));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );
}

Widget _transactionApp({
  required TransactionType type,
  required Brightness brightness,
}) {
  final cashbook = CashbookEntity(
    cashbookId: 'cashbook-1',
    userId: 'user-1',
    cashbookName: 'Buku Kas',
    createdAt: DateTime(2026, 8, 1),
  );
  final category = CategoryEntity(
    categoryId: 'category-1',
    type: type,
    categoryName: type == TransactionType.income ? 'Gaji' : 'Makanan',
    icon: type == TransactionType.income ? 'gaji' : 'makanan',
    color: '#2F7D59',
  );
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      activeCashbookProvider.overrideWith((ref) => cashbook),
      categoriesProvider(cashbook.cashbookId).overrideWith((ref) => [category]),
      walletsProvider.overrideWith(
        (ref) => [
          WalletEntity(
            walletId: 'wallet-a',
            cashbookId: cashbook.cashbookId,
            type: WalletType.cash,
            walletName: 'Uang Tunai Harian',
            initialBalance: 1250000,
            currentBalance: 1250000,
            createdAt: DateTime(2026, 8, 1),
          ),
        ],
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: TransactionAddFlowScreen(type: type),
    ),
  );
}

Widget _transferApp({required Brightness brightness}) {
  final cashbook = CashbookEntity(
    cashbookId: 'cashbook-1',
    userId: 'user-1',
    cashbookName: 'Buku Kas',
    createdAt: DateTime(2026, 8, 1),
  );
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      activeCashbookProvider.overrideWith((ref) => cashbook),
      walletsProvider.overrideWith(
        (ref) => [
          WalletEntity(
            walletId: 'wallet-a',
            cashbookId: cashbook.cashbookId,
            type: WalletType.cash,
            walletName: 'Uang Tunai Harian',
            initialBalance: 1250000,
            currentBalance: 1250000,
            createdAt: DateTime(2026, 8, 1),
          ),
          WalletEntity(
            walletId: 'wallet-b',
            cashbookId: cashbook.cashbookId,
            type: WalletType.bankAcc,
            walletName: 'Rekening Tabungan Utama',
            initialBalance: 3500000,
            currentBalance: 3500000,
            createdAt: DateTime(2026, 8, 1),
          ),
        ],
      ),
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const TransferScreen(),
    ),
  );
}

Future<void> _loadMaterialIconsFont() async {
  final fontPath = _materialIconsFontPath();
  if (fontPath == null) return;
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
    if (File(candidate).existsSync()) return candidate;
  }
  return null;
}
