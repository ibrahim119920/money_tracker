import 'package:flutter/material.dart';

/// A wallet surface color and the foreground that is safe to render on it.
@immutable
class WalletPaletteEntry {
  const WalletPaletteEntry({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}

/// Color tokens for the Money Tracker visual system.
///
/// Existing names are kept for compatibility with feature screens that still
/// reference [AppColors] directly. New UI should prefer [ColorScheme],
/// [MoneyTrackerSemanticColors], and the deterministic palette helpers.
class AppColors {
  // -------------------------------------------------------------------------
  // Brand and Material 3 colors.
  // -------------------------------------------------------------------------
  static const Color primary = Color(0xFF155E63);
  static const Color primaryDark = Color(0xFF083D40);
  static const Color primaryLight = Color(0xFF4B898D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFFD3EFF0);
  static const Color onPrimaryContainer = Color(0xFF083D40);

  static const Color secondary = Color(0xFF6D5A85);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color secondaryContainer = Color(0xFFEEE7F5);
  static const Color onSecondaryContainer = Color(0xFF3E3151);

  static const Color tertiary = Color(0xFFC96A4B);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryContainer = Color(0xFFFCE6DE);
  static const Color onTertiaryContainer = Color(0xFF5D2E20);

  // -------------------------------------------------------------------------
  // Light semantic financial colors.
  // -------------------------------------------------------------------------
  static const Color income = Color(0xFF2F7D59);
  static const Color incomeContainer = Color(0xFFDCEFE4);
  static const Color onIncomeContainer = Color(0xFF123D29);

  static const Color expense = Color(0xFFB64B4B);
  static const Color expenseContainer = Color(0xFFF9DDDC);
  static const Color onExpenseContainer = Color(0xFF5D2020);

  static const Color transfer = Color(0xFF3F6DA8);
  static const Color transferContainer = Color(0xFFDDE9F7);
  static const Color onTransferContainer = Color(0xFF183D68);

  static const Color warning = Color(0xFFA66B17);
  static const Color warningContainer = Color(0xFFF7E8C9);
  static const Color onWarningContainer = Color(0xFF503305);

  static const Color success = Color(0xFF2F7D59);
  static const Color successContainer = Color(0xFFDCEFE4);
  static const Color onSuccessContainer = Color(0xFF123D29);

  static const Color neutralInfo = Color(0xFF60706E);
  static const Color neutralInfoContainer = Color(0xFFE3E9E7);
  static const Color onNeutralInfoContainer = Color(0xFF293735);

  // Info remains as a compatibility alias for neutral information.
  static const Color info = neutralInfo;
  static const Color infoContainer = neutralInfoContainer;
  static const Color onInfoContainer = onNeutralInfoContainer;

  // Error is kept conceptually separate from an expense transaction even
  // though both use a related red hue in the visual system.
  static const Color error = Color(0xFFB64B4B);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = Color(0xFFF9DDDC);
  static const Color onErrorContainer = Color(0xFF5D2020);

  // -------------------------------------------------------------------------
  // Light surface hierarchy and text.
  // -------------------------------------------------------------------------
  static const Color background = Color(0xFFFBFAF7);
  static const Color surface = Color(0xFFFBFAF7);
  static const Color surfaceVariant = Color(0xFFF4F3EF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF4F3EF);
  static const Color surfaceContainer = Color(0xFFECEBE6);
  static const Color surfaceContainerHigh = Color(0xFFE4E3DD);
  static const Color surfaceContainerHighest = Color(0xFFDCDAD4);
  static const Color outline = Color(0xFF798180);
  static const Color outlineVariant = Color(0xFFCDD2CF);

  static const Color textPrimary = Color(0xFF1B1D1D);
  static const Color textSecondary = Color(0xFF5C6363);
  static const Color textTertiary = Color(0xFF6F7674);
  static const Color textHint = Color(0xFF7A817F);
  static const Color disabled = Color(0xFFD4D6D3);
  static const Color onBackground = textPrimary;
  static const Color onSurface = textPrimary;
  static const Color onSurfaceVariant = textSecondary;

  // -------------------------------------------------------------------------
  // Curated light wallet palette.
  // -------------------------------------------------------------------------
  static const Color walletTeal = Color(0xFFB8D8D5);
  static const Color walletLavender = Color(0xFFC9C2DE);
  static const Color walletBlue = Color(0xFFBED3E7);
  static const Color walletSand = Color(0xFFE4D5B8);
  static const Color walletSage = Color(0xFFC7D8C5);

  static const List<WalletPaletteEntry> lightWalletPalette = [
    WalletPaletteEntry(background: walletTeal, foreground: Color(0xFF1B2C2B)),
    WalletPaletteEntry(
      background: walletLavender,
      foreground: Color(0xFF2C2540),
    ),
    WalletPaletteEntry(background: walletBlue, foreground: Color(0xFF203246)),
    WalletPaletteEntry(background: walletSand, foreground: Color(0xFF3A2B19)),
    WalletPaletteEntry(background: walletSage, foreground: Color(0xFF203327)),
  ];

  // -------------------------------------------------------------------------
  // Legacy light accent names retained for existing screens.
  // -------------------------------------------------------------------------
  static const Color lavender = walletLavender;
  static const Color lime = tertiary;
  static const Color mint = walletTeal;
  static const Color peach = walletSand;
  static const Color lightLavender = secondaryContainer;
  static const Color softTeal = primaryContainer;

  // Legacy foreground names retained for existing callers.
  static const Color onIncome = onIncomeContainer;
  static const Color onExpense = onExpenseContainer;
  static const Color onTransfer = onTransferContainer;
  static const Color lightIncomeForeground = income;
  static const Color lightExpenseForeground = expense;
  static const Color lightTransferForeground = transfer;

  static Color incomeForeground(Brightness brightness) {
    return brightness == Brightness.dark ? darkIncome : income;
  }

  static Color expenseForeground(Brightness brightness) {
    return brightness == Brightness.dark ? darkExpense : expense;
  }

  static Color transferForeground(Brightness brightness) {
    return brightness == Brightness.dark ? darkTransfer : transfer;
  }

  // -------------------------------------------------------------------------
  // Dark Material roles, surfaces, and text.
  // -------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0F1516);
  static const Color darkSurface = Color(0xFF0F1516);
  static const Color darkSurfaceVariant = Color(0xFF151C1D);
  static const Color darkSurfaceContainerLowest = Color(0xFF0A0F10);
  static const Color darkSurfaceContainerLow = Color(0xFF151C1D);
  static const Color darkSurfaceContainer = Color(0xFF1C2425);
  static const Color darkSurfaceContainerHigh = Color(0xFF253031);
  static const Color darkSurfaceContainerHighest = Color(0xFF303B3C);
  static const Color darkOutline = Color(0xFF87908E);
  static const Color darkOutlineVariant = Color(0xFF3C4747);

  static const Color darkTextPrimary = Color(0xFFE7E9E7);
  static const Color darkTextSecondary = Color(0xFFBAC3C1);
  static const Color darkTextTertiary = Color(0xFF9BA5A3);
  static const Color darkTextHint = Color(0xFF87918F);
  static const Color darkDisabled = Color(0xFF3C4747);
  static const Color darkOnBackground = darkTextPrimary;
  static const Color darkOnSurface = darkTextPrimary;
  static const Color darkOnSurfaceVariant = darkTextSecondary;

  static const Color darkPrimary = Color(0xFF8CD5D7);
  static const Color darkOnPrimary = Color(0xFF003739);
  static const Color darkPrimaryContainer = Color(0xFF145357);
  static const Color darkOnPrimaryContainer = Color(0xFFC7F2F3);
  static const Color darkSecondary = Color(0xFFD0C2E0);
  static const Color darkOnSecondary = Color(0xFF382D45);
  static const Color darkSecondaryContainer = Color(0xFF4A3D59);
  static const Color darkOnSecondaryContainer = Color(0xFFEEE3F5);
  static const Color darkTertiary = Color(0xFFF1B39B);
  static const Color darkOnTertiary = Color(0xFF502315);
  static const Color darkTertiaryContainer = Color(0xFF713F2F);
  static const Color darkOnTertiaryContainer = Color(0xFFFFDCCE);

  // -------------------------------------------------------------------------
  // Curated dark wallet palette and legacy dark accent aliases.
  // -------------------------------------------------------------------------
  static const Color darkWalletTeal = Color(0xFF245B58);
  static const Color darkWalletLavender = Color(0xFF41415B);
  static const Color darkWalletBlue = Color(0xFF304D68);
  static const Color darkWalletSand = Color(0xFF594C37);
  static const Color darkWalletSage = Color(0xFF3C5540);

  static const List<WalletPaletteEntry> darkWalletPalette = [
    WalletPaletteEntry(
      background: darkWalletTeal,
      foreground: Color(0xFFF2FAF8),
    ),
    WalletPaletteEntry(
      background: darkWalletLavender,
      foreground: Color(0xFFF4F0FF),
    ),
    WalletPaletteEntry(
      background: darkWalletBlue,
      foreground: Color(0xFFF1F7FF),
    ),
    WalletPaletteEntry(
      background: darkWalletSand,
      foreground: Color(0xFFFFF6E8),
    ),
    WalletPaletteEntry(
      background: darkWalletSage,
      foreground: Color(0xFFF1FAF1),
    ),
  ];

  static const Color darkLavender = darkWalletLavender;
  static const Color darkLavenderContainer = darkWalletLavender;
  static const Color darkLime = darkTertiary;
  static const Color darkLimeContainer = darkTertiaryContainer;
  static const Color darkMint = darkWalletTeal;
  static const Color darkMintContainer = darkWalletTeal;
  static const Color darkPeach = darkWalletSand;
  static const Color darkSoftTeal = darkPrimaryContainer;

  // -------------------------------------------------------------------------
  // Dark semantic financial colors.
  // -------------------------------------------------------------------------
  static const Color darkIncome = Color(0xFF7FD0A5);
  static const Color darkIncomeContainer = Color(0xFF204E36);
  static const Color darkOnIncomeContainer = Color(0xFFC5F4D7);
  static const Color darkExpense = Color(0xFFF29A9A);
  static const Color darkExpenseContainer = Color(0xFF642C31);
  static const Color darkOnExpenseContainer = Color(0xFFFFDADB);
  static const Color darkTransfer = Color(0xFF8CB6E6);
  static const Color darkTransferContainer = Color(0xFF294968);
  static const Color darkOnTransferContainer = Color(0xFFD8E9FF);
  static const Color darkWarning = Color(0xFFF0BE6D);
  static const Color darkWarningContainer = Color(0xFF5A431D);
  static const Color darkOnWarningContainer = Color(0xFFFFE6B4);
  static const Color darkSuccess = Color(0xFF7FD0A5);
  static const Color darkSuccessContainer = Color(0xFF204E36);
  static const Color darkOnSuccessContainer = Color(0xFFC5F4D7);
  static const Color darkNeutralInfo = Color(0xFFA9B8B5);
  static const Color darkNeutralInfoContainer = Color(0xFF2A3736);
  static const Color darkOnNeutralInfoContainer = Color(0xFFDAE7E4);
  static const Color darkInfo = darkNeutralInfo;
  static const Color darkInfoContainer = darkNeutralInfoContainer;
  static const Color darkOnInfoContainer = darkOnNeutralInfoContainer;

  static const Color darkError = Color(0xFFF29A9A);
  static const Color darkOnError = Color(0xFF5C1015);
  static const Color darkErrorContainer = Color(0xFF7A2930);
  static const Color darkOnErrorContainer = Color(0xFFFFDADB);

  // -------------------------------------------------------------------------
  // Deterministic categorical chart palette.
  // -------------------------------------------------------------------------
  static const List<Color> lightChartPalette = [
    Color(0xFF3D7EA6), // Blue
    Color(0xFFD96C75), // Coral
    Color(0xFFD9A441), // Amber
    Color(0xFF6B8F71), // Sage
    Color(0xFF7B6FA6), // Violet
    Color(0xFF73808A), // Slate / Lainnya
    Color(0xFF2F9CA6), // Cyan
    Color(0xFFB85D86), // Rose
  ];

  static const List<Color> darkChartPalette = [
    Color(0xFF75B3D6), // Blue
    Color(0xFFF08D95), // Coral
    Color(0xFFE8BE63), // Amber
    Color(0xFF8DB89B), // Sage
    Color(0xFFAA9BD4), // Violet
    Color(0xFF98A6AE), // Slate / Lainnya
    Color(0xFF70C7CE), // Cyan
    Color(0xFFDB8BB0), // Rose
  ];

  /// Returns a stable wallet color based on an application-level key.
  ///
  /// Callers should include the wallet type and wallet ID in [stableKey] so
  /// the result remains stable across rebuilds and distributes similar
  /// wallets across the curated palette.
  static WalletPaletteEntry walletPaletteFor(
    String stableKey,
    Brightness brightness,
  ) {
    final palette = brightness == Brightness.dark
        ? darkWalletPalette
        : lightWalletPalette;
    return palette[_stableIndex(stableKey, palette.length)];
  }

  /// Returns a stable category color. The presentation layer can pass the
  /// category ID and fall back to the category name when no ID is available.
  static Color chartColorFor(String stableKey, Brightness brightness) {
    final palette = brightness == Brightness.dark
        ? darkChartPalette
        : lightChartPalette;
    if (stableKey.trim().toLowerCase() == 'lainnya') {
      return palette[5];
    }
    return palette[_stableIndex(stableKey, palette.length)];
  }

  /// Selects readable chart-label text for both light and dark palettes.
  static Color chartForegroundFor(Color background, Brightness brightness) {
    final lightBackground = background.computeLuminance() > 0.35;
    if (lightBackground) {
      return brightness == Brightness.dark ? darkBackground : textPrimary;
    }
    return brightness == Brightness.dark ? darkTextPrimary : onPrimary;
  }

  static int _stableIndex(String value, int length) {
    var hash = 0x811C9DC5;
    for (final codeUnit in value.trim().toLowerCase().codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0x7FFFFFFF;
    }
    return hash % length;
  }

  // Compatibility map retained for legacy category presentation callers.
  static const Map<String, Color> categoryColors = {
    'salary': Color(0xFF3D7EA6),
    'bonus': Color(0xFFD9A441),
    'investment': Color(0xFF2F9CA6),
    'freelance': Color(0xFF6B8F71),
    'business': Color(0xFF73808A),
    'food': Color(0xFFD96C75),
    'transport': Color(0xFF3D7EA6),
    'shopping': Color(0xFFB85D86),
    'bills': Color(0xFF2F9CA6),
    'health': Color(0xFFD96C75),
    'entertainment': Color(0xFF7B6FA6),
    'education': Color(0xFFAA9BD4),
    'communication': Color(0xFF6B8F71),
  };
}

/// Compatibility accessors for screens that already read semantic colors from
/// [ColorScheme]. New code can use [MoneyTrackerSemanticColors] directly.
extension MoneyTrackerColorScheme on ColorScheme {
  Color get incomeColor =>
      brightness == Brightness.dark ? AppColors.darkIncome : AppColors.income;

  Color get onIncomeColor => brightness == Brightness.dark
      ? AppColors.darkOnIncomeContainer
      : AppColors.onIncomeContainer;

  Color get incomeContainer => brightness == Brightness.dark
      ? AppColors.darkIncomeContainer
      : AppColors.incomeContainer;

  Color get expenseColor =>
      brightness == Brightness.dark ? AppColors.darkExpense : AppColors.expense;

  Color get onExpenseColor => brightness == Brightness.dark
      ? AppColors.darkOnExpenseContainer
      : AppColors.onExpenseContainer;

  Color get expenseContainer => brightness == Brightness.dark
      ? AppColors.darkExpenseContainer
      : AppColors.expenseContainer;

  Color get transferColor => brightness == Brightness.dark
      ? AppColors.darkTransfer
      : AppColors.transfer;

  Color get onTransferColor => brightness == Brightness.dark
      ? AppColors.darkOnTransferContainer
      : AppColors.onTransferContainer;

  Color get transferContainer => brightness == Brightness.dark
      ? AppColors.darkTransferContainer
      : AppColors.transferContainer;

  Color get warningColor =>
      brightness == Brightness.dark ? AppColors.darkWarning : AppColors.warning;

  Color get warningContainer => brightness == Brightness.dark
      ? AppColors.darkWarningContainer
      : AppColors.warningContainer;

  Color get onWarningColor => brightness == Brightness.dark
      ? AppColors.darkOnWarningContainer
      : AppColors.onWarningContainer;

  Color get successColor =>
      brightness == Brightness.dark ? AppColors.darkSuccess : AppColors.success;

  Color get successContainer => brightness == Brightness.dark
      ? AppColors.darkSuccessContainer
      : AppColors.successContainer;

  Color get onSuccessColor => brightness == Brightness.dark
      ? AppColors.darkOnSuccessContainer
      : AppColors.onSuccessContainer;

  Color get infoColor =>
      brightness == Brightness.dark ? AppColors.darkInfo : AppColors.info;

  Color get infoContainer => brightness == Brightness.dark
      ? AppColors.darkInfoContainer
      : AppColors.infoContainer;

  Color get onInfoColor => brightness == Brightness.dark
      ? AppColors.darkOnInfoContainer
      : AppColors.onInfoContainer;

  Color get neutralInfoColor => brightness == Brightness.dark
      ? AppColors.darkNeutralInfo
      : AppColors.neutralInfo;

  Color get neutralInfoContainer => brightness == Brightness.dark
      ? AppColors.darkNeutralInfoContainer
      : AppColors.neutralInfoContainer;

  Color get onNeutralInfoColor => brightness == Brightness.dark
      ? AppColors.darkOnNeutralInfoContainer
      : AppColors.onNeutralInfoContainer;
}
