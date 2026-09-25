import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/utils/recurrence_helper.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import 'task_state.dart';

/// Cubit لإدارة عمليات وبيانات المهام والفلترة والبحث
class TaskCubit extends Cubit<TaskState> {
  final TaskRepository repository;
  final INotificationService _notificationService;
  String? _currentUserId;

  /// معرف المستخدم الحالي المسجل لعزل بيانات المهام
  String? get currentUserId => _currentUserId;

  /// تعيين المستخدم الحالي وإعادة تحميل مهامه الخاصة
  Future<void> setCurrentUser(String? userId) async {
    _currentUserId = userId;
    await loadTasks();
  }

  /// مسح المهام من الذاكرة والشاشة عند تسجيل الخروج
  void clearTasks() {
    _currentUserId = null;
    emit(const TaskState());
  }

  /// callback اختياري لعرض رسائل للمستخدم (SnackBar) من خارج الـ Cubit
  void Function(String message)? onRecurringTaskCreated;

  TaskCubit({
    required this.repository,
    INotificationService? notificationService,
  })  : _notificationService = notificationService ?? NotificationService.instance,
        super(const TaskState());

  /// تحميل كافة مهام المستخدم النشط من قاعدة البيانات المحلية
  Future<void> loadTasks() async {
    emit(state.copyWith(status: TaskStateStatus.loading));
    try {
      final tasks = await repository.getTasks(userId: _currentUserId);
      emit(state.copyWith(
        status: TaskStateStatus.success,
        tasks: tasks,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في تحميل المهام: $e',
      ));
    }
  }

