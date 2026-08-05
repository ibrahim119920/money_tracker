import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/app/router.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/core/utils/validators.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/icons/app_icons.dart';
import 'package:money_tracker/presentation/screens/transaction/transaction_add_flow_screen.dart';
import 'package:money_tracker/presentation/screens/transaction/transaction_form_screen.dart';
import 'package:money_tracker/presentation/screens/transfer/transfer_screen.dart';
import 'package:money_tracker/presentation/state/sequential_add_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('money input and typed drafts', () {
    test('notes validation is optional through exactly 500 characters', () {
      expect(Validators.validateNotes(null), isNull);
      expect(Validators.validateNotes(''), isNull);
      expect(Validators.validateNotes('x' * 500), isNull);
      expect(
        Validators.validateNotes('x' * 501),
        'Catatan maksimal 500 karakter',
      );
    });

    test('normalizes leading zeros and one-digit backspace to zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(transactionDraftProvider, (_, _) {});
      addTearDown(keepAlive.close);
      final controller = container.read(transactionDraftProvider.notifier);

      expect(container.read(transactionDraftProvider).amount, 0);
      controller.appendDigit(0);
      controller.appendDigit(0);
      controller.appendDigit(7);
      expect(container.read(transactionDraftProvider).amount, 7);
      controller.deleteDigit();
      expect(container.read(transactionDraftProvider).amount, 0);

      controller.appendDigit(0);
      controller.appendDigit(0);
      expect(container.read(transactionDraftProvider).amount, 0);
    });

    test('rejects an amount that would overflow PostgreSQL BIGINT', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(transactionDraftProvider, (_, _) {});
      addTearDown(keepAlive.close);
      final controller = container.read(transactionDraftProvider.notifier);

      controller.setAmount(9223372036854775807);
      expect(controller.appendDigit(9), isFalse);
      expect(
        container.read(transactionDraftProvider).amount,
        9223372036854775807,
      );
    });

    test(
      'transaction draft preserves every field and becomes submit-ready',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final keepAlive = container.listen(transactionDraftProvider, (_, _) {});
        addTearDown(keepAlive.close);
        final controller = container.read(transactionDraftProvider.notifier);
        final yesterday = DateTime.now().subtract(const Duration(days: 1));

        controller.setAmount(125000);
        controller.setCategory('category-1');
        controller.setWallet('wallet-1');
        controller.setDate(yesterday);
        controller.setNotes('Catatan singkat');

        final draft = container.read(transactionDraftProvider);
        expect(draft.amount, 125000);
        expect(draft.categoryId, 'category-1');
        expect(draft.walletId, 'wallet-1');
        expect(draft.notes, 'Catatan singkat');
        expect(draft.canSubmit, isTrue);
      },
    );

    test(
      'transfer draft clears conflicting destination when source changes',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);
        final keepAlive = container.listen(transferDraftProvider, (_, _) {});
        addTearDown(keepAlive.close);
        final controller = container.read(transferDraftProvider.notifier);

        controller.setAmount(50000);
        controller.setSourceWallet('wallet-a');
        controller.setDestinationWallet('wallet-b');
        expect(
          container.read(transferDraftProvider).destinationWalletId,
          'wallet-b',
        );

        controller.setSourceWallet('wallet-b');
        expect(
          container.read(transferDraftProvider).sourceWalletId,
          'wallet-b',
        );
        expect(
          container.read(transferDraftProvider).destinationWalletId,
          isNull,
        );
        controller.setDestinationWallet('wallet-b');
        expect(
          container.read(transferDraftProvider).destinationWalletId,
          isNull,
        );
      },
    );
  });

  group('transfer selection rules and routing', () {
    test('destination excludes source and fewer-than-two is explicit', () {
      final wallets = _wallets();
      expect(hasTransferWalletPair(wallets), isTrue);
      expect(hasTransferWalletPair(wallets.take(1).toList()), isFalse);
      expect(
        transferDestinationOptions(
          wallets,
          'wallet-a',
        ).map((wallet) => wallet.walletId),
        containsAll(<String>['wallet-b', 'wallet-c']),
      );
      expect(
        transferDestinationOptions(
          wallets,
          'wallet-a',
        ).map((wallet) => wallet.walletId),
        isNot(contains('wallet-a')),
      );
      expect(isTransferSourceSufficient(wallets.first, 100001), isFalse);
      expect(isTransferSourceSufficient(wallets.first, 100000), isTrue);
    });

    test('add and compatibility routes are explicit and validated', () {
      expect(AppRoutes.addIncomeTransaction, '/transactions/add/income');
      expect(AppRoutes.addExpenseTransaction, '/transactions/add/expense');
      expect(AppRoutes.transactionForm, '/transactions/form');
      expect(AppRoutes.transfer, '/transfer');
      expect(AppRoutes.transferHistory, '/transfer/history');
    });

    testWidgets('invalid edit extras render a safe route fallback', (
      tester,
    ) async {
      final authState = AuthState(
        AuthChangeEvent.initialSession,
        Session(
          accessToken: 'test-token',
          tokenType: 'bearer',
          user: User(
            id: 'user-1',
            appMetadata: const {},
            userMetadata: null,
            aud: 'authenticated',
            createdAt: DateTime(2026, 8, 1).toIso8601String(),
          ),
        ),
      );
      GoRouter? router;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith((ref) => Stream.value(authState)),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              router ??= ref.watch(goRouterProvider);
              return MaterialApp.router(routerConfig: router!);
            },
          ),
        ),
      );
      await tester.pump();
      router!.go(
        AppRoutes.transactionForm,
        extra: <String, Object?>{'type': 'not-a-transaction-type'},
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Form transaksi membutuhkan data edit yang valid.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'existing edit notes field uses the shared 500-character contract',
      (tester) async {
        final cashbook = _cashbook();
        final wallet = _wallet('wallet-a', 'Dompet Utama', 500000);
        final transaction = TransactionEntity(
          transactionId: 'transaction-1',
          cashbookId: cashbook.cashbookId,
          walletId: wallet.walletId,
          categoryId: 'category-income',
          type: TransactionType.income,
          amount: 125000,
          notes: 'Catatan lama',
          transactionDate: DateTime(2026, 8, 1),
          createdAt: DateTime(2026, 8, 1),
          categoryName: 'Gaji',
          categoryIcon: 'gaji',
        );

        await tester.binding.setSurfaceSize(const Size(393, 852));
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              activeCashbookProvider.overrideWith((ref) => cashbook),
              walletsProvider.overrideWith((ref) => [wallet]),
            ],
            child: MaterialApp(
              theme: AppTheme.getLightTheme(),
              home: TransactionFormScreen(
                type: TransactionType.income,
                transaction: transaction,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final notesField = tester.widget<TextFormField>(
          find.byType(TextFormField).last,
        );
        final notesInput = tester.widget<TextField>(
          find.byType(TextField).last,
        );
        expect(notesInput.maxLength, 500);
        expect(notesField.validator?.call('x' * 500), isNull);
        expect(
          notesField.validator?.call('x' * 501),
          'Catatan maksimal 500 karakter',
        );

        await tester.binding.setSurfaceSize(null);
      },
    );
  });

  testWidgets(
    'income flow follows five steps and preserves selections on Back',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final cashbook = _cashbook();
      final categories = [
        _category('category-income', 'Gaji', TransactionType.income),
      ];
      final wallets = [_wallet('wallet-a', 'Dompet Utama', 500000)];

      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(
        _transactionApp(
          cashbook: cashbook,
          categories: categories,
          wallets: wallets,
          type: TransactionType.income,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('transaction-step-amount')),
        findsOneWidget,
      );
      expect(find.text('Rp 0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Lanjut'))
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('amount-key-1')));
      await tester.tap(find.byKey(const ValueKey('amount-key-2')));
      await tester.pump();
      expect(find.text('Rp 12'), findsOneWidget);
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('transaction-step-category')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('category-option-category-income')),
      );
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transaction-step-wallet')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('wallet-option-wallet-a')));
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transaction-step-date')),
        findsOneWidget,
      );

      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transaction-step-wallet')),
        findsOneWidget,
      );
      expect(find.text('Dompet Utama'), findsOneWidget);

      await tester.tap(find.text('Kembali'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transaction-step-category')),
        findsOneWidget,
      );
      expect(find.byIcon(AppIcons.selected), findsOneWidget);

      semantics.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'transfer flow excludes source, explains insufficient balance, and handles one wallet',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final cashbook = _cashbook();
      final wallets = [
        _wallet('wallet-a', 'Saldo Kecil', 50),
        _wallet('wallet-b', 'Dompet Tujuan', 1000000),
      ];

      await tester.binding.setSurfaceSize(const Size(393, 852));
      await tester.pumpWidget(
        _transferApp(cashbook: cashbook, wallets: wallets),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('amount-key-1')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('amount-key-0')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('amount-key-0')));
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      expect(find.text('Saldo Kecil'), findsOneWidget);
      expect(find.text('Saldo kurang dari nominal'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('wallet-option-wallet-b')));
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('transfer-step-destination')),
        findsOneWidget,
      );
      expect(find.text('Dompet Tujuan'), findsNothing);
      expect(find.text('Saldo Kecil'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('wallet-option-wallet-a')));
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('transfer-step-date')), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await tester.pumpWidget(
        _transferApp(cashbook: cashbook, wallets: wallets.take(1).toList()),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('amount-key-1')));
      await tester.pump();
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Butuh dua dompet aktif'), findsOneWidget);
      expect(find.text('Buat dompet'), findsOneWidget);

      semantics.dispose();
      await tester.binding.setSurfaceSize(null);
    },
  );
}

