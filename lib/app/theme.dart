import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/constants.dart';

/// Central Material 3 theme for Money Tracker.
class AppTheme {
  /// System bars use transparent surfaces while screens protect content with
  /// SafeArea and the appropriate view insets.
  static SystemUiOverlayStyle systemUiOverlayStyle(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: isDark
          ? Brightness.light
          : Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarContrastEnforced: false,
    );
  }

  static ThemeData getLightTheme() {
    return _buildTheme(
      brightness: Brightness.light,
      colorScheme: _lightColorScheme(),
    );
  }

  static ThemeData getDarkTheme() {
    return _buildTheme(
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme(),
    );
  }

  static ColorScheme _lightColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      brightness: Brightness.light,
      primary: AppColors.primary,
      onPrimary: AppColors.onPrimary,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      onSecondary: AppColors.onSecondary,
      secondaryContainer: AppColors.secondaryContainer,
      onSecondaryContainer: AppColors.onSecondaryContainer,
      tertiary: AppColors.tertiary,
      onTertiary: AppColors.onTertiary,
      tertiaryContainer: AppColors.tertiaryContainer,
      onTertiaryContainer: AppColors.onTertiaryContainer,
      surface: AppColors.surface,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      error: AppColors.error,
      onError: AppColors.onError,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      inverseSurface: AppColors.primaryDark,
      onInverseSurface: AppColors.onPrimary,
      inversePrimary: AppColors.primaryLight,
      scrim: Colors.black,
      shadow: Colors.black,
    );
  }

  static ColorScheme _darkColorScheme() {
    return ColorScheme.fromSeed(
      seedColor: AppColors.darkPrimary,
      brightness: Brightness.dark,
    ).copyWith(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkOnPrimaryContainer,
      secondary: AppColors.darkSecondary,
      onSecondary: AppColors.darkOnSecondary,
      secondaryContainer: AppColors.darkSecondaryContainer,
      onSecondaryContainer: AppColors.darkOnSecondaryContainer,
      tertiary: AppColors.darkTertiary,
      onTertiary: AppColors.darkOnTertiary,
      tertiaryContainer: AppColors.darkTertiaryContainer,
      onTertiaryContainer: AppColors.darkOnTertiaryContainer,
      surface: AppColors.darkSurface,
      surfaceContainerLowest: AppColors.darkSurfaceContainerLowest,
      surfaceContainerLow: AppColors.darkSurfaceContainerLow,
      surfaceContainer: AppColors.darkSurfaceContainer,
      surfaceContainerHigh: AppColors.darkSurfaceContainerHigh,
      surfaceContainerHighest: AppColors.darkSurfaceContainerHighest,
      outline: AppColors.darkOutline,
      outlineVariant: AppColors.darkOutlineVariant,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      error: AppColors.darkError,
      onError: AppColors.darkOnError,
      errorContainer: AppColors.darkErrorContainer,
      onErrorContainer: AppColors.darkOnErrorContainer,
      inverseSurface: AppColors.surface,
      onInverseSurface: AppColors.textPrimary,
      inversePrimary: AppColors.primary,
      scrim: Colors.black,
      shadow: Colors.black,
    );
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required ColorScheme colorScheme,
  }) {
    final isDark = brightness == Brightness.dark;
    final textTheme = _buildTextTheme(
      primary: colorScheme.onSurface,
      secondary: colorScheme.onSurfaceVariant,
      tertiary: isDark ? AppColors.darkTextTertiary : AppColors.textTertiary,
    );
    final appBarBackground = colorScheme.surfaceContainerLow;
    final appBarForeground = colorScheme.onSurface;
    final inputFill = colorScheme.surfaceContainerLow;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      extensions: <ThemeExtension<dynamic>>[
        isDark
            ? MoneyTrackerSemanticColors.dark
            : MoneyTrackerSemanticColors.light,
      ],
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      primaryTextTheme: textTheme.apply(
        bodyColor: appBarForeground,
        displayColor: appBarForeground,
      ),
      iconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: AppIconSize.regular,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: appBarForeground,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: appBarForeground,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: systemUiOverlayStyle(brightness),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.none,
        height: AppComponentHeight.navigationBar,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: AppRadius.compactBorder,
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
          final color = states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant;
          return textTheme.labelMedium?.copyWith(color: color);
        }),
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
          final color = states.contains(WidgetState.selected)
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant;
          return IconThemeData(color: color, size: AppIconSize.navigation);
        }),
      ),
      // Kept for screens that still use the legacy BottomNavigationBar API.
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        selectedLabelStyle: textTheme.labelMedium,
        unselectedLabelStyle: textTheme.labelMedium,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: AppElevation.none,
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: AppElevation.none,
        margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBorder),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: AppBorder.subtleWidth,
        space: AppSpacing.md,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        isDense: false,
        contentPadding: AppSpacing.controlPadding,
        border: OutlineInputBorder(
          borderRadius: AppRadius.compactBorder,
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.compactBorder,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.compactBorder,
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: AppBorder.focusWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.compactBorder,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.compactBorder,
          borderSide: BorderSide(
            color: colorScheme.error,
            width: AppBorder.focusWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.compactBorder,
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        floatingLabelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: isDark ? AppColors.darkTextHint : AppColors.textHint,
        ),
        errorStyle: textTheme.bodySmall?.copyWith(color: colorScheme.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: _filledButtonStyle(colorScheme, textTheme),
      ),
      // Existing screens may still use ElevatedButton; keep it visually
      // aligned with the new FilledButton treatment.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: _filledButtonStyle(colorScheme, textTheme),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: _outlinedButtonStyle(colorScheme, textTheme),
      ),
      textButtonTheme: TextButtonThemeData(
        style: _textButtonStyle(colorScheme, textTheme),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: AppElevation.low,
        focusElevation: AppElevation.raised,
        hoverElevation: AppElevation.raised,
        highlightElevation: AppElevation.low,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.controlBorder),
        extendedPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: _segmentedButtonStyle(colorScheme, textTheme),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        modalBackgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.low,
        modalElevation: AppElevation.low,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadius.prominentTopBorder,
        ),
        showDragHandle: true,
        dragHandleColor: colorScheme.outline,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.raised,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.regularBorder),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.inversePrimary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.compactBorder),
        behavior: SnackBarBehavior.floating,
        elevation: AppElevation.low,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        horizontalTitleGap: AppSpacing.sm,
        minLeadingWidth: AppIconSize.regular,
        minVerticalPadding: AppSpacing.xs,
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
        titleTextStyle: textTheme.bodyLarge,
        subtitleTextStyle: textTheme.bodySmall,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.surfaceContainerHigh,
        circularTrackColor: colorScheme.surfaceContainerHigh,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colorScheme.primary,
        selectionColor: colorScheme.primaryContainer,
        selectionHandleColor: colorScheme.primary,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color?>((states) {
          if (states.contains(WidgetState.disabled)) {
            return colorScheme.onSurface.withValues(alpha: 0.12);
          }
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : Colors.transparent;
        }),
        checkColor: WidgetStatePropertyAll<Color?>(colorScheme.onPrimary),
        side: BorderSide(color: colorScheme.outline),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBorder),
      ),
    );
  }

  static TextTheme _buildTextTheme({
    required Color primary,
    required Color secondary,
    required Color tertiary,
  }) {
    TextStyle style(
      double size,
      FontWeight weight,
      Color color, {
      double height = 1.4,
    }) {
      return TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: height,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      );
    }

    return TextTheme(
      displayLarge: style(32, FontWeight.w600, primary, height: 1.25),
      displayMedium: style(28, FontWeight.w600, primary, height: 1.29),
      displaySmall: style(24, FontWeight.w600, primary, height: 1.33),
      headlineLarge: style(22, FontWeight.w600, primary, height: 1.27),
      headlineMedium: style(20, FontWeight.w600, primary, height: 1.3),
      headlineSmall: style(18, FontWeight.w500, primary, height: 1.33),
      titleLarge: style(16, FontWeight.w600, primary, height: 1.5),
      titleMedium: style(14, FontWeight.w500, primary, height: 1.43),
      titleSmall: style(12, FontWeight.w500, primary, height: 1.33),
      bodyLarge: style(16, FontWeight.w400, primary, height: 1.5),
      bodyMedium: style(14, FontWeight.w400, primary, height: 1.43),
      bodySmall: style(12, FontWeight.w400, secondary, height: 1.33),
      labelLarge: style(14, FontWeight.w600, primary, height: 1.43),
      labelMedium: style(12, FontWeight.w500, secondary, height: 1.33),
      labelSmall: style(11, FontWeight.w500, tertiary, height: 1.45),
    );
  }

  static ButtonStyle _filledButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppComponentHeight.interactive),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        AppSpacing.controlPadding,
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadius.compactBorder),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withValues(alpha: 0.12)
            : colorScheme.primary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : colorScheme.onPrimary;
      }),
      textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
      elevation: const WidgetStatePropertyAll<double>(AppElevation.none),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _outlinedButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppComponentHeight.interactive),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        AppSpacing.controlPadding,
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadius.compactBorder),
      ),
      side: WidgetStateProperty.resolveWith<BorderSide?>((states) {
        final color = states.contains(WidgetState.disabled)
            ? colorScheme.outlineVariant
            : colorScheme.outline;
        return BorderSide(color: color, width: AppBorder.subtleWidth);
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : colorScheme.primary;
      }),
      textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _textButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppComponentHeight.interactive),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadius.compactBorder),
      ),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.disabled)
            ? colorScheme.onSurface.withValues(alpha: 0.38)
            : colorScheme.primary;
      }),
      textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }

  static ButtonStyle _segmentedButtonStyle(
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return ButtonStyle(
      minimumSize: const WidgetStatePropertyAll<Size>(
        Size(0, AppComponentHeight.interactive),
      ),
      padding: const WidgetStatePropertyAll<EdgeInsets>(
        EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      shape: WidgetStatePropertyAll<OutlinedBorder>(
        RoundedRectangleBorder(borderRadius: AppRadius.compactBorder),
      ),
      side: const WidgetStatePropertyAll<BorderSide?>(BorderSide.none),
      backgroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? colorScheme.primaryContainer
            : Colors.transparent;
      }),
      foregroundColor: WidgetStateProperty.resolveWith<Color?>((states) {
        return states.contains(WidgetState.selected)
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurfaceVariant;
      }),
      textStyle: WidgetStatePropertyAll<TextStyle?>(textTheme.labelLarge),
      tapTargetSize: MaterialTapTargetSize.padded,
    );
  }
}
