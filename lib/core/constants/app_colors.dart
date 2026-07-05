import 'package:flutter/material.dart';

/// Color constants untuk Money Tracker app
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1B3A3A);
  static const Color primaryDark = Color(0xFF1A3535);
  static const Color primaryLight = Color(0xFF2A5A5A);

  // Accent Colors
  static const Color lavender = Color(0xFFC4B5E8);
  static const Color lime = Color(0xFFC4E538);
  static const Color mint = Color(0xFF7FB89A);
  static const Color peach = Color(0xFFF5D5C0);
  static const Color lightLavender = Color(0xFFE0D9F5);
  static const Color softTeal = Color(0xFFD4EDE4);

  // Transaction Type Colors
  static const Color income = Color(0xFF7ED957); // Lime green
  static const Color expense = Color(0xFFE53935); // Merah
  static const Color transfer = Color(0xFFB8A9E0); // Lavender

  // Status Colors
  static const Color success = Color(0xFF7ED957);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFF4C95D);
  static const Color info = Color(0xFF5BA89A);

  // Neutral Colors
  static const Color background = Color(0xFFDCE2E1);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F7F6);
  static const Color outline = Color(0xFF9CA8A8);
  static const Color outlineVariant = Color(0xFFD8DEDE);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A2B2B);
  static const Color textSecondary = Color(0xFF8B9A9A);
  static const Color textTertiary = Color(0xFF9CA8A8);
  static const Color textHint = Color(0xFFB7C0C0);

  // Disabled state
  static const Color disabled = Color(0xFFD8DEDE);

  // Dark Theme Colors (New Palette)
  // Primary Colors
  static const Color darkBackground = Color(0xFF0D1F1F);      // Background luar (dasar terdalam)
  static const Color darkSurface = Color(0xFF1E3535);         // Card/Surface (pengganti White)
  static const Color darkSurfaceVariant = Color(0xFF1C3232);  // Slightly lighter surface
  static const Color darkSurfaceContainer = Color(0xFF234040); // Elevated surface
  static const Color darkSurfaceContainerHigh = Color(0xFF2A4A4A); // Higher elevation
  static const Color darkOutline = Color(0xFF5C7086);         // Blue-gray for outlines
  static const Color darkOutlineVariant = Color(0xFF3E4A4A);  // Subtle outlines

  // Dark Text Colors
  static const Color darkTextPrimary = Color(0xFFF2F5F4);     // Teks utama (heading) - hampir putih
  static const Color darkTextSecondary = Color(0xFF8FA3A0);   // Teks sekunder (subtext)
  static const Color darkTextTertiary = Color(0xFF9AACA9);    // Teks tersier
  static const Color darkTextHint = Color(0xFF6B7A77);        // Hint text

  // Dark Primary (keep brand identity - Teal)
  static const Color darkPrimary = Color(0xFF6FCB4A);         // Green (active/highlight) - main brand
  static const Color darkPrimaryContainer = Color(0xFF1A3D1A); // Dark green container
  static const Color darkOnPrimary = Color(0xFF0D1F1F);       // On primary
  static const Color darkOnPrimaryContainer = Color(0xFFB8D22E); // Lime green on container

  // Dark Accent Colors
  static const Color darkLavender = Color(0xFF9F8FD4);        // Lavender/Purple (aksen besar)
  static const Color darkLavenderContainer = Color(0xFF3A3450); // Dark lavender container
  static const Color darkLime = Color(0xFFC8DB4A);            // Lime Green (aksen cerah)
  static const Color darkLimeContainer = Color(0xFF3D4A14);    // Dark lime container
  static const Color darkMint = Color(0xFF5C9578);            // Soft Mint/Sage Green
  static const Color darkMintContainer = Color(0xFF28403A);    // Teal/Mint (icon bg ketiga)
  static const Color darkPeach = Color(0xFF4A3A30);           // Peach/Cream (icon bg Virusology)
  static const Color darkSoftTeal = Color(0xFF3E8478);        // Teal (icon container Thorne B-complex)
  static const Color darkSecondaryContainer = Color(0xFF3A3450); // Secondary container
  static const Color darkTertiaryContainer = Color(0xFF3D4A14);   // Tertiary container

  // Dark Status Colors
  static const Color darkSuccess = Color(0xFF6FCB4A);          // Green (active/highlight)
  static const Color darkError = Color(0xFFEF5350);            // Red for errors
  static const Color darkWarning = Color(0xFFFFD54F);          // Yellow for warnings
  static const Color darkInfo = Color(0xFF7A6BB0);             // Purple (icon container Uronox)
  static const Color darkErrorContainer = Color(0xFF5A1A1A);   // Error container

  // Dark Disabled state
  static const Color darkDisabled = Color(0xFF3E4A4A);

  // Category Colors (predefined system categories)
  static const Map<String, Color> categoryColors = {
    // Income
    'salary': Color(0xFF7ED957),
    'bonus': Color(0xFFC4E538),
    'investment': Color(0xFF7FB89A),
    'freelance': Color(0xFF5BA89A),
    'business': Color(0xFF7A8FA6),
    // Expense
    'food': Color(0xFFF5D5C0),
    'transport': Color(0xFF7A8FA6),
    'shopping': Color(0xFFE0D9F5),
    'bills': Color(0xFFD4EDE4),
    'health': Color(0xFFF2B8B5),
    'entertainment': Color(0xFFC4B5E8),
    'education': Color(0xFFB8C7D6),
    'communication': Color(0xFFD4EDE4),
  };
}
