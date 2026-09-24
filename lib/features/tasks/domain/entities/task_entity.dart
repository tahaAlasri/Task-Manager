import 'subtask_entity.dart';

/// أنماط تكرار المهمة
enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  monthly;

  String get labelAr {
    switch (this) {
      case RecurrenceType.none:
        return 'لا يتكرر';
      case RecurrenceType.daily:
        return 'يومياً';
      case RecurrenceType.weekdays:
        return 'أيام العمل';
      case RecurrenceType.weekly:
        return 'أسبوعياً';
      case RecurrenceType.monthly:
        return 'شهرياً';
    }
  }

  String get labelEn {
    switch (this) {
      case RecurrenceType.none:
        return 'None';
      case RecurrenceType.daily:
        return 'Daily';
      case RecurrenceType.weekdays:
        return 'Weekdays';
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
    }
  }

  static RecurrenceType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'daily':
        return RecurrenceType.daily;
      case 'weekdays':
        return RecurrenceType.weekdays;
      case 'weekly':
        return RecurrenceType.weekly;
      case 'monthly':
        return RecurrenceType.monthly;
      case 'none':
      default:
        return RecurrenceType.none;
    }
  }
}

/// مستويات أولوية المهمة
enum TaskPriority {
  low,
  medium,
  high;

  String get labelAr {
    switch (this) {
      case TaskPriority.high:
        return 'عالية';
      case TaskPriority.medium:
        return 'متوسطة';
      case TaskPriority.low:
        return 'منخفضة';
    }
  }

  String get labelEn {
    switch (this) {
      case TaskPriority.high:
        return 'High';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.low:
        return 'Low';
    }
  }

  static TaskPriority fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'high':
        return TaskPriority.high;
      case 'medium':
        return TaskPriority.medium;
      case 'low':
      default:
        return TaskPriority.low;
    }
  }
}

/// كائن المهمة المجرد في طبقة الـ Domain
class TaskEntity {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final TaskPriority priority;
  final String categoryId;
  final bool isCompleted;
  final bool isReminderEnabled;
  final bool isFavorite;
  final String? userId;
  final List<SubTaskEntity> subtasks;
  final DateTime createdAt;
  final RecurrenceType recurrenceType;
  final DateTime? recurrenceEndDate;

  // الحقول الجديدة للمرحلة 2: الأرشفة وسلة المحذوفات والوسوم والتنبيه المسبق
  final bool isArchived;
  final bool isDeleted;
  final DateTime? deletedAt;
  final List<String> tags;
  final int reminderMinutesBefore; // 0 = في الوقت، 15 = قبل ربع ساعة، 60 = قبل ساعة، إلخ
  final List<String> attachments; // مسارات الصور والمرفقات المحفوظة محلياً

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.priority,
    required this.categoryId,
    this.isCompleted = false,
    this.isReminderEnabled = false,
    this.isFavorite = false,
    this.userId,
    this.subtasks = const [],
    required this.createdAt,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceEndDate,
    this.isArchived = false,
    this.isDeleted = false,
    this.deletedAt,
    this.tags = const [],
    this.reminderMinutesBefore = 0,
    this.attachments = const [],
  });

  int get subtasksCount => subtasks.length;
  int get completedSubtasksCount => subtasks.where((s) => s.isCompleted).length;
  double get subtasksProgress =>
      subtasksCount == 0 ? 0.0 : completedSubtasksCount / subtasksCount;

  /// هل المهمة متكررة؟
  bool get isRecurring => recurrenceType != RecurrenceType.none;

  TaskEntity copyWith({
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
    bool? isArchived,
    bool? isDeleted,
    DateTime? deletedAt,
    List<String>? tags,
    int? reminderMinutesBefore,
    List<String>? attachments,
  }) {
    return TaskEntity(
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
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      tags: tags ?? this.tags,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      attachments: attachments ?? this.attachments,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          dueDate == other.dueDate &&
          priority == other.priority &&
          categoryId == other.categoryId &&
          isCompleted == other.isCompleted &&
          isReminderEnabled == other.isReminderEnabled &&
          isFavorite == other.isFavorite &&
          userId == other.userId &&
          createdAt == other.createdAt &&
          recurrenceType == other.recurrenceType &&
          recurrenceEndDate == other.recurrenceEndDate &&
          isArchived == other.isArchived &&
          isDeleted == other.isDeleted &&
          deletedAt == other.deletedAt &&
          reminderMinutesBefore == other.reminderMinutesBefore &&
          attachments == other.attachments;

  @override
  int get hashCode =>
      id.hashCode ^
      title.hashCode ^
      description.hashCode ^
      dueDate.hashCode ^
      priority.hashCode ^
      categoryId.hashCode ^
      isCompleted.hashCode ^
      isReminderEnabled.hashCode ^
      isFavorite.hashCode ^
      userId.hashCode ^
      createdAt.hashCode ^
      recurrenceType.hashCode ^
      recurrenceEndDate.hashCode ^
      isArchived.hashCode ^
      isDeleted.hashCode ^
      deletedAt.hashCode ^
      reminderMinutesBefore.hashCode ^
      attachments.hashCode;
}
