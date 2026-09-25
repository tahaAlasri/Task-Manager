import '../../domain/entities/subtask_entity.dart';
import '../../domain/entities/task_entity.dart';

/// نموذج البيانات الفعلي للمهمة في طبقة الـ Data
class TaskModel extends TaskEntity {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    required super.dueDate,
    required super.priority,
    required super.categoryId,
    super.isCompleted,
    super.isReminderEnabled,
    super.isFavorite,
    super.userId,
    super.subtasks,
    required super.createdAt,
    super.recurrenceType,
    super.recurrenceEndDate,
    super.isArchived,
    super.isDeleted,
    super.deletedAt,
    super.tags,
    super.reminderMinutesBefore,
    super.attachments,
    super.estimatedMinutes,
  });

  /// تحويل كائن TaskEntity إلى TaskModel
  factory TaskModel.fromEntity(TaskEntity entity) {
    return TaskModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      dueDate: entity.dueDate,
      priority: entity.priority,
      categoryId: entity.categoryId,
      isCompleted: entity.isCompleted,
      isReminderEnabled: entity.isReminderEnabled,
      isFavorite: entity.isFavorite,
      userId: entity.userId,
      subtasks: entity.subtasks,
      createdAt: entity.createdAt,
      recurrenceType: entity.recurrenceType,
      recurrenceEndDate: entity.recurrenceEndDate,
      isArchived: entity.isArchived,
      isDeleted: entity.isDeleted,
      deletedAt: entity.deletedAt,
      tags: entity.tags,
      reminderMinutesBefore: entity.reminderMinutesBefore,
      attachments: entity.attachments,
      estimatedMinutes: entity.estimatedMinutes,
    );
  }

  /// تحويل من Map (لقراءة البيانات المخزنة في Hive مع ضمان التوافق العكسي)
  factory TaskModel.fromMap(Map<dynamic, dynamic> map) {
    List<SubTaskEntity> parsedSubtasks = [];
    if (map['subtasks'] is List) {
      parsedSubtasks = (map['subtasks'] as List)
          .whereType<Map>()
          .map((item) => SubTaskEntity.fromMap(item))
          .toList();
    }

    List<String> parsedTags = [];
    if (map['tags'] is List) {
      parsedTags = List<String>.from(map['tags'] as List);
    }

    List<String> parsedAttachments = [];
    if (map['attachments'] is List) {
      parsedAttachments = List<String>.from(map['attachments'] as List);
    }

    return TaskModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      description: map['description'] as String?,
      dueDate: DateTime.tryParse(map['dueDate'] as String? ?? '') ?? DateTime.now(),
      priority: TaskPriority.fromString(map['priority'] as String?),
      categoryId: map['categoryId'] as String? ?? 'other',
      isCompleted: map['isCompleted'] as bool? ?? false,
      isReminderEnabled: map['isReminderEnabled'] as bool? ?? false,
      isFavorite: map['isFavorite'] as bool? ?? false,
      userId: map['userId'] as String?,
      subtasks: parsedSubtasks,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      recurrenceType: RecurrenceType.fromString(map['recurrenceType'] as String?),
      recurrenceEndDate: map['recurrenceEndDate'] != null
          ? DateTime.tryParse(map['recurrenceEndDate'] as String)
          : null,
      isArchived: map['isArchived'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      deletedAt: map['deletedAt'] != null
          ? DateTime.tryParse(map['deletedAt'] as String)
          : null,
      tags: parsedTags,
      reminderMinutesBefore: map['reminderMinutesBefore'] as int? ?? 0,
      attachments: parsedAttachments,
      estimatedMinutes: map['estimatedMinutes'] as int? ?? 0,
    );
  }

  /// تحويل إلى Map (للتخزين المحلي الفوري في Hive Box)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dueDate': dueDate.toIso8601String(),
      'priority': priority.name,
      'categoryId': categoryId,
      'isCompleted': isCompleted,
      'isReminderEnabled': isReminderEnabled,
      'isFavorite': isFavorite,
      'userId': userId,
      'subtasks': subtasks.map((s) => s.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'recurrenceType': recurrenceType.name,
      'recurrenceEndDate': recurrenceEndDate?.toIso8601String(),
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.toIso8601String(),
      'tags': tags,
      'reminderMinutesBefore': reminderMinutesBefore,
      'attachments': attachments,
      'estimatedMinutes': estimatedMinutes,
    };
  }

  /// ميثود نسخ وتعديل المهمة
  @override
  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    TaskPriority? priority,
    String? categoryId,
    bool? isCompleted,
    bool? isReminderEnabled,
    bool? isFavorite,
    String? userId,
    List<SubTaskEntity>? subtasks,
    DateTime? createdAt,
    RecurrenceType? recurrenceType,
    DateTime? recurrenceEndDate,
    bool clearRecurrenceEndDate = false,
    bool? isArchived,
    bool? isDeleted,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    List<String>? tags,
    int? reminderMinutesBefore,
    List<String>? attachments,
    int? estimatedMinutes,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      categoryId: categoryId ?? this.categoryId,
      isCompleted: isCompleted ?? this.isCompleted,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt ?? this.createdAt,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceEndDate: clearRecurrenceEndDate ? null : (recurrenceEndDate ?? this.recurrenceEndDate),
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      tags: tags ?? this.tags,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      attachments: attachments ?? this.attachments,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
