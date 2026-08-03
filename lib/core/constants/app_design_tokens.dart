import 'package:flutter/material.dart';

/// Shared spacing values based on an 8-point layout grid.
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 40;
  static const double screenHorizontal = 20;
  static const double section = 24;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );
  static const EdgeInsets compactPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: xs,
  );
  static const EdgeInsets controlPadding = EdgeInsets.symmetric(
    horizontal: md,
    vertical: sm,
  );
}

/// Semantic corner radii. Each value describes the role of a shape instead of
/// making every component look like the same rounded rectangle.
abstract final class AppRadius {
  static const double small = 8;
  static const double control = 12;
  static const double card = 18;
  static const double prominent = 28;
  static const double pill = 999;

  // Legacy aliases retained for existing screens during the shape migration.
  static const double compact = control;
  static const double regular = card;

  static const BorderRadius smallBorder = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius controlBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardBorder = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius prominentBorder = BorderRadius.all(
    Radius.circular(prominent),
  );
  static const BorderRadius prominentTopBorder = BorderRadius.vertical(
    top: Radius.circular(prominent),
  );

  // Legacy aliases retained for existing theme and feature callers.
  static const BorderRadius compactBorder = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius regularBorder = BorderRadius.all(
    Radius.circular(card),
  );
}

/// Border widths are kept deliberately quiet; color comes from the active
/// [ColorScheme] at the component level.
abstract final class AppBorder {
  static const double subtleWidth = 1;
  static const double focusWidth = 2;
}

/// Elevation steps for surfaces that need separation without heavy shadows.
abstract final class AppElevation {
  static const double none = 0;
  static const double low = 1;
  static const double raised = 2;
}

/// Standard icon sizes used by interactive and informational components.
abstract final class AppIconSize {
  static const double small = 18;
  static const double regular = 24;

  /// Bottom-navigation destinations.
  static const double navigation = 26;

  /// Wallet objects and supporting empty-state icons.
  static const double object = 30;

  /// Rare onboarding or hero-level states.
  static const double hero = 36;

  // Temporary compatibility values for screens deferred to later icon phases.
  // Remove these after those screens migrate to the restrained scale above.
  static const double large = 32;
  static const double prominent = 40;
}

/// Minimum heights preserve Android touch-target guidance and predictable
/// form rhythm.
abstract final class AppComponentHeight {
  static const double interactive = 48;
  static const double compactControl = 40;
  static const double field = 56;
  // Leaves room for Material 3 labels at the supported 1.3 text scale.
  static const double navigationBar = 88;
  // Two-line wallet names plus large values remain readable at 1.3 scale.
  static const double walletCard = 144;
}

/// Motion durations for state changes and navigation feedback.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 200);
  static const Duration emphasized = Duration(milliseconds: 300);
}
