import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/icons/app_icons.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/screens/transaction/transaction_detail_screen.dart';
import 'package:money_tracker/presentation/widgets/sequential_flow_widgets.dart';
import 'package:money_tracker/presentation/widgets/transaction_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  test(
    'future balance projection uses only future income and expense dates',
    () {
      final projection = FutureTransactionProjection.fromFutureTransactions(
        storedWalletTotal: 1260000,
        today: DateTime(2026, 8, 8),
        transactions: [
          FutureTransactionImpact(
            transactionDate: DateTime(2026, 8, 9),
            type: TransactionType.income,
            amount: 300000,
          ),
          FutureTransactionImpact(
            transactionDate: DateTime(2026, 8, 31),
            type: TransactionType.expense,
            amount: 100000,
          ),
          FutureTransactionImpact(
            transactionDate: DateTime(2026, 9, 2),
            type: TransactionType.income,
            amount: 200000,
          ),
          FutureTransactionImpact(
            transactionDate: DateTime(2026, 8, 8),
            type: TransactionType.expense,
            amount: 900000,
          ),
        ],
      );

      expect(projection.futureTransactionCount, 3);
      expect(projection.futureNet, 400000);
      expect(projection.currentBalance, 860000);
      expect(projection.currentMonthFutureNet, 200000);
      expect(projection.endOfCurrentMonthBalance, 1060000);
    },
  );

  test('net-zero scheduled records still retain their future count', () {
    final projection = FutureTransactionProjection.fromFutureTransactions(
      storedWalletTotal: 500000,
      today: DateTime(2026, 8, 8),
      transactions: [
        FutureTransactionImpact(
          transactionDate: DateTime(2026, 8, 9),
          type: TransactionType.income,
          amount: 100000,
        ),
        FutureTransactionImpact(
          transactionDate: DateTime(2026, 8, 10),
          type: TransactionType.expense,
          amount: 100000,
        ),
      ],
    );

    expect(projection.hasFutureTransactions, isTrue);
    expect(projection.futureTransactionCount, 2);
    expect(projection.futureNet, 0);
    expect(projection.currentBalance, 500000);
    expect(projection.endOfCurrentMonthBalance, 500000);
  });

  testWidgets('future transactions are marked in both list and detail', (
    tester,
  ) async {
    final today = DateTime.now();
    final future = _transaction(
      id: 'future-transaction',
      date: DateTime(today.year, today.month, today.day + 1),
    );
    final past = _transaction(
      id: 'past-transaction',
      date: DateTime(today.year, today.month, today.day - 1),
    );
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getLightTheme(),
        home: Scaffold(
          body: Column(
            children: [
              TransactionTile(transaction: future),
              TransactionTile(transaction: past),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mendatang'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Transaksi dijadwalkan untuk masa depan'),
      findsOneWidget,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          transactionDetailProvider(
            future.transactionId,
          ).overrideWith((ref) => future),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(),
          home: TransactionDetailScreen(transaction: future),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mendatang'), findsOneWidget);
    expect(
      find.bySemanticsLabel('Transaksi dijadwalkan untuk masa depan'),
      findsOneWidget,
    );

    semantics.dispose();
  });

  testWidgets('category picker uses the shared icon mapping at target sizes', (
    tester,
  ) async {
    final category = CategoryEntity(
      categoryId: 'category-donation',
      type: TransactionType.expense,
      categoryName: 'Donasi Keluarga yang Panjang',
      icon: 'donasi',
      color: '#E53935',
    );

    for (final width in [360.0, 393.0, 412.0]) {
      await tester.binding.setSurfaceSize(Size(width, 852));
      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            categoriesProvider('cashbook-1').overrideWith((ref) => [category]),
          ],
          child: MaterialApp(
            theme: AppTheme.getLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(1.3)),
              child: child!,
            ),
            home: const Scaffold(
              body: CategoryPickerSheet(
                cashbookId: 'cashbook-1',
                type: TransactionType.expense,
                selectedId: null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byIcon(AppIcons.forCategory('donasi')), findsOneWidget);
      expect(find.text('Donasi Keluarga yang Panjang'), findsOneWidget);
    }

    await tester.binding.setSurfaceSize(null);
  });
}

TransactionEntity _transaction({required String id, required DateTime date}) {
  return TransactionEntity(
    transactionId: id,
    cashbookId: 'cashbook-1',
    walletId: 'wallet-1',
    categoryId: 'category-1',
    type: TransactionType.expense,
    amount: 125000,
    name: 'Belanja kebutuhan',
    transactionDate: date,
    createdAt: date,
    walletName: 'Dompet Utama',
    categoryName: 'Belanja',
    categoryIcon: 'belanja',
  );
}