  /// إضافة مهمة جديدة وربطها بالمستخدم النشط تلقائياً
  Future<void> addTask(TaskEntity task) async {
    try {
      final taskToSave = (task.userId == null && _currentUserId != null)
          ? TaskEntity(
              id: task.id,
              title: task.title,
              description: task.description,
              dueDate: task.dueDate,
              priority: task.priority,
              categoryId: task.categoryId,
              isCompleted: task.isCompleted,
              isReminderEnabled: task.isReminderEnabled,
              isFavorite: task.isFavorite,
              userId: _currentUserId,
              subtasks: task.subtasks,
              createdAt: task.createdAt,
              recurrenceType: task.recurrenceType,
              recurrenceEndDate: task.recurrenceEndDate,
              isArchived: task.isArchived,
              isDeleted: task.isDeleted,
              deletedAt: task.deletedAt,
              tags: task.tags,
              reminderMinutesBefore: task.reminderMinutesBefore,
            )
          : task;

      await repository.addTask(taskToSave);

      // جدولة تنبيه محلي مع مراعاة التنبيه المسبق إن وجد
      if (taskToSave.isReminderEnabled) {
        final notifId = taskToSave.id.hashCode.abs() % 1000000;
        final scheduledDate = taskToSave.reminderMinutesBefore > 0
            ? taskToSave.dueDate.subtract(Duration(minutes: taskToSave.reminderMinutesBefore))
            : taskToSave.dueDate;

        final body = taskToSave.reminderMinutesBefore > 0
            ? 'تنبيه مسبق (خلال ${taskToSave.reminderMinutesBefore} دقيقة): ${taskToSave.description ?? taskToSave.title}'
            : (taskToSave.description ?? 'حفظ وإنجاز مهامك اليومية خطوة بخطوة');

        await _notificationService.scheduleTaskReminder(
          id: notifId,
          title: 'تذكير بمهمة: ${taskToSave.title}',
          body: body,
          scheduledDate: scheduledDate,
        );
      }

      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في إضافة المهمة: $e',
      ));
    }
  }

  /// تعديل تفاصيل مهمة موجودة
  Future<void> updateTask(TaskEntity task) async {
    try {
      await repository.updateTask(task);

      final notifId = task.id.hashCode.abs() % 1000000;
      if (task.isReminderEnabled && !task.isCompleted && !task.isDeleted && !task.isArchived) {
        final scheduledDate = task.reminderMinutesBefore > 0
            ? task.dueDate.subtract(Duration(minutes: task.reminderMinutesBefore))
            : task.dueDate;

        final body = task.reminderMinutesBefore > 0
            ? 'تنبيه مسبق (خلال ${task.reminderMinutesBefore} دقيقة): ${task.description ?? task.title}'
            : (task.description ?? 'حان موعد استحقاق مهمتك');

        await _notificationService.scheduleTaskReminder(
          id: notifId,
          title: 'تذكير بمهمة: ${task.title}',
          body: body,
          scheduledDate: scheduledDate,
        );
      } else {
        await _notificationService.cancelReminder(notifId);
      }

      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في تعديل المهمة: $e',
      ));
    }
  }

  /// تبديل حالة الإنجاز (مكتملة / قيد التنفيذ)
  /// عند إكمال مهمة متكررة، يتم توليد النسخة التالية تلقائياً
  Future<void> toggleTaskStatus(String id) async {
    try {
      // جلب المهمة الحالية قبل التبديل لمعرفة حالتها
      final currentTask = state.tasks.firstWhere((t) => t.id == id);
      final willBeCompleted = !currentTask.isCompleted;

      await repository.toggleTaskStatus(id);
      final notifId = id.hashCode.abs() % 1000000;
      await _notificationService.cancelReminder(notifId);

      // إذا تم إكمال المهمة وهي متكررة → إنشاء النسخة التالية
      if (willBeCompleted && currentTask.isRecurring) {
        await _generateNextRecurringTask(currentTask);
      }

      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في تغيير حالة المهمة: $e',
      ));
    }
  }

  /// توليد المهمة المتكررة التالية تلقائياً
  Future<void> _generateNextRecurringTask(TaskEntity completedTask) async {
    final nextDueDate = RecurrenceHelper.calculateNextDueDate(
      completedTask.dueDate,
      completedTask.recurrenceType,
    );

    if (nextDueDate == null) return;

    final shouldCreate = RecurrenceHelper.shouldRecur(
      type: completedTask.recurrenceType,
      endDate: completedTask.recurrenceEndDate,
      nextDueDate: nextDueDate,
    );

    if (!shouldCreate) return;

    final newTask = TaskEntity(
      id: const Uuid().v4(),
      title: completedTask.title,
      description: completedTask.description,
      dueDate: nextDueDate,
      priority: completedTask.priority,
      categoryId: completedTask.categoryId,
      isCompleted: false,
      isReminderEnabled: completedTask.isReminderEnabled,
      isFavorite: completedTask.isFavorite,
      userId: completedTask.userId ?? _currentUserId,
      subtasks: const [], // المهام الفرعية تبدأ فارغة في كل نسخة جديدة
      createdAt: DateTime.now(),
      recurrenceType: completedTask.recurrenceType,
      recurrenceEndDate: completedTask.recurrenceEndDate,
    );

    await repository.addTask(newTask);

    // جدولة تنبيه للمهمة الجديدة
    if (newTask.isReminderEnabled) {
      final newNotifId = newTask.id.hashCode.abs() % 1000000;
      await _notificationService.scheduleTaskReminder(
        id: newNotifId,
        title: 'تذكير بمهمة متكررة: ${newTask.title}',
        body: newTask.description ?? 'حان وقت إنجاز مهمتك المتكررة',
        scheduledDate: newTask.dueDate,
      );
    }

    // إشعار المستخدم عبر callback
    onRecurringTaskCreated?.call(
      'تم إنشاء نسخة جديدة من "${completedTask.title}" 🔄',
    );
  }

  /// تبديل حالة المفضلة للمهمة
  Future<void> toggleFavorite(String id) async {
    try {
      await repository.toggleFavoriteStatus(id);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في تحديث حالة المفضلة: $e',
      ));
    }
  }

  /// جلب قائمة المهام المحذوفة مؤقتاً في سلة المهملات
  Future<List<TaskEntity>> getDeletedTasks() async {
    return await repository.getDeletedTasks(userId: _currentUserId);
  }

  /// جلب قائمة المهام المؤرشفة
  Future<List<TaskEntity>> getArchivedTasks() async {
    return await repository.getArchivedTasks(userId: _currentUserId);
  }

  /// نقل مهمة إلى سلة المحذوفات (حذف ناعم)
  Future<void> softDeleteTask(String id) async {
    try {
      await repository.softDeleteTask(id);
      final notifId = id.hashCode.abs() % 1000000;
      await _notificationService.cancelReminder(notifId);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في نقل المهمة لسلة المهملات: $e',
      ));
    }
  }

  /// استعادة مهمة من سلة المحذوفات
  Future<void> restoreTask(String id) async {
    try {
      await repository.restoreTask(id);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في استعادة المهمة: $e',
      ));
    }
  }

  /// الحذف النهائي للمهمة بدون استرجاع
  Future<void> permanentDeleteTask(String id) async {
    try {
      await repository.permanentDeleteTask(id);
      final notifId = id.hashCode.abs() % 1000000;
      await _notificationService.cancelReminder(notifId);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في حذف المهمة نهائياً: $e',
      ));
    }
  }

  /// تفريغ سلة المهملات بالكامل
  Future<void> emptyTrash() async {
    try {
      await repository.emptyTrash(userId: _currentUserId);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في تفريغ سلة المهملات: $e',
      ));
    }
  }

  /// أرشفة المهمة
  Future<void> archiveTask(String id) async {
    try {
      await repository.archiveTask(id);
      final notifId = id.hashCode.abs() % 1000000;
      await _notificationService.cancelReminder(notifId);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في أرشفة المهمة: $e',
      ));
    }
  }

  /// إلغاء أرشفة المهمة وإعادتها للقائمة الفعالة
  Future<void> unarchiveTask(String id) async {
    try {
      await repository.unarchiveTask(id);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في إلغاء أرشفة المهمة: $e',
      ));
    }
  }

  /// حذف مهمة فردية (افتراضياً نقل لسلة المحذوفات للحماية)
  Future<void> deleteTask(String id) async {
    await softDeleteTask(id);
  }

  /// حذف جميع المهام المكتملة للمستخدم الحالي دفعة واحدة
  Future<void> deleteCompletedTasks() async {
    try {
      await repository.deleteCompletedTasks(userId: _currentUserId);
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في حذف المهام المكتملة: $e',
      ));
    }
  }
  /// أرشفة عدة مهام دفعة واحدة
  Future<void> archiveMultipleTasks(List<String> ids) async {
    try {
      for (final id in ids) {
        await repository.archiveTask(id);
        final notifId = id.hashCode.abs() % 1000000;
        await _notificationService.cancelReminder(notifId);
      }
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في أرشفة المهام المحددة: $e',
      ));
    }
  }

  /// حذف عدة مهام دفعة واحدة (نقل لسلة المهملات)
  Future<void> deleteMultipleTasks(List<String> ids) async {
    try {
      for (final id in ids) {
        await repository.softDeleteTask(id);
        final notifId = id.hashCode.abs() % 1000000;
        await _notificationService.cancelReminder(notifId);
      }
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في حذف المهام المحددة: $e',
      ));
    }
  }

  /// إكمال عدة مهام دفعة واحدة
  Future<void> completeMultipleTasks(List<String> ids) async {
    try {
      for (final id in ids) {
        final task = state.tasks.firstWhere((t) => t.id == id, orElse: () => state.tasks.first);
        if (!task.isCompleted) {
          await repository.toggleTaskStatus(id);
          final notifId = id.hashCode.abs() % 1000000;
          await _notificationService.cancelReminder(notifId);
        }
      }
      await loadTasks();
    } catch (e) {
      emit(state.copyWith(
        status: TaskStateStatus.failure,
        errorMessage: 'فشل في إكمال المهام المحددة: $e',
      ));
    }
  }

  /// تغيير حالة الفلترة (الكل، اليوم، المكتملة، المؤجلة)
  void setFilterStatus(TaskFilterStatus filter) {
    emit(state.copyWith(filterStatus: filter));
  }

  /// تغيير طريقة فرز وترتيب المهام
  void setSortOption(TaskSortOption sortOption) {
    emit(state.copyWith(sortOption: sortOption));
  }

  /// تحديد مستوى الأولوية للفلترة (أو إزالته بالضغط عليه مجدداً)
  void setSelectedPriority(TaskPriority? priority) {
    if (priority == null || state.selectedPriority == priority) {
      emit(state.copyWith(clearPriorityFilter: true));
    } else {
      emit(state.copyWith(selectedPriority: priority));
    }
  }

  /// تغيير الفئة المحددة
  void setSelectedCategory(String categoryId) {
    emit(state.copyWith(selectedCategoryId: categoryId));
  }

  /// تحديث نص البحث
  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}

