import 'package:intl/intl.dart';

/// Formatting helpers for dates, macros, calories, and time.
class Formatters {
  Formatters._();

  static final DateFormat _dayOfWeekMonthDay = DateFormat('EEE, MMM d');
  static final DateFormat _timeOnly = DateFormat('h:mm a');
  static final DateFormat _isoDateOnly = DateFormat('yyyy-MM-dd');

  /// Format calories to whole number (e.g. "450 kcal")
  static String formatCalories(num? calories) {
    if (calories == null) return '0 kcal';
    return '${calories.round()} kcal';
  }

  /// Format macros to 1 decimal place (e.g. "24.5g")
  static String formatGrams(num? grams) {
    if (grams == null) return '0g';
    final rounded = (grams * 10).round() / 10.0;
    if (rounded % 1 == 0) {
      return '${rounded.toInt()}g';
    }
    return '${rounded.toStringAsFixed(1)}g';
  }

  /// Format date to readable label
  static String formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target == today) return 'Today';
    if (target == today.subtract(const Duration(days: 1))) return 'Yesterday';
    return _dayOfWeekMonthDay.format(date);
  }

  /// Format time (e.g. "1:30 PM")
  static String formatTime(DateTime time) {
    return _timeOnly.format(time);
  }

  /// Format ISO date string (YYYY-MM-DD)
  static String toIsoDate(DateTime date) {
    return _isoDateOnly.format(date);
  }

  /// Capitalize first letter of meal type (e.g. "Breakfast")
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1).toLowerCase();
  }

  /// Suggest meal type based on current time of day
  static String suggestMealType([DateTime? now]) {
    final time = now ?? DateTime.now();
    final hour = time.hour;
    if (hour >= 5 && hour < 11) {
      return 'breakfast';
    } else if (hour >= 11 && hour < 16) {
      return 'lunch';
    } else if (hour >= 16 && hour < 18) {
      return 'snack';
    } else if (hour >= 18 && hour < 22) {
      return 'dinner';
    } else {
      return 'snack';
    }
  }
}
