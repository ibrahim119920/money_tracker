import 'package:intl/intl.dart';

/// Date formatter untuk format tanggal Bahasa Indonesia
class DateFormatter {
  static const String _locale = 'id_ID';

  /// Format DateTime menjadi string format: "15 Januari 2024"
  static String formatLongDate(DateTime date) {
    final DateFormat formatter = DateFormat('d MMMM yyyy', _locale);
    return formatter.format(date);
  }

  /// Format DateTime menjadi string format: "15/01/2024"
  static String formatShortDate(DateTime date) {
    final DateFormat formatter = DateFormat('dd/MM/yyyy', _locale);
    return formatter.format(date);
  }

  /// Format DateTime menjadi string format: "15 Jan"
  static String formatMediumDate(DateTime date) {
    final DateFormat formatter = DateFormat('d MMM', _locale);
    return formatter.format(date);
  }

  /// Format DateTime menjadi string format: "Januari 2024"
  static String formatMonthYear(DateTime date) {
    final DateFormat formatter = DateFormat('MMMM yyyy', _locale);
    return formatter.format(date);
  }

  /// Format DateTime menjadi string format: "Jan '24"
  static String formatMonthYearShort(DateTime date) {
    final DateFormat formatter = DateFormat('MMM yy', _locale);
    return formatter.format(date);
  }

  /// Format DateTime menjadi string format: "Senin, 15 Januari 2024"
  static String formatFullDate(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE, d MMMM yyyy', _locale);
    return formatter.format(date);
  }

  /// Format DateTime menjadi string format: "15:30"
  static String formatTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('HH:mm', _locale);
    return formatter.format(dateTime);
  }

  /// Format DateTime menjadi string format: "15 Januari 2024 - 15:30"
  static String formatDateAndTime(DateTime dateTime) {
    final DateFormat formatter = DateFormat('d MMMM yyyy - HH:mm', _locale);
    return formatter.format(dateTime);
  }

  /// Parse string date format "dd/MM/yyyy" menjadi DateTime
  static DateTime? parseShortDate(String dateString) {
    try {
      final DateFormat formatter = DateFormat('dd/MM/yyyy');
      return formatter.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Get nama hari dari DateTime
  /// Contoh: DateTime(2024, 1, 15) -> "Senin"
  static String getDayName(DateTime date) {
    final DateFormat formatter = DateFormat('EEEE', _locale);
    return formatter.format(date);
  }

  /// Get nama bulan dari DateTime
  /// Contoh: DateTime(2024, 1, 15) -> "Januari"
  static String getMonthName(DateTime date) {
    final DateFormat formatter = DateFormat('MMMM', _locale);
    return formatter.format(date);
  }

  /// Get nama bulan pendek dari DateTime
  /// Contoh: DateTime(2024, 1, 15) -> "Jan"
  static String getMonthNameShort(DateTime date) {
    final DateFormat formatter = DateFormat('MMM', _locale);
    return formatter.format(date);
  }

  /// Check apakah dua tanggal sama (hanya date, ignore time)
  static bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  /// Check apakah tanggal hari ini
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// Check apakah tanggal kemarin
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, yesterday);
  }

  /// Format DateTime relative: "Hari ini", "Kemarin", atau format pendek
  static String relative(DateTime date) {
    if (isToday(date)) return 'Hari ini';
    if (isYesterday(date)) return 'Kemarin';
    return formatMediumDate(date);
  }
}
