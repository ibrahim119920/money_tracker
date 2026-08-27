import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/app/theme.dart';
import 'package:money_tracker/core/utils/currency_formatter.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/providers/providers.dart';
import 'package:money_tracker/presentation/screens/cashbook/cashbook_list_screen.dart';

void main() {
  testWidgets('cashbook list item resolves its named balance provider', (
    tester,
  ) async {
    final cashbook = CashbookEntity(
      cashbookId: 'cashbook-1',
      userId: 'user-1',
      cashbookName: 'Buku Kas Keluarga',
      createdAt: DateTime(2026, 8, 8),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cashbookBalanceProvider(
            cashbook.cashbookId,
          ).overrideWith((ref) => 1750000),
        ],
        child: MaterialApp(
          theme: AppTheme.getLightTheme(),
          home: Scaffold(
            body: CashbookListItem(
              cashbook: cashbook,
              onEdit: () {},
              onSetDefault: () {},
              onDelete: () {},
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining(CurrencyFormatter.format(1750000)),
      findsOneWidget,
    );
    expect(find.text('Menghitung...'), findsNothing);

    await tester.pump();
    expect(
      find.textContaining(CurrencyFormatter.format(1750000)),
      findsOneWidget,
    );
    expect(find.text('Menghitung...'), findsNothing);
  });
}
