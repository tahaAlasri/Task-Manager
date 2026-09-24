import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/task_model.dart';

/// واجهة مصدر البيانات المحلي
abstract class TaskLocalDataSource {
  Future<List<TaskModel>> getTasks({
    String? userId,
    bool includeArchived = false,
    bool includeDeleted = false,
  });
  Future<List<TaskModel>> getDeletedTasks({String? userId});
  Future<List<TaskModel>> getArchivedTasks({String? userId});
  Future<void> saveTask(TaskModel task);
  Future<void> softDeleteTask(String id);
  Future<void> restoreTask(String id);
  Future<void> permanentDeleteTask(String id);
  Future<void> emptyTrash({String? userId});
  Future<void> archiveTask(String id);
  Future<void> unarchiveTask(String id);
  Future<void> deleteTask(String id);
  Future<void> deleteCompletedTasks({String? userId});
  Future<void> toggleTaskStatus(String id);
  Future<void> toggleFavoriteStatus(String id);
}

/// تطبيق مصدر البيانات المحلي باستخدام Hive Box
class TaskLocalDataSourceImpl implements TaskLocalDataSource {
  final Box _box;

  TaskLocalDataSourceImpl({Box? box})
      : _box = box ?? Hive.box(AppConstants.tasksBoxName);

  @override
  Future<List<TaskModel>> getTasks({
    String? userId,
    bool includeArchived = false,
    bool includeDeleted = false,
  }) async {
    final List<TaskModel> tasks = [];
    for (var i = 0; i < _box.length; i++) {
      final data = _box.getAt(i);
      if (data is Map) {
        final task = TaskModel.fromMap(data);
        // عزل المهام: إرجاع مهام المستخدم الحالي فقط
        if (userId == null || task.userId == null || task.userId == userId) {
          if (!includeDeleted && task.isDeleted) continue;
          if (!includeArchived && task.isArchived) continue;
          tasks.add(task);
        }
      }
    }
    // ترتيب المهام حسب تاريخ الاستحقاق
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return tasks;
  }

  @override
  Future<List<TaskModel>> getDeletedTasks({String? userId}) async {
    final List<TaskModel> tasks = [];
    for (var i = 0; i < _box.length; i++) {
      final data = _box.getAt(i);
      if (data is Map) {
        final task = TaskModel.fromMap(data);
        if (task.isDeleted) {
          if (userId == null || task.userId == null || task.userId == userId) {
            tasks.add(task);
          }
        }
      }
    }
    tasks.sort((a, b) => (b.deletedAt ?? b.dueDate).compareTo(a.deletedAt ?? a.dueDate));
    return tasks;
  }

  @override
  Future<List<TaskModel>> getArchivedTasks({String? userId}) async {
    final List<TaskModel> tasks = [];
    for (var i = 0; i < _box.length; i++) {
      final data = _box.getAt(i);
      if (data is Map) {
        final task = TaskModel.fromMap(data);
        if (task.isArchived && !task.isDeleted) {
          if (userId == null || task.userId == null || task.userId == userId) {
            tasks.add(task);
          }
        }
      }
    }
    tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return tasks;
  }

  @override
  Future<void> saveTask(TaskModel task) async {
    // استخدام task.id كمفتاح في Hive Box للوصول والتحديث السريع
    await _box.put(task.id, task.toMap());
  }

  @override
  Future<void> softDeleteTask(String id) async {
    final val = _box.get(id);
    if (val is Map) {
      final task = TaskModel.fromMap(val);
      final updated = task.copyWith(
        isDeleted: true,
        deletedAt: DateTime.now(),
      );
      await _box.put(id, updated.toMap());
    }
  }

  @override
  Future<void> restoreTask(String id) async {
    final val = _box.get(id);
    if (val is Map) {
      final task = TaskModel.fromMap(val);
      final updated = task.copyWith(
        isDeleted: false,
        clearDeletedAt: true,
      );
      await _box.put(id, updated.toMap());
    }
  }

  @override
  Future<void> permanentDeleteTask(String id) async {
    await _box.delete(id);
  }

  @override
  Future<void> emptyTrash({String? userId}) async {
    final keysToDelete = <dynamic>[];
    for (var key in _box.keys) {
      final val = _box.get(key);
      if (val is Map && val['isDeleted'] == true) {
        if (userId == null || val['userId'] == null || val['userId'] == userId) {
          keysToDelete.add(key);
        }
      }
    }
    await _box.deleteAll(keysToDelete);
  }

  @override
  Future<void> archiveTask(String id) async {
    final val = _box.get(id);
    if (val is Map) {
      final task = TaskModel.fromMap(val);
      final updated = task.copyWith(isArchived: true);
      await _box.put(id, updated.toMap());
    }
  }

  @override
  Future<void> unarchiveTask(String id) async {
    final val = _box.get(id);
    if (val is Map) {
      final task = TaskModel.fromMap(val);
      final updated = task.copyWith(isArchived: false);
      await _box.put(id, updated.toMap());
    }
  }

  @override
  Future<void> deleteTask(String id) async {
    // الحذف الافتراضي هو نقل لسلة المحذوفات للحفاظ على الأمان
    await softDeleteTask(id);
  }

  @override
  Future<void> deleteCompletedTasks({String? userId}) async {
    final keysToDelete = <dynamic>[];
    for (var key in _box.keys) {
      final val = _box.get(key);
      if (val is Map && val['isCompleted'] == true) {
        if (userId == null || val['userId'] == null || val['userId'] == userId) {
          keysToDelete.add(key);
        }
      }
    }
    await _box.deleteAll(keysToDelete);
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    final val = _box.get(id);
    if (val is Map) {
      final task = TaskModel.fromMap(val);
      final updatedTask = task.copyWith(isCompleted: !task.isCompleted);
      await _box.put(id, updatedTask.toMap());
    }
  }

  @override
  Future<void> toggleFavoriteStatus(String id) async {
    final val = _box.get(id);
    if (val is Map) {
      final task = TaskModel.fromMap(val);
      final updatedTask = task.copyWith(isFavorite: !task.isFavorite);
      await _box.put(id, updatedTask.toMap());
    }
  }
}
