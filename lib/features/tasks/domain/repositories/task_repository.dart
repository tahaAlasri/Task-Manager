import '../entities/task_entity.dart';

/// واجهة مستودع المهام (Contract) في طبقة الـ Domain
abstract class TaskRepository {
  /// جلب كافة المهام النشطة المحفوظة (مع إمكانية الفلترة بحسب المستخدم)
  Future<List<TaskEntity>> getTasks({String? userId});

  /// جلب المهام الموجودة في سلة المحذوفات
  Future<List<TaskEntity>> getDeletedTasks({String? userId});

  /// جلب المهام المؤرشفة
  Future<List<TaskEntity>> getArchivedTasks({String? userId});

  /// إضافة مهمة جديدة
  Future<void> addTask(TaskEntity task);

  /// تحديث بيانات مهمة موجودة
  Future<void> updateTask(TaskEntity task);

  /// نقل المهمة لسلة المحذوفات (حذف ناعم)
  Future<void> softDeleteTask(String id);

  /// استعادة المهمة من سلة المحذوفات
  Future<void> restoreTask(String id);

  /// الحذف النهائي للمهمة
  Future<void> permanentDeleteTask(String id);

  /// تفريغ سلة المحذوفات بالكامل للمستخدم
  Future<void> emptyTrash({String? userId});

  /// أرشفة المهمة
  Future<void> archiveTask(String id);

  /// إلغاء أرشفة المهمة
  Future<void> unarchiveTask(String id);

  /// حذف مهمة عبر معرفها
  Future<void> deleteTask(String id);

  /// حذف جميع المهام المكتملة للمستخدم الحالي دفعة واحدة
  Future<void> deleteCompletedTasks({String? userId});

  /// تبديل حالة المهمة بين مكتملة / قيد التنفيذ
  Future<void> toggleTaskStatus(String id);

  /// تبديل حالة المفضلة (إضافة / إزالة من المفضلة)
  Future<void> toggleFavoriteStatus(String id);
}
