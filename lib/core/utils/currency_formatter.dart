import 'package:intl/intl.dart';

/// Currency formatter untuk format Rupiah (IDR)
class CurrencyFormatter {
  static const String _locale = 'id_ID';
  static const String _currencySymbol = 'Rp';

  /// Format amount menjadi string Rupiah
  /// Contoh: 1000000 -> "Rp 1.000.000"
  static String format(int amount) {
    final NumberFormat formatter = NumberFormat.currency(
      locale: _locale,
      symbol: '$_currencySymbol ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format amount menjadi string Rupiah tanpa symbol
  /// Contoh: 1000000 -> "1.000.000"
  static String formatWithoutSymbol(int amount) {
    final NumberFormat formatter = NumberFormat.decimalPattern(_locale);
    return formatter.format(amount);
  }

  /// Parse string menjadi int (untuk input form)
  /// Contoh: "1.000.000" -> 1000000
  static int? parse(String value) {
    if (value.isEmpty) return null;

    try {
      // Remove all non-digit characters
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleanValue);
    } catch (e) {
      return null;
    }
  }

  /// Format untuk display di input field dengan auto-grouping
  /// Menambahkan separator ribuan saat mengetik
  static String formatForDisplay(int amount) {
    if (amount == 0) return '';
    final formatted = formatWithoutSymbol(amount);
    return formatted;
  }

  /// Format untuk display simple tanpa symbol dan separator
  static String formatSimple(int amount) {
    return amount.toString();
  }

  /// Format amount menjadi string singkat Rupiah
  /// Contoh: 1500000 -> "Rp 1,5 jt", 2000 -> "Rp 2 rb"
  static String formatCompact(int amount) {
    if (amount >= 1000000000) {
      final value = amount / 1000000000;
      final disp = value % 1 == 0
          ? '${value.toInt()}'
          : value.toStringAsFixed(1).replaceAll('.', ',');
      return '$_currencySymbol $disp M';
    } else if (amount >= 1000000) {
      final value = amount / 1000000;
      final disp = value % 1 == 0
          ? '${value.toInt()}'
          : value.toStringAsFixed(1).replaceAll('.', ',');
      return '$_currencySymbol $disp jt';
    } else if (amount >= 1000) {
      final value = amount / 1000;
      final disp = value % 1 == 0
          ? '${value.toInt()}'
          : value.toStringAsFixed(1).replaceAll('.', ',');
      return '$_currencySymbol $disp rb';
    } else {
      return format(amount);
    }
  }
}
