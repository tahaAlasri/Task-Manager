import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/tasks/domain/entities/subtask_entity.dart';
import 'package:task_manager/features/tasks/domain/entities/task_entity.dart';
import 'package:task_manager/features/tasks/domain/repositories/task_repository.dart';
import 'package:task_manager/features/tasks/presentation/cubit/task_cubit.dart';
import 'package:task_manager/features/tasks/presentation/cubit/task_state.dart';

class FakeTaskRepository implements TaskRepository {
  final List<TaskEntity> _tasks = [];
  final List<TaskEntity> _deletedTasks = [];
  final List<TaskEntity> _archivedTasks = [];

  @override
  Future<List<TaskEntity>> getTasks({String? userId}) async {
    if (userId == null) return List.unmodifiable(_tasks);
    return List.unmodifiable(_tasks.where((t) => t.userId == null || t.userId == userId));
  }

  @override
  Future<List<TaskEntity>> getDeletedTasks({String? userId}) async {
    if (userId == null) return List.unmodifiable(_deletedTasks);
    return List.unmodifiable(_deletedTasks.where((t) => t.userId == null || t.userId == userId));
  }

  @override
  Future<List<TaskEntity>> getArchivedTasks({String? userId}) async {
    if (userId == null) return List.unmodifiable(_archivedTasks);
    return List.unmodifiable(_archivedTasks.where((t) => t.userId == null || t.userId == userId));
  }