Widget _transactionApp({
  required CashbookEntity cashbook,
  required List<CategoryEntity> categories,
  required List<WalletEntity> wallets,
  required TransactionType type,
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      activeCashbookProvider.overrideWith((ref) => cashbook),
      categoriesProvider(cashbook.cashbookId).overrideWith((ref) => categories),
      walletsProvider.overrideWith((ref) => wallets),
    ],
    child: MaterialApp(
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: TransactionAddFlowScreen(type: type),
    ),
  );
}

Widget _transferApp({
  required CashbookEntity cashbook,
  required List<WalletEntity> wallets,
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    key: UniqueKey(),
    overrides: [
      activeCashbookProvider.overrideWith((ref) => cashbook),
      walletsProvider.overrideWith((ref) => wallets),
    ],
    child: MaterialApp(
      theme: AppTheme.getLightTheme(),
      darkTheme: AppTheme.getDarkTheme(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: const TransferScreen(),
    ),
  );
}

CashbookEntity _cashbook() {
  return CashbookEntity(
    cashbookId: 'cashbook-1',
    userId: 'user-1',
    cashbookName: 'Buku Kas',
    createdAt: DateTime(2026, 8, 1),
  );
}

CategoryEntity _category(String id, String name, TransactionType type) {
  return CategoryEntity(
    categoryId: id,
    type: type,
    categoryName: name,
    icon: type == TransactionType.income ? 'gaji' : 'makanan',
    color: '#2F7D59',
  );
}

WalletEntity _wallet(String id, String name, int balance) {
  return WalletEntity(
    walletId: id,
    cashbookId: 'cashbook-1',
    type: WalletType.cash,
    walletName: name,
    initialBalance: balance,
    currentBalance: balance,
    createdAt: DateTime(2026, 8, 1),
  );
}

List<WalletEntity> _wallets() {
  return [
    _wallet('wallet-a', 'A', 100000),
    _wallet('wallet-b', 'B', 200000),
    _wallet('wallet-c', 'C', 300000),
  ];
}
