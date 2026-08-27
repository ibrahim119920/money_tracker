import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/core/constants/app_colors.dart';
import 'package:money_tracker/core/constants/app_design_tokens.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/screens/transaction/transaction_list_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  testWidgets(
    'transaction history filters use equal segments and preserve legacy filter state',
    (tester) async {
      final semantics = tester.ensureSemantics();
      final container = ProviderContainer(
        overrides: [
          transactionsProvider.overrideWith(
            (ref) => Stream.value(const <TransactionEntity>[]),
          ),
          monthlySummaryProvider.overrideWith(
            (ref) async => {'income': 0, 'expense': 0},
          ),
          selectedMonthProvider.overrideWith((ref) => DateTime(2026, 8)),
          selectedMonthTransfersProvider.overrideWith(
            (ref) => [
              TransferEntity(
                transferId: 'transfer-1',
                cashbookId: 'cashbook-1',
                fromWalletId: 'wallet-a',
                toWalletId: 'wallet-b',
                amount: 125000,
                transferDate: DateTime(2026, 8, 8),
                createdAt: DateTime(2026, 8, 8),
                fromWalletName: 'Dompet Asal',
                toWalletName: 'Dompet Tujuan',
              ),
            ],
          ),
        ],
      );

      try {
        await tester.binding.setSurfaceSize(const Size(360, 800));
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.getLightTheme(),
              home: const TransactionListScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        final labels = [
          'Filter Semua',
          'Filter Pemasukan',
          'Filter Pengeluaran',
          'Filter Transfer',
        ];
        Finder segmentFor(String label) {
          return find.byWidgetPredicate(
            (widget) => widget is Semantics && widget.properties.label == label,
            description: label,
          );
        }

        final widths = [
          for (final label in labels) tester.getSize(segmentFor(label)).width,
        ];
        final expectedWidth =
            (360 - (2 * AppSpacing.screenHorizontal) - (2 * 2)) / 4;

        for (final width in widths) {
          expect(width, closeTo(expectedWidth, 1));
        }
        expect(widths[0], closeTo(widths[1], 1));
        expect(widths[1], closeTo(widths[2], 1));
        expect(widths[2], closeTo(widths[3], 1));
        final longestLabel = find
            .byWidgetPredicate(
              (widget) => widget is Text && widget.data == 'Pengeluaran',
              description: 'Pengeluaran text',
            )
            .first;
        expect(
          tester.widget<Text>(longestLabel).overflow,
          TextOverflow.ellipsis,
        );
        expect(tester.widget<Text>(longestLabel).softWrap, isFalse);

        final colorScheme = Theme.of(
          tester.element(find.byType(TransactionListScreen)),
        ).colorScheme;
        final expectedColors = <String, Color>{
          'Filter Semua': colorScheme.primaryContainer,
          'Filter Pemasukan': colorScheme.incomeContainer,
          'Filter Pengeluaran': colorScheme.expenseContainer,
          'Filter Transfer': colorScheme.transferContainer,
        };

        Future<void> tapAndExpect({
          required String label,
          required TransactionType? type,
        }) async {
          await tester.tap(segmentFor(label));
          await tester.pump();

          expect(tester.takeException(), isNull);
          expect(container.read(transactionFilterProvider).type, type);

          final selectedSemantics = tester.getSemantics(segmentFor(label));
          expect(selectedSemantics.flagsCollection.isButton, isTrue);
          expect(selectedSemantics.flagsCollection.isSelected, Tristate.isTrue);
          final selectedMaterial = find.descendant(
            of: segmentFor(label),
            matching: find.byType(Material),
          );
          expect(selectedMaterial, findsOneWidget);
          expect(
            tester.widget<Material>(selectedMaterial).color,
            expectedColors[label],
          );

          for (final otherLabel in labels.where((value) => value != label)) {
            expect(
              tester
                  .getSemantics(segmentFor(otherLabel))
                  .flagsCollection
                  .isSelected,
              isNot(Tristate.isTrue),
            );
          }
        }

        await tapAndExpect(
          label: 'Filter Pemasukan',
          type: TransactionType.income,
        );
        await tapAndExpect(
          label: 'Filter Pengeluaran',
          type: TransactionType.expense,
        );
        await tapAndExpect(label: 'Filter Semua', type: null);

        await tester.tap(segmentFor('Filter Transfer'));
        await tester.pumpAndSettle();
        expect(
          container.read(transactionHistorySegmentProvider),
          TransactionHistorySegment.transfer,
        );
        expect(container.read(transactionFilterProvider).type, isNull);
        expect(
          tester
              .getSemantics(segmentFor('Filter Transfer'))
              .flagsCollection
              .isSelected,
          Tristate.isTrue,
        );
        final transferMaterial = find.descendant(
          of: segmentFor('Filter Transfer'),
          matching: find.byType(Material),
        );
        expect(
          tester.widget<Material>(transferMaterial).color,
          expectedColors['Filter Transfer'],
        );
        expect(find.text('Dompet Asal → Dompet Tujuan'), findsOneWidget);
        expect(find.text('8 Agustus 2026'), findsOneWidget);
        expect(find.text('Rp 125.000'), findsOneWidget);
      } finally {
        semantics.dispose();
        container.dispose();
        await tester.binding.setSurfaceSize(null);
      }
    },
  );
}
