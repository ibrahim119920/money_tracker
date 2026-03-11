import 'package:flutter/material.dart';

/// Color constants untuk Money Tracker app
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF42A5F5);

  // Transaction Type Colors
  static const Color income = Color(0xFF43A047); // Hijau
  static const Color expense = Color(0xFFE53935); // Merah
  static const Color transfer = Color(0xFF8E24AA); // Ungu

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF29B6F6);

  // Neutral Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);
  static const Color outline = Color(0xFFBDBDBD);
  static const Color outlineVariant = Color(0xFFE0E0E0);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFFBDBDBD);
  static const Color textHint = Color(0xFFE0E0E0);

  // Disabled state
  static const Color disabled = Color(0xFDE0E0E0);

  // Category Colors (predefined system categories)
  static const Map<String, Color> categoryColors = {
    // Income
    'salary': Color(0xFF4CAF50),
    'bonus': Color(0xFF8BC34A),
    'investment': Color(0xFF009688),
    'freelance': Color(0xFF00BCD4),
    'business': Color(0xFF3F51B5),
    // Expense
    'food': Color(0xFFF44336),
    'transport': Color(0xFFFF5722),
    'shopping': Color(0xFFE91E63),
    'bills': Color(0xFFFF9800),
    'health': Color(0xFFF44336),
    'entertainment': Color(0xFF9C27B0),
    'education': Color(0xFF2196F3),
    'communication': Color(0xFF00BCD4),
  };
}
