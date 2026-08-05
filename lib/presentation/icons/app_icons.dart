import 'package:flutter/material.dart';

import '../../domain/entities/entities.dart';

/// Central Material icon vocabulary for presentation code.
///
/// This class intentionally contains only application-level concepts. Screens
/// should keep using text when an icon does not improve recognition, navigation,
/// action clarity, or financial meaning.
abstract final class AppIcons {
  // Navigation destinations use matching outlined/filled pairs.
  static const IconData dashboard = Icons.home_outlined;
  static const IconData dashboardSelected = Icons.home_rounded;
  static const IconData transactions = Icons.receipt_long_outlined;
  static const IconData transactionsSelected = Icons.receipt_long_rounded;
  static const IconData reports = Icons.bar_chart_outlined;
  static const IconData reportsSelected = Icons.bar_chart_rounded;
  static const IconData settings = Icons.settings_outlined;
  static const IconData settingsSelected = Icons.settings_rounded;

  // Common Dashboard actions and state.
  static const IconData add = Icons.add_rounded;
  static const IconData selected = Icons.check_rounded;
  static const IconData cashbook = Icons.menu_book_rounded;
  static const IconData manageCashbooks = Icons.settings_rounded;
  static const IconData dropdown = Icons.keyboard_arrow_down_rounded;
  static const IconData income = Icons.south_west_rounded;
  static const IconData expense = Icons.north_east_rounded;
  static const IconData transfer = Icons.swap_horiz_rounded;

  // Wallet identities.
  static const IconData cashWallet = Icons.payments_rounded;
  static const IconData bankWallet = Icons.account_balance_rounded;
  static const IconData eWallet = Icons.smartphone_rounded;
  static const IconData walletFallback = Icons.account_balance_wallet_rounded;

  // Category fallback is intentionally neutral.
  static const IconData categoryFallback = Icons.category_rounded;

  static const Map<String, IconData> _categoryIcons = {
    'salary': Icons.work_rounded,
    'work': Icons.work_rounded,
    'gaji': Icons.work_rounded,
    'bonus': Icons.card_giftcard_rounded,
    'gift': Icons.card_giftcard_rounded,
    'investment': Icons.trending_up_rounded,
    'trending_up': Icons.trending_up_rounded,
    'investasi': Icons.trending_up_rounded,
    'freelance': Icons.assignment_rounded,
    'assignment': Icons.assignment_rounded,
    'business': Icons.storefront_rounded,
    'bisnis': Icons.storefront_rounded,
    'food': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_rounded,
    'makanan': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'directions_car': Icons.directions_car_rounded,
    'transportasi': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'belanja': Icons.shopping_bag_rounded,
    'bills': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_long_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'tagihan': Icons.receipt_long_rounded,
    'health': Icons.medical_services_rounded,
    'health_and_safety': Icons.medical_services_rounded,
    'medical_services': Icons.medical_services_rounded,
    'kesehatan': Icons.medical_services_rounded,
    'entertainment': Icons.movie_rounded,
    'movie': Icons.movie_rounded,
    'hiburan': Icons.movie_rounded,
    'education': Icons.school_rounded,
    'school': Icons.school_rounded,
    'pendidikan': Icons.school_rounded,
    'communication': Icons.cell_tower_rounded,
    'phone': Icons.cell_tower_rounded,
    'cell_tower': Icons.cell_tower_rounded,
    'komunikasi': Icons.cell_tower_rounded,
    'transfer': Icons.swap_horiz_rounded,
    'swap_horiz': Icons.swap_horiz_rounded,
    'lainnya': Icons.category_rounded,
    'category': Icons.category_rounded,
  };

  /// Returns the stable icon for an existing wallet type.
  static IconData forWalletType(WalletType? type) {
    return switch (type) {
      WalletType.cash => cashWallet,
      WalletType.bankAcc => bankWallet,
      WalletType.eWallet => eWallet,
      null => walletFallback,
    };
  }

  /// Returns a consistent directional icon for a financial transaction type.
  static IconData forTransactionType(TransactionType type) {
    return switch (type) {
      TransactionType.income => income,
      TransactionType.expense => expense,
    };
  }

  /// Maps persisted category icon keys without modifying the stored value.
  ///
  /// Unknown, empty, and unsupported keys intentionally use a neutral fallback.
  static IconData forCategory(String? key) {
    final normalizedKey = _normalizeCategoryKey(key);
    return _categoryIcons[normalizedKey] ?? categoryFallback;
  }

  static String _normalizeCategoryKey(String? key) {
    var normalized = key?.trim().toLowerCase() ?? '';
    if (normalized.startsWith('icons.')) {
      normalized = normalized.substring('icons.'.length);
    }
    normalized = normalized.replaceAll(' ', '_').replaceAll('-', '_');

    for (final suffix in const ['_outlined', '_rounded']) {
      if (normalized.endsWith(suffix)) {
        normalized = normalized.substring(0, normalized.length - suffix.length);
        break;
      }
    }
    return normalized;
  }
}