  @override
  Future<void> softDeleteTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = _tasks.removeAt(idx);
      _deletedTasks.add(t.copyWith(isDeleted: true, deletedAt: DateTime.now()));
    }
  }

  @override
  Future<void> restoreTask(String id) async {
    final idx = _deletedTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = _deletedTasks.removeAt(idx);
      _tasks.add(t.copyWith(isDeleted: false, deletedAt: null));
    }
  }

  @override
  Future<void> permanentDeleteTask(String id) async {
    _deletedTasks.removeWhere((t) => t.id == id);
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> emptyTrash({String? userId}) async {
    if (userId == null) {
      _deletedTasks.clear();
    } else {
      _deletedTasks.removeWhere((t) => t.userId == null || t.userId == userId);
    }
  }

  @override
  Future<void> archiveTask(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = _tasks.removeAt(idx);
      _archivedTasks.add(t.copyWith(isArchived: true));
    }
  }

  @override
  Future<void> unarchiveTask(String id) async {
    final idx = _archivedTasks.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final t = _archivedTasks.removeAt(idx);
      _tasks.add(t.copyWith(isArchived: false));
    }
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    _tasks.add(task);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    _tasks.removeWhere((t) => t.id == id);
  }

  @override
  Future<void> deleteCompletedTasks({String? userId}) async {
    if (userId == null) {
      _tasks.removeWhere((t) => t.isCompleted);
    } else {
      _tasks.removeWhere((t) => t.isCompleted && (t.userId == null || t.userId == userId));
    }
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final t = _tasks[index];
      _tasks[index] = TaskEntity(
        id: t.id,
        title: t.title,
        description: t.description,
        dueDate: t.dueDate,
        priority: t.priority,
        categoryId: t.categoryId,
        isCompleted: !t.isCompleted,
        isReminderEnabled: t.isReminderEnabled,
        isFavorite: t.isFavorite,
        userId: t.userId,
        subtasks: t.subtasks,
        createdAt: t.createdAt,
        recurrenceType: t.recurrenceType,
        recurrenceEndDate: t.recurrenceEndDate,
      );
    }
  }

  @override
  Future<void> toggleFavoriteStatus(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      final t = _tasks[index];
      _tasks[index] = TaskEntity(
        id: t.id,
        title: t.title,
        description: t.description,
        dueDate: t.dueDate,
        priority: t.priority,
        categoryId: t.categoryId,
        isCompleted: t.isCompleted,
        isReminderEnabled: t.isReminderEnabled,
        isFavorite: !t.isFavorite,
        userId: t.userId,
        subtasks: t.subtasks,
        createdAt: t.createdAt,
        recurrenceType: t.recurrenceType,
        recurrenceEndDate: t.recurrenceEndDate,
      );
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskCubit Tests', () {
    late FakeTaskRepository fakeRepo;
    late TaskCubit cubit;

    setUp(() {
      fakeRepo = FakeTaskRepository();
      cubit = TaskCubit(repository: fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('الحالة الابتدائية تكون initial وتفرغ قائمة المهام', () {
      expect(cubit.state.status, equals(TaskStateStatus.initial));
      expect(cubit.state.tasks, isEmpty);
      expect(cubit.state.sortOption, equals(TaskSortOption.dueDateAsc));
    });

    test('إضافة مهمة جديدة يحفظها ويحدث الحالة إلى success', () async {
      final task = TaskEntity(
        id: '1',
        title: 'مهمة جديدة',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        priority: TaskPriority.high,
        categoryId: 'work',
        isFavorite: true,
        subtasks: const [
          SubTaskEntity(id: 's1', title: 'خطوة 1', isCompleted: false),
        ],
        createdAt: DateTime.now(),
      );

      await cubit.addTask(task);

      expect(cubit.state.status, equals(TaskStateStatus.success));
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.title, equals('مهمة جديدة'));
      expect(cubit.state.tasks.first.isFavorite, isTrue);
      expect(cubit.state.tasks.first.subtasksCount, equals(1));
    });

    test('تعديل المهمة مع الاحتفاظ بنجمة المفضلة isFavorite', () async {
      final originalTask = TaskEntity(
        id: '1',
        title: 'مهمة أصلية',
        dueDate: DateTime.now(),
        priority: TaskPriority.medium,
        categoryId: 'study',
        isFavorite: true,
        createdAt: DateTime.now(),
      );
      await cubit.addTask(originalTask);

      final updatedTask = TaskEntity(
        id: '1',
        title: 'مهمة معدلة بالكامل',
        dueDate: originalTask.dueDate,
        priority: TaskPriority.high,
        categoryId: 'study',
        isFavorite: originalTask.isFavorite,
        createdAt: originalTask.createdAt,
      );
      await cubit.updateTask(updatedTask);

      expect(cubit.state.tasks.first.title, equals('مهمة معدلة بالكامل'));
      expect(cubit.state.tasks.first.isFavorite, isTrue);
      expect(cubit.state.tasks.first.priority, equals(TaskPriority.high));
    });

    test('فرز المهام حسب الأولوية من الأعلى إلى الأقل', () async {
      final lowTask = TaskEntity(
        id: '1',
        title: 'منخفضة',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'other',
        createdAt: DateTime.now(),
      );
      final highTask = TaskEntity(
        id: '2',
        title: 'عالية الأهمية',
        dueDate: DateTime.now(),
        priority: TaskPriority.high,
        categoryId: 'work',
        createdAt: DateTime.now(),
      );

      await cubit.addTask(lowTask);
      await cubit.addTask(highTask);

      cubit.setSortOption(TaskSortOption.priorityDesc);

      final filtered = cubit.state.filteredTasks;
      expect(filtered.first.priority, equals(TaskPriority.high));
      expect(filtered.last.priority, equals(TaskPriority.low));
    });

    test('فلترة المهام حسب درجة الأولوية', () async {
      final lowTask = TaskEntity(
        id: '1',
        title: 'منخفضة',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'other',
        createdAt: DateTime.now(),
      );
      final highTask = TaskEntity(
        id: '2',
        title: 'عالية',
        dueDate: DateTime.now(),
        priority: TaskPriority.high,
        categoryId: 'work',
        createdAt: DateTime.now(),
      );

      await cubit.addTask(lowTask);
      await cubit.addTask(highTask);

      cubit.setSelectedPriority(TaskPriority.high);
      expect(cubit.state.filteredTasks.length, equals(1));
      expect(cubit.state.filteredTasks.first.title, equals('عالية'));

      // إلغاء فلترة الأولوية بالضغط مجدداً
      cubit.setSelectedPriority(TaskPriority.high);
      expect(cubit.state.filteredTasks.length, equals(2));
    });

    test('حذف مهمة ثم التراجع عنها يرجعها للقائمة', () async {
      final task = TaskEntity(
        id: '99',
        title: 'مهمة للحذف',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'other',
        createdAt: DateTime.now(),
      );
      await cubit.addTask(task);
      expect(cubit.state.totalCount, equals(1));

      await cubit.deleteTask('99');
      expect(cubit.state.totalCount, equals(0));

      // محاكاة زر التراجع
      await cubit.addTask(task);
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.title, equals('مهمة للحذف'));
    });

    test('إكمال مهمة متكررة يومية يولّد نسخة جديدة تلقائياً', () async {
      final dueDate = DateTime(2026, 9, 16, 10, 0);
      final recurringTask = TaskEntity(
        id: 'recurring-1',
        title: 'مهمة يومية متكررة',
        dueDate: dueDate,
        priority: TaskPriority.medium,
        categoryId: 'personal',
        recurrenceType: RecurrenceType.daily,
        createdAt: DateTime.now(),
      );
      await cubit.addTask(recurringTask);
      expect(cubit.state.totalCount, equals(1));

      // إكمال المهمة المتكررة
      await cubit.toggleTaskStatus('recurring-1');

      // يجب أن تصبح المهمة الأصلية مكتملة + مهمة جديدة غير مكتملة
      expect(cubit.state.totalCount, equals(2));
      final completedTask = cubit.state.tasks.firstWhere((t) => t.id == 'recurring-1');
      expect(completedTask.isCompleted, isTrue);

      final newTask = cubit.state.tasks.firstWhere((t) => t.id != 'recurring-1');
      expect(newTask.isCompleted, isFalse);
      expect(newTask.title, equals('مهمة يومية متكررة'));
      expect(newTask.recurrenceType, equals(RecurrenceType.daily));
      // التاريخ التالي يجب أن يكون +1 يوم
      expect(newTask.dueDate.day, equals(dueDate.day + 1));
    });

    test('إكمال مهمة غير متكررة لا يولّد نسخة جديدة', () async {
      final task = TaskEntity(
        id: 'normal-1',
        title: 'مهمة عادية',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        priority: TaskPriority.low,
        categoryId: 'other',
        recurrenceType: RecurrenceType.none,
        createdAt: DateTime.now(),
      );
      await cubit.addTask(task);

      await cubit.toggleTaskStatus('normal-1');

      // يجب أن تبقى مهمة واحدة فقط (بدون نسخة جديدة)
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.isCompleted, isTrue);
    });

    test('المهمة المتكررة تتوقف عن التوليد عند تجاوز تاريخ الانتهاء', () async {
      final dueDate = DateTime(2026, 9, 16, 10, 0);
      final endDate = DateTime(2026, 9, 16, 23, 59); // نفس يوم الاستحقاق
      final recurringTask = TaskEntity(
        id: 'limited-1',
        title: 'مهمة محدودة التكرار',
        dueDate: dueDate,
        priority: TaskPriority.high,
        categoryId: 'work',
        recurrenceType: RecurrenceType.daily,
        recurrenceEndDate: endDate,
        createdAt: DateTime.now(),
      );
      await cubit.addTask(recurringTask);

      await cubit.toggleTaskStatus('limited-1');

      // تاريخ التكرار التالي (17 سبتمبر) بعد تاريخ الانتهاء (16 سبتمبر) → لا توليد
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.isCompleted, isTrue);
    });

    test('عزل مهام المستخدمين: المستخدم يرى فقط مهامه الخاصة', () async {
      // إعداد مهام للمستخدم الأول
      await cubit.setCurrentUser('user-1');
      await cubit.addTask(TaskEntity(
        id: 'u1-task',
        title: 'مهمة المستخدم الأول',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        priority: TaskPriority.high,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));

      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.userId, equals('user-1'));

      // التبديل إلى المستخدم الثاني
      await cubit.setCurrentUser('user-2');
      await cubit.addTask(TaskEntity(
        id: 'u2-task',
        title: 'مهمة المستخدم الثاني',
        dueDate: DateTime.now().add(const Duration(hours: 2)),
        priority: TaskPriority.medium,
        categoryId: 'personal',
        createdAt: DateTime.now(),
      ));

      // المستخدم الثاني يرى فقط مهمته
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.id, equals('u2-task'));
      expect(cubit.state.tasks.first.userId, equals('user-2'));

      // العودة للمستخدم الأول
      await cubit.setCurrentUser('user-1');
      expect(cubit.state.totalCount, equals(1));
      expect(cubit.state.tasks.first.id, equals('u1-task'));
    });

    test('clearTasks يفرغ المهام من الذاكرة تماماً عند تسجيل الخروج', () async {
      await cubit.setCurrentUser('user-1');
      await cubit.addTask(TaskEntity(
        id: 'u1-task-2',
        title: 'مهمة سرية',
        dueDate: DateTime.now().add(const Duration(hours: 1)),
        priority: TaskPriority.high,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));
      expect(cubit.state.totalCount, equals(1));

      // تسجيل الخروج ومسح الحالة
      cubit.clearTasks();
      expect(cubit.state.tasks, isEmpty);
      expect(cubit.state.totalCount, equals(0));
      expect(cubit.currentUserId, isNull);
    });

    test('softDeleteTask ينقل المهمة لسلة المهملات ويزيلها من المهام النشطة', () async {
      await cubit.addTask(TaskEntity(
        id: 'trash-test-1',
        title: 'مهمة للحذف المؤقت',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));
      expect(cubit.state.tasks.any((t) => t.id == 'trash-test-1'), isTrue);

      await cubit.softDeleteTask('trash-test-1');
      expect(cubit.state.tasks.any((t) => t.id == 'trash-test-1'), isFalse);

      final deleted = await cubit.getDeletedTasks();
      expect(deleted.any((t) => t.id == 'trash-test-1'), isTrue);
    });

    test('restoreTask يسترجع المهمة من سلة المهملات إلى المهام النشطة', () async {
      await cubit.addTask(TaskEntity(
        id: 'restore-test-1',
        title: 'مهمة ستسترجع',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));
      await cubit.softDeleteTask('restore-test-1');
      expect(cubit.state.tasks.any((t) => t.id == 'restore-test-1'), isFalse);

      await cubit.restoreTask('restore-test-1');
      expect(cubit.state.tasks.any((t) => t.id == 'restore-test-1'), isTrue);

      final deleted = await cubit.getDeletedTasks();
      expect(deleted.any((t) => t.id == 'restore-test-1'), isFalse);
    });

    test('archiveTask ينقل المهمة للأرشيف و unarchiveTask يسترجعها', () async {
      await cubit.addTask(TaskEntity(
        id: 'archive-test-1',
        title: 'مهمة للأرشفة',
        dueDate: DateTime.now(),
        priority: TaskPriority.medium,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));
      expect(cubit.state.tasks.any((t) => t.id == 'archive-test-1'), isTrue);

      await cubit.archiveTask('archive-test-1');
      expect(cubit.state.tasks.any((t) => t.id == 'archive-test-1'), isFalse);

      final archived = await cubit.getArchivedTasks();
      expect(archived.any((t) => t.id == 'archive-test-1'), isTrue);

      await cubit.unarchiveTask('archive-test-1');
      expect(cubit.state.tasks.any((t) => t.id == 'archive-test-1'), isTrue);

      final archivedAfter = await cubit.getArchivedTasks();
      expect(archivedAfter.any((t) => t.id == 'archive-test-1'), isFalse);
    });

    test('emptyTrash يفرغ سلة المهملات بالكامل', () async {
      await cubit.addTask(TaskEntity(
        id: 'empty-test-1',
        title: 'مهمة 1',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));
      await cubit.addTask(TaskEntity(
        id: 'empty-test-2',
        title: 'مهمة 2',
        dueDate: DateTime.now(),
        priority: TaskPriority.low,
        categoryId: 'work',
        createdAt: DateTime.now(),
      ));
      await cubit.softDeleteTask('empty-test-1');
      await cubit.softDeleteTask('empty-test-2');

      final deletedBefore = await cubit.getDeletedTasks();
      expect(deletedBefore.length, equals(2));

      await cubit.emptyTrash();
      final deletedAfter = await cubit.getDeletedTasks();
      expect(deletedAfter, isEmpty);
    });
  });
}
