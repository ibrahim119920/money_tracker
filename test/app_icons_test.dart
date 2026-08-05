import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_tracker/core/constants/app_design_tokens.dart';
import 'package:money_tracker/domain/entities/entities.dart';
import 'package:money_tracker/presentation/icons/app_icons.dart';

void main() {
  group('AppIcons', () {
    test('uses matching active and inactive navigation pairs', () {
      expect(AppIcons.dashboard, Icons.home_outlined);
      expect(AppIcons.dashboardSelected, Icons.home_rounded);
      expect(AppIcons.transactions, Icons.receipt_long_outlined);
      expect(AppIcons.transactionsSelected, Icons.receipt_long_rounded);
      expect(AppIcons.reports, Icons.bar_chart_outlined);
      expect(AppIcons.reportsSelected, Icons.bar_chart_rounded);
      expect(AppIcons.settings, Icons.settings_outlined);
      expect(AppIcons.settingsSelected, Icons.settings_rounded);
    });

    test('maps every supported wallet type with a safe fallback', () {
      expect(AppIcons.forWalletType(WalletType.cash), Icons.payments_rounded);
      expect(
        AppIcons.forWalletType(WalletType.bankAcc),
        Icons.account_balance_rounded,
      );
      expect(
        AppIcons.forWalletType(WalletType.eWallet),
        Icons.smartphone_rounded,
      );
      expect(AppIcons.forWalletType(null), AppIcons.walletFallback);
    });

    test('maps transaction types deterministically', () {
      expect(
        AppIcons.forTransactionType(TransactionType.income),
        AppIcons.income,
      );
      expect(
        AppIcons.forTransactionType(TransactionType.expense),
        AppIcons.expense,
      );
      expect(
        AppIcons.forTransactionType(TransactionType.income),
        AppIcons.forTransactionType(TransactionType.income),
      );
    });

    test('normalizes known category aliases without changing stored keys', () {
      expect(
        AppIcons.forCategory('Icons.restaurant_outlined'),
        Icons.restaurant_rounded,
      );
      expect(AppIcons.forCategory('MAKANAN'), Icons.restaurant_rounded);
      expect(
        AppIcons.forCategory('health-and-safety'),
        Icons.medical_services_rounded,
      );
      expect(
        AppIcons.forCategory('shopping bag rounded'),
        Icons.shopping_bag_rounded,
      );
      expect(AppIcons.forCategory('komunikasi'), Icons.cell_tower_rounded);
    });

    test('returns a deterministic fallback for unsupported category keys', () {
      expect(AppIcons.forCategory(null), AppIcons.categoryFallback);
      expect(AppIcons.forCategory(''), AppIcons.categoryFallback);
      expect(AppIcons.forCategory('donasi'), AppIcons.categoryFallback);
      expect(AppIcons.forCategory('unknown-key'), AppIcons.categoryFallback);
    });

    test('uses the restrained Phase 2 icon-size scale', () {
      expect(AppIconSize.small, 18);
      expect(AppIconSize.regular, 24);
      expect(AppIconSize.navigation, 26);
      expect(AppIconSize.object, 30);
      expect(AppIconSize.hero, 36);
    });
  });
}
