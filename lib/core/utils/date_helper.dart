import 'package:intl/intl.dart';

/// دوال مساعدة لحساب التواريخ وحالات المهام
class DateHelper {
  DateHelper._();

  /// هل التاريخ يصادف اليوم؟
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  /// هل التاريخ يصادف الغد؟
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  /// هل المهمة متأخرة/مؤجلة عن موعدها؟
  static bool isOverdue(DateTime dueDate, {bool isCompleted = false}) {
    if (isCompleted) return false;
    return dueDate.isBefore(DateTime.now());
  }

  /// تنسيق مقروء وذكي للتاريخ (اليوم، غداً، أو اسم اليوم والتاريخ)
  static String formatSmartDate(DateTime date, {bool isArabic = true}) {
    if (isToday(date)) {
      return isArabic ? 'اليوم' : 'Today';
    } else if (isTomorrow(date)) {
      return isArabic ? 'غداً' : 'Tomorrow';
    } else {
      final locale = isArabic ? 'ar' : 'en';
      return DateFormat('EEE, d MMM', locale).format(date);
    }
  }

  /// تنسيق الوقت (مثال: 02:30 م / 02:30 PM)
  static String formatTime(DateTime date, {bool isArabic = true}) {
    final locale = isArabic ? 'ar' : 'en';
    return DateFormat('hh:mm a', locale).format(date);
  }

  /// تنسيق التاريخ والوقت كاملاً
  static String formatFullDateTime(DateTime date, {bool isArabic = true}) {
    return '${formatSmartDate(date, isArabic: isArabic)} • ${formatTime(date, isArabic: isArabic)}';
  }
}
