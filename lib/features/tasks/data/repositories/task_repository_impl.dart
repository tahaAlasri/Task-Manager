import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/task_repository.dart';
import '../datasources/task_local_data_source.dart';
import '../models/task_model.dart';

/// تطبيق مستودع المهام لربط الـ Domain بالـ Data
class TaskRepositoryImpl implements TaskRepository {
  final TaskLocalDataSource localDataSource;

  TaskRepositoryImpl({required this.localDataSource});

  @override
  Future<List<TaskEntity>> getTasks({String? userId}) async {
    return await localDataSource.getTasks(userId: userId);
  }

  @override
  Future<List<TaskEntity>> getDeletedTasks({String? userId}) async {
    return await localDataSource.getDeletedTasks(userId: userId);
  }

  @override
  Future<List<TaskEntity>> getArchivedTasks({String? userId}) async {
    return await localDataSource.getArchivedTasks(userId: userId);
  }

  @override
  Future<void> addTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await localDataSource.saveTask(model);
  }

  @override
  Future<void> updateTask(TaskEntity task) async {
    final model = TaskModel.fromEntity(task);
    await localDataSource.saveTask(model);
  }

  @override
  Future<void> softDeleteTask(String id) async {
    await localDataSource.softDeleteTask(id);
  }

  @override
  Future<void> restoreTask(String id) async {
    await localDataSource.restoreTask(id);
  }

  @override
  Future<void> permanentDeleteTask(String id) async {
    await localDataSource.permanentDeleteTask(id);
  }

  @override
  Future<void> emptyTrash({String? userId}) async {
    await localDataSource.emptyTrash(userId: userId);
  }

  @override
  Future<void> archiveTask(String id) async {
    await localDataSource.archiveTask(id);
  }

  @override
  Future<void> unarchiveTask(String id) async {
    await localDataSource.unarchiveTask(id);
  }

  @override
  Future<void> deleteTask(String id) async {
    await localDataSource.deleteTask(id);
  }

  @override
  Future<void> deleteCompletedTasks({String? userId}) async {
    await localDataSource.deleteCompletedTasks(userId: userId);
  }

  @override
  Future<void> toggleTaskStatus(String id) async {
    await localDataSource.toggleTaskStatus(id);
  }

  @override
  Future<void> toggleFavoriteStatus(String id) async {
    await localDataSource.toggleFavoriteStatus(id);
  }
}
