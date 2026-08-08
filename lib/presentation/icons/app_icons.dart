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
    'income': Icons.work_rounded,
    'pemasukan': Icons.work_rounded,
    'pendapatan': Icons.work_rounded,
    'upah': Icons.work_rounded,
    'honor': Icons.work_rounded,
    'uang_masuk': Icons.work_rounded,
    'bonus': Icons.card_giftcard_rounded,
    'gift': Icons.card_giftcard_rounded,
    'hadiah': Icons.card_giftcard_rounded,
    'cashback': Icons.card_giftcard_rounded,
    'investment': Icons.trending_up_rounded,
    'trending_up': Icons.trending_up_rounded,
    'investasi': Icons.trending_up_rounded,
    'freelance': Icons.assignment_rounded,
    'assignment': Icons.assignment_rounded,
    'business': Icons.storefront_rounded,
    'bisnis': Icons.storefront_rounded,
    'usaha': Icons.storefront_rounded,
    'jualan': Icons.storefront_rounded,
    'food': Icons.restaurant_rounded,
    'restaurant': Icons.restaurant_rounded,
    'makanan': Icons.restaurant_rounded,
    'makan': Icons.restaurant_rounded,
    'minuman': Icons.restaurant_rounded,
    'kuliner': Icons.restaurant_rounded,
    'transport': Icons.directions_car_rounded,
    'directions_car': Icons.directions_car_rounded,
    'transportasi': Icons.directions_car_rounded,
    'bensin': Icons.local_gas_station_rounded,
    'fuel': Icons.local_gas_station_rounded,
    'parkir': Icons.local_parking_rounded,
    'parking': Icons.local_parking_rounded,
    'ojek': Icons.two_wheeler_rounded,
    'taxi': Icons.local_taxi_rounded,
    'perjalanan': Icons.directions_car_rounded,
    'travel': Icons.directions_car_rounded,
    'shopping': Icons.shopping_bag_rounded,
    'shopping_bag': Icons.shopping_bag_rounded,
    'belanja': Icons.shopping_bag_rounded,
    'groceries': Icons.shopping_bag_rounded,
    'grocery': Icons.shopping_bag_rounded,
    'pasar': Icons.shopping_bag_rounded,
    'kebutuhan': Icons.shopping_bag_rounded,
    'kebutuhan_harian': Icons.shopping_bag_rounded,
    'pakaian': Icons.checkroom_rounded,
    'clothing': Icons.checkroom_rounded,
    'fashion': Icons.checkroom_rounded,
    'bills': Icons.receipt_long_rounded,
    'receipt': Icons.receipt_long_rounded,
    'receipt_long': Icons.receipt_long_rounded,
    'tagihan': Icons.receipt_long_rounded,
    'listrik': Icons.bolt_rounded,
    'electricity': Icons.bolt_rounded,
    'air': Icons.water_drop_rounded,
    'water': Icons.water_drop_rounded,
    'internet': Icons.wifi_rounded,
    'subscription': Icons.subscriptions_rounded,
    'langganan': Icons.subscriptions_rounded,
    'sewa': Icons.home_rounded,
    'rent': Icons.home_rounded,
    'rumah': Icons.home_rounded,
    'home': Icons.home_rounded,
    'housing': Icons.home_rounded,
    'health': Icons.medical_services_rounded,
    'health_and_safety': Icons.medical_services_rounded,
    'medical_services': Icons.medical_services_rounded,
    'kesehatan': Icons.medical_services_rounded,
    'dokter': Icons.medical_services_rounded,
    'obat': Icons.medical_services_rounded,
    'beauty': Icons.spa_rounded,
    'kecantikan': Icons.spa_rounded,
    'entertainment': Icons.movie_rounded,
    'movie': Icons.movie_rounded,
    'hiburan': Icons.movie_rounded,
    'education': Icons.school_rounded,
    'school': Icons.school_rounded,
    'pendidikan': Icons.school_rounded,
    'kursus': Icons.school_rounded,
    'buku': Icons.menu_book_rounded,
    'communication': Icons.cell_tower_rounded,
    'phone': Icons.cell_tower_rounded,
    'cell_tower': Icons.cell_tower_rounded,
    'komunikasi': Icons.cell_tower_rounded,
    'pulsa': Icons.phone_android_rounded,
    'data': Icons.phone_android_rounded,
    'keluarga': Icons.family_restroom_rounded,
    'family': Icons.family_restroom_rounded,
    'anak': Icons.family_restroom_rounded,
    'hewan': Icons.pets_rounded,
    'pet': Icons.pets_rounded,
    'asuransi': Icons.shield_rounded,
    'insurance': Icons.shield_rounded,
    'pajak': Icons.account_balance_rounded,
    'tax': Icons.account_balance_rounded,
    'donasi': Icons.volunteer_activism_rounded,
    'donation': Icons.volunteer_activism_rounded,
    'sedekah': Icons.volunteer_activism_rounded,
    'zakat': Icons.volunteer_activism_rounded,
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
  /// Older user categories can have a generic or unknown icon key. When the
  /// category name is available, it is used as a second lookup before the
  /// neutral fallback so familiar names retain a meaningful visual identity.
  static IconData forCategory(String? key, {String? categoryName}) {
    final normalizedKey = _normalizeCategoryKey(key);
    final storedIcon = _categoryIcons[normalizedKey];
    if (storedIcon != null && !_isGenericCategoryKey(normalizedKey)) {
      return storedIcon;
    }

    final normalizedName = categoryKeyForName(categoryName ?? '');
    final nameIcon = _categoryIcons[normalizedName];
    if (nameIcon != null && !_isGenericCategoryKey(normalizedName)) {
      return nameIcon;
    }

    return storedIcon ?? categoryFallback;
  }

  /// Returns a persisted icon key for a newly created category name.
  ///
  /// Exact aliases are preferred, then individual words in longer Indonesian
  /// category names. Unknown names retain the neutral `category` key.
  static String categoryKeyForName(String categoryName) {
    final normalizedName = _normalizeCategoryKey(categoryName);
    if (_isMeaningfulCategoryKey(normalizedName)) return normalizedName;

    for (final segment in normalizedName.split('_')) {
      if (_isMeaningfulCategoryKey(segment)) return segment;
    }

    return 'category';
  }

  static bool _isMeaningfulCategoryKey(String key) {
    return !_isGenericCategoryKey(key) && _categoryIcons.containsKey(key);
  }

  static bool _isGenericCategoryKey(String key) {
    return key.isEmpty || key == 'category';
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
