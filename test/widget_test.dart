import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/tasks/data/models/task_model.dart';
import 'package:task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:task_manager/core/utils/recurrence_helper.dart';

void main() {
  group('TaskModel Tests', () {
    final now = DateTime.now();
    final task = TaskModel(
      id: 'test-123',
      title: 'إنجاز مهمة تجريبية',
      description: 'وصف المهمة للتأكد من نجاح الاختبار',
      dueDate: now,
      priority: TaskPriority.high,
      categoryId: 'work',
      isCompleted: false,
      isReminderEnabled: true,
      isFavorite: true,
      createdAt: now,
    );

    test('يجب تحويل المهمة إلى Map واستعادتها بنجاح مع خاصية المفضلة (Serialization/Deserialization)', () {
      final map = task.toMap();
      final restoredTask = TaskModel.fromMap(map);

      expect(restoredTask.id, equals(task.id));
      expect(restoredTask.title, equals(task.title));
      expect(restoredTask.description, equals(task.description));
      expect(restoredTask.priority, equals(TaskPriority.high));
      expect(restoredTask.categoryId, equals('work'));
      expect(restoredTask.isCompleted, isFalse);
      expect(restoredTask.isReminderEnabled, isTrue);
      expect(restoredTask.isFavorite, isTrue);
    });

    test('يجب نسخ وتعديل المهمة عبر copyWith بشكل سليم وتبديل المفضلة', () {
      final updatedTask = task.copyWith(
        isCompleted: true,
        priority: TaskPriority.low,
        isFavorite: false,
      );

      expect(updatedTask.id, equals(task.id));
      expect(updatedTask.isCompleted, isTrue);
      expect(updatedTask.priority, equals(TaskPriority.low));
      expect(updatedTask.isFavorite, isFalse);
      expect(task.isCompleted, isFalse); // التأكد من عدم تعديل الكائن الأصلي (Immutability)
      expect(task.isFavorite, isTrue);
    });

    test('المهمة بدون تكرار يجب أن تُخزَّن وتُسترجع بـ recurrenceType = none', () {
      final map = task.toMap();
      final restored = TaskModel.fromMap(map);

      expect(restored.recurrenceType, equals(RecurrenceType.none));
      expect(restored.recurrenceEndDate, isNull);
      expect(restored.isRecurring, isFalse);
    });

    test('المهمة المتكررة يجب أن تحفظ وتسترجع نوع التكرار وتاريخ الانتهاء', () {
      final endDate = DateTime(2026, 12, 31);
      final recurringTask = TaskModel(
        id: 'rec-1',
        title: 'مهمة أسبوعية',
        dueDate: now,
        priority: TaskPriority.medium,
        categoryId: 'personal',
        createdAt: now,
        recurrenceType: RecurrenceType.weekly,
        recurrenceEndDate: endDate,
      );

      final map = recurringTask.toMap();
      expect(map['recurrenceType'], equals('weekly'));
      expect(map['recurrenceEndDate'], isNotNull);

      final restored = TaskModel.fromMap(map);
      expect(restored.recurrenceType, equals(RecurrenceType.weekly));
      expect(restored.isRecurring, isTrue);
      expect(restored.recurrenceEndDate?.year, equals(2026));
      expect(restored.recurrenceEndDate?.month, equals(12));
    });

    test('البيانات القديمة بدون حقل التكرار تعمل بشكل طبيعي (Backward Compatibility)', () {
      // محاكاة بيانات قديمة بدون حقل recurrenceType
      final oldMap = {
        'id': 'old-1',
        'title': 'مهمة قديمة',
        'dueDate': now.toIso8601String(),
        'priority': 'low',
        'categoryId': 'other',
        'isCompleted': false,
        'isReminderEnabled': false,
        'isFavorite': false,
        'subtasks': [],
        'createdAt': now.toIso8601String(),
        // لا يوجد recurrenceType أو recurrenceEndDate
      };

      final restored = TaskModel.fromMap(oldMap);
      expect(restored.recurrenceType, equals(RecurrenceType.none));
      expect(restored.recurrenceEndDate, isNull);
      expect(restored.isRecurring, isFalse);
    });

    test('حقول المرحلة الثانية (الأرشيف، الحذف المؤقت، الوسوم، التذكير المتقدم) تُخزّن وتُسترجع بنجاح', () {
      final taskPhase2 = TaskModel(
        id: 'phase2-1',
        title: 'مهمة فئة 2 مع وسوم وأرشيف',
        dueDate: now,
        priority: TaskPriority.high,
        categoryId: 'work',
        isCompleted: false,
        isArchived: true,
        isDeleted: true,
        deletedAt: now,
        tags: const ['عاجل', 'برمجة', 'مشروع'],
        reminderMinutesBefore: 30,
        createdAt: now,
      );

      final map = taskPhase2.toMap();
      expect(map['isArchived'], isTrue);
      expect(map['isDeleted'], isTrue);
      expect(map['deletedAt'], isNotNull);
      expect(map['tags'], equals(['عاجل', 'برمجة', 'مشروع']));
      expect(map['reminderMinutesBefore'], equals(30));

      final restored = TaskModel.fromMap(map);
      expect(restored.isArchived, isTrue);
      expect(restored.isDeleted, isTrue);
      expect(restored.deletedAt, isNotNull);
      expect(restored.tags, equals(['عاجل', 'برمجة', 'مشروع']));
      expect(restored.reminderMinutesBefore, equals(30));
    });

    test('البيانات القديمة تفترض افتراضيات آمنة للحقول الجديدة', () {
      final legacyMap = {
        'id': 'legacy-99',
        'title': 'مهمة قديمة جداً',
        'dueDate': now.toIso8601String(),
        'priority': 'high',
        'categoryId': 'work',
        'isCompleted': false,
        'createdAt': now.toIso8601String(),
      };

      final restored = TaskModel.fromMap(legacyMap);
      expect(restored.isArchived, isFalse);
      expect(restored.isDeleted, isFalse);
      expect(restored.deletedAt, isNull);
      expect(restored.tags, isEmpty);
      expect(restored.reminderMinutesBefore, equals(0));
      expect(restored.attachments, isEmpty);
    });

    test('حقول المرحلة الثالثة (المرفقات والصور) تُخزّن وتُسترجع بنجاح', () {
      final taskPhase3 = TaskModel(
        id: 'phase3-1',
        title: 'مهمة مع صور ومرفقات',
        dueDate: now,
        priority: TaskPriority.medium,
        categoryId: 'work',
        attachments: const [
          '/data/user/0/app/attachments/img1.jpg',
          '/data/user/0/app/attachments/img2.jpg',
        ],
        createdAt: now,
      );

      final map = taskPhase3.toMap();
      expect(
        map['attachments'],
        equals([
          '/data/user/0/app/attachments/img1.jpg',
          '/data/user/0/app/attachments/img2.jpg',
        ]),
      );

      final restored = TaskModel.fromMap(map);
      expect(restored.attachments.length, equals(2));
      expect(restored.attachments.first, equals('/data/user/0/app/attachments/img1.jpg'));
    });
  });

  group('RecurrenceHelper Tests', () {
    test('التكرار اليومي يضيف يوماً واحداً', () {
      final date = DateTime(2026, 9, 16, 10, 0);
      final next = RecurrenceHelper.calculateNextDueDate(date, RecurrenceType.daily);

      expect(next, isNotNull);
      expect(next!.year, equals(2026));
      expect(next.month, equals(9));
      expect(next.day, equals(17));
      expect(next.hour, equals(10));
    });

    test('التكرار الأسبوعي يضيف 7 أيام', () {
      final date = DateTime(2026, 9, 16, 14, 30);
      final next = RecurrenceHelper.calculateNextDueDate(date, RecurrenceType.weekly);

      expect(next, isNotNull);
      expect(next!.day, equals(23));
      expect(next.hour, equals(14));
      expect(next.minute, equals(30));
    });

    test('التكرار الشهري يضيف شهراً مع معالجة الأشهر القصيرة', () {
      // 31 يناير → 28 فبراير (ليس سنة كبيسة في 2027)
      final date = DateTime(2027, 1, 31, 9, 0);
      final next = RecurrenceHelper.calculateNextDueDate(date, RecurrenceType.monthly);

      expect(next, isNotNull);
      expect(next!.month, equals(2));
      expect(next.day, equals(28)); // فبراير 2027 = 28 يوم
    });

    test('تكرار أيام العمل يتخطى الجمعة والسبت', () {
      // الخميس 17 سبتمبر 2026 (الخميس = weekday 4)
      final thursday = DateTime(2026, 9, 17, 8, 0);
      final next = RecurrenceHelper.calculateNextDueDate(thursday, RecurrenceType.weekdays);

      expect(next, isNotNull);
      // يجب أن يتخطى الجمعة (5) والسبت (6) ويعطي الأحد (7)
      expect(next!.weekday, isNot(equals(DateTime.friday)));
      expect(next.weekday, isNot(equals(DateTime.saturday)));
    });

    test('نوع التكرار none يعيد null', () {
      final date = DateTime(2026, 9, 16, 10, 0);
      final next = RecurrenceHelper.calculateNextDueDate(date, RecurrenceType.none);
      expect(next, isNull);
    });

    test('shouldRecur يعيد false عند تجاوز تاريخ الانتهاء', () {
      final endDate = DateTime(2026, 9, 16);
      final nextDate = DateTime(2026, 9, 17);

      final result = RecurrenceHelper.shouldRecur(
        type: RecurrenceType.daily,
        endDate: endDate,
        nextDueDate: nextDate,
      );
      expect(result, isFalse);
    });

    test('shouldRecur يعيد true بدون تاريخ انتهاء (تكرار لا نهائي)', () {
      final result = RecurrenceHelper.shouldRecur(
        type: RecurrenceType.daily,
        endDate: null,
        nextDueDate: DateTime(2030, 1, 1),
      );
      expect(result, isTrue);
    });

    test('shouldRecur يعيد true عندما يكون التاريخ التالي = تاريخ الانتهاء', () {
      final date = DateTime(2026, 9, 20);
      final result = RecurrenceHelper.shouldRecur(
        type: RecurrenceType.daily,
        endDate: date,
        nextDueDate: date,
      );
      expect(result, isTrue);
    });
  });
}
