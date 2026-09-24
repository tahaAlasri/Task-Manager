import '../../../../core/utils/date_helper.dart';
import '../../domain/entities/task_entity.dart';

/// حالات فلترة المهام
enum TaskFilterStatus {
  all,
  today,
  completed,
  overdue;

  String get labelAr {
    switch (this) {
      case TaskFilterStatus.all:
        return 'الكل';
      case TaskFilterStatus.today:
        return 'اليوم';
      case TaskFilterStatus.completed:
        return 'المكتملة';
      case TaskFilterStatus.overdue:
        return 'المؤجلة';
    }
  }

  String get labelEn {
    switch (this) {
      case TaskFilterStatus.all:
        return 'All';
      case TaskFilterStatus.today:
        return 'Today';
      case TaskFilterStatus.completed:
        return 'Completed';
      case TaskFilterStatus.overdue:
        return 'Overdue';
    }
  }
}

/// خيارات ترتيب وفرز المهام
enum TaskSortOption {
  dueDateAsc,
  dueDateDesc,
  priorityDesc,
  titleAsc;

  String get labelAr {
    switch (this) {
      case TaskSortOption.dueDateAsc:
        return 'الأقرب موعداً ⏳';
      case TaskSortOption.dueDateDesc:
        return 'الأبعد موعداً 📅';
      case TaskSortOption.priorityDesc:
        return 'الأولوية (الأعلى أولاً) ⚡';
      case TaskSortOption.titleAsc:
        return 'الأبجدية (أ - ي) 🔤';
    }
  }
}

enum TaskStateStatus { initial, loading, success, failure }

/// حالة شاشة المهام المتكاملة
class TaskState {
  final TaskStateStatus status;
  final List<TaskEntity> tasks;
  final TaskFilterStatus filterStatus;
  final TaskSortOption sortOption;
  final String selectedCategoryId;
  final TaskPriority? selectedPriority;
  final String searchQuery;
  final String? errorMessage;

  const TaskState({
    this.status = TaskStateStatus.initial,
    this.tasks = const [],
    this.filterStatus = TaskFilterStatus.all,
    this.sortOption = TaskSortOption.dueDateAsc,
    this.selectedCategoryId = 'all',
    this.selectedPriority,
    this.searchQuery = '',
    this.errorMessage,
  });

  /// المهام المفلترة والمرتبة حسب البحث والتصنيف والأولوية والفرز
  List<TaskEntity> get filteredTasks {
    final list = tasks.where((task) {
      // فلترة بالبحث
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.trim().toLowerCase();
        final matchesTitle = task.title.toLowerCase().contains(query);
        final matchesDesc = task.description?.toLowerCase().contains(query) ?? false;
        if (!matchesTitle && !matchesDesc) return false;
      }

      // فلترة بالفئة
      if (selectedCategoryId != 'all' && task.categoryId != selectedCategoryId) {
        return false;
      }

      // فلترة بمستوى الأولوية المحدد
      if (selectedPriority != null && task.priority != selectedPriority) {
        return false;
      }

      // فلترة بحالة المهمة
      switch (filterStatus) {
        case TaskFilterStatus.all:
          return true;
        case TaskFilterStatus.today:
          return DateHelper.isToday(task.dueDate);
        case TaskFilterStatus.completed:
          return task.isCompleted;
        case TaskFilterStatus.overdue:
          return DateHelper.isOverdue(task.dueDate, isCompleted: task.isCompleted);
      }
    }).toList();

    // فرز المهام حسب خيار الترتيب المحدد
    switch (sortOption) {
      case TaskSortOption.dueDateAsc:
        list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
        break;
      case TaskSortOption.dueDateDesc:
        list.sort((a, b) => b.dueDate.compareTo(a.dueDate));
        break;
      case TaskSortOption.priorityDesc:
        const priorityRank = {
          TaskPriority.high: 0,
          TaskPriority.medium: 1,
          TaskPriority.low: 2,
        };
        list.sort((a, b) => (priorityRank[a.priority] ?? 2).compareTo(priorityRank[b.priority] ?? 2));
        break;
      case TaskSortOption.titleAsc:
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
    }

    return list;
  }

  // إحصائيات سريعة
  int get totalCount => tasks.length;
  int get completedCount => tasks.where((t) => t.isCompleted).length;
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;
  int get favoriteCount => tasks.where((t) => t.isFavorite).length;
  double get completionRatio => totalCount == 0 ? 0.0 : (completedCount / totalCount);

  /// قائمة المهام المفضلة
  List<TaskEntity> get favoriteTasks => tasks.where((t) => t.isFavorite).toList();

  TaskState copyWith({
    TaskStateStatus? status,
    List<TaskEntity>? tasks,
    TaskFilterStatus? filterStatus,
    TaskSortOption? sortOption,
    String? selectedCategoryId,
    TaskPriority? selectedPriority,
    bool clearPriorityFilter = false,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TaskState(
      status: status ?? this.status,
      tasks: tasks ?? this.tasks,
      filterStatus: filterStatus ?? this.filterStatus,
      sortOption: sortOption ?? this.sortOption,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedPriority: clearPriorityFilter ? null : (selectedPriority ?? this.selectedPriority),
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
