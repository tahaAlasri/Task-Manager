import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/tasks/data/models/task_model.dart';
import '../../features/tasks/domain/entities/task_entity.dart';

/// خدمة إدارة قاعدة البيانات المحلية (Hive) والنسخ الاحتياطي الداخلي
/// تعمل بنسبة 100% بدون اتصال بالإنترنت (Offline-Only)
class LocalDatabaseService {
  LocalDatabaseService._();
  static final LocalDatabaseService instance = LocalDatabaseService._();

  static const String _backupBoxName = 'injaz_local_backup_box';
  static const String _backupKey = 'latest_tasks_snapshot';
  static const String _backupTimestampKey = 'latest_backup_timestamp';

  /// إنشاء نسخة احتياطية محلية فورية لكافة المهام في مساحة تخزين Hive
  Future<bool> createLocalBackup(List<TaskEntity> tasks) async {
    try {
      final box = await Hive.openBox(_backupBoxName);
      final list = tasks.map((t) => TaskModel.fromEntity(t).toMap()).toList();
      final jsonString = jsonEncode(list);

      await box.put(_backupKey, jsonString);
      await box.put(_backupTimestampKey, DateTime.now().toIso8601String());

      // ضغط وتنظيم صناديق البيانات لسرعة استجابة فائقة
      await compactAllBoxes();

      debugPrint('Local Hive backup created successfully. Total tasks: ${tasks.length}');
      return true;
    } catch (e) {
      debugPrint('Local Hive backup error: $e');
      return false;
    }
  }

  /// استرجاع تاريخ آخر نسخة احتياطية محلية
  Future<DateTime?> getLastBackupTimestamp() async {
    try {
      final box = await Hive.openBox(_backupBoxName);
      final raw = box.get(_backupTimestampKey) as String?;
      if (raw != null) {
        return DateTime.tryParse(raw);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// استعادة المهام من النسخة الاحتياطية المحلية ككائنات
  Future<List<TaskEntity>?> restoreLocalBackup() async {
    try {
      final box = await Hive.openBox(_backupBoxName);
      final rawJson = box.get(_backupKey) as String?;
      if (rawJson == null || rawJson.isEmpty) return null;

      final decoded = jsonDecode(rawJson) as List<dynamic>;
      return decoded.map((item) => TaskModel.fromMap(Map<String, dynamic>.from(item))).toList();
    } catch (e) {
      debugPrint('Local Hive restore error: $e');
      return null;
    }
  }

  /// استعادة النسخة الاحتياطية وتطبيقها مباشرة على صندوق المهام الفعال (Active Box)
  Future<int?> restoreBackupToActiveBox() async {
    try {
      final tasks = await restoreLocalBackup();
      if (tasks == null || tasks.isEmpty) return null;

      final targetBox = Hive.isBoxOpen(AppConstants.tasksBoxName)
          ? Hive.box(AppConstants.tasksBoxName)
          : await Hive.openBox(AppConstants.tasksBoxName);

      for (final t in tasks) {
        final model = TaskModel.fromEntity(t);
        await targetBox.put(model.id, model.toMap());
      }
      return tasks.length;
    } catch (e) {
      debugPrint('Error restoring backup to active box: $e');
      return null;
    }
  }

  /// تصدير كافة المهام كنص JSON منظم للحفظ أو المشاركة الخارجية
  Future<String?> exportToJsonString() async {
    try {
      final targetBox = Hive.isBoxOpen(AppConstants.tasksBoxName)
          ? Hive.box(AppConstants.tasksBoxName)
          : await Hive.openBox(AppConstants.tasksBoxName);

      final List<Map<String, dynamic>> list = [];
      for (var i = 0; i < targetBox.length; i++) {
        final val = targetBox.getAt(i);
        if (val is Map) {
          list.add(Map<String, dynamic>.from(val));
        }
      }

      final exportData = {
        'version': '1.0',
        'exportDate': DateTime.now().toIso8601String(),
        'appName': 'Injaz Task Manager',
        'totalTasks': list.length,
        'tasks': list,
      };

      return const JsonEncoder.withIndent('  ').convert(exportData);
    } catch (e) {
      debugPrint('Export to JSON error: $e');
      return null;
    }
  }

  /// استيراد مهام من نص JSON محفوظ سابقاً
  Future<int?> importFromJsonString(String jsonContent) async {
    try {
      final decoded = jsonDecode(jsonContent);
      List<dynamic> taskList;

      if (decoded is List) {
        taskList = decoded;
      } else if (decoded is Map && decoded['tasks'] is List) {
        taskList = decoded['tasks'] as List;
      } else {
        return null;
      }

      final targetBox = Hive.isBoxOpen(AppConstants.tasksBoxName)
          ? Hive.box(AppConstants.tasksBoxName)
          : await Hive.openBox(AppConstants.tasksBoxName);

      int count = 0;
      for (final item in taskList) {
        if (item is Map) {
          final model = TaskModel.fromMap(Map<String, dynamic>.from(item));
          await targetBox.put(model.id, model.toMap());
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('Import from JSON error: $e');
      return null;
    }
  }

  /// تحسين وضغط صناديق Hive المحلية لتحرير المساحة
  Future<void> compactAllBoxes() async {
    try {
      if (Hive.isBoxOpen(AppConstants.tasksBoxName)) {
        await Hive.box(AppConstants.tasksBoxName).compact();
      }
      if (Hive.isBoxOpen(AppConstants.settingsBoxName)) {
        await Hive.box(AppConstants.settingsBoxName).compact();
      }
      if (Hive.isBoxOpen(AppConstants.authBoxName)) {
        await Hive.box(AppConstants.authBoxName).compact();
      }
      if (Hive.isBoxOpen('pomodoro_box')) {
        await Hive.box('pomodoro_box').compact();
      }
      if (Hive.isBoxOpen(_backupBoxName)) {
        await Hive.box(_backupBoxName).compact();
      }
    } catch (e) {
      debugPrint('Error compacting Hive boxes: $e');
    }
  }

  /// جلب إحصائيات قاعدة البيانات المحلية
  Future<Map<String, dynamic>> getDatabaseStats() async {
    int totalTasks = 0;
    int completedTasks = 0;
    int favoriteTasks = 0;

    if (Hive.isBoxOpen(AppConstants.tasksBoxName)) {
      final box = Hive.box(AppConstants.tasksBoxName);
      totalTasks = box.length;
      for (var item in box.values) {
        if (item is Map) {
          if (item['isCompleted'] == true) completedTasks++;
          if (item['isFavorite'] == true) favoriteTasks++;
        }
      }
    }

    final lastBackup = await getLastBackupTimestamp();

    return {
      'totalTasks': totalTasks,
      'completedTasks': completedTasks,
      'favoriteTasks': favoriteTasks,
      'lastBackup': lastBackup,
      'isPureOffline': true,
      'engine': 'Hive NoSQL Engine v2.2.3',
    };
  }
}
