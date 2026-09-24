import '../../features/tasks/domain/entities/task_entity.dart';

/// كلاس مساعد لحساب التكرار الذكي للمهام الدورية
class RecurrenceHelper {
  RecurrenceHelper._();

  /// حساب تاريخ الاستحقاق التالي بناءً على نوع التكرار
  static DateTime? calculateNextDueDate(
    DateTime currentDueDate,
    RecurrenceType type,
  ) {
    switch (type) {
      case RecurrenceType.none:
        return null;

      case RecurrenceType.daily:
        return currentDueDate.add(const Duration(days: 1));

      case RecurrenceType.weekdays:
        // أيام العمل: أحد (7) إلى خميس (4)
        // تخطي الجمعة (5) والسبت (6)
        DateTime next = currentDueDate.add(const Duration(days: 1));
        while (next.weekday == DateTime.friday ||
            next.weekday == DateTime.saturday) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case RecurrenceType.weekly:
        return currentDueDate.add(const Duration(days: 7));

      case RecurrenceType.monthly:
        // إضافة شهر مع معالجة الأشهر الأقصر (مثلاً 31 يناير → 28 فبراير)
        int newMonth = currentDueDate.month + 1;
        int newYear = currentDueDate.year;
        if (newMonth > 12) {
          newMonth = 1;
          newYear++;
        }
        // تحديد آخر يوم في الشهر الجديد لتفادي تجاوز عدد الأيام
        final lastDayOfNewMonth = DateTime(newYear, newMonth + 1, 0).day;
        final newDay = currentDueDate.day > lastDayOfNewMonth
            ? lastDayOfNewMonth
            : currentDueDate.day;
        return DateTime(
          newYear,
          newMonth,
          newDay,
          currentDueDate.hour,
          currentDueDate.minute,
        );
    }
  }

  /// التحقق مما إذا كان يجب إنشاء نسخة جديدة من المهمة المتكررة
  /// يعيد false إذا كان نوع التكرار none أو تجاوز تاريخ الانتهاء
  static bool shouldRecur({
    required RecurrenceType type,
    DateTime? endDate,
    DateTime? nextDueDate,
  }) {
    if (type == RecurrenceType.none) return false;
    if (endDate == null) return true; // بدون تاريخ انتهاء = تكرار لا نهائي
    if (nextDueDate == null) return false;
    return nextDueDate.isBefore(endDate) || nextDueDate.isAtSameMomentAs(endDate);
  }
}
