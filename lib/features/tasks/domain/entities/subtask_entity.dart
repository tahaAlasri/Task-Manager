/// كائن المهمة الفرعية (Subtask) في طبقة الـ Domain
class SubTaskEntity {
  final String id;
  final String title;
  final bool isCompleted;

  const SubTaskEntity({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });

  SubTaskEntity copyWith({
    String? id,
    String? title,
    bool? isCompleted,
  }) {
    return SubTaskEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'isCompleted': isCompleted,
    };
  }

  factory SubTaskEntity.fromMap(Map<dynamic, dynamic> map) {
    return SubTaskEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SubTaskEntity &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          isCompleted == other.isCompleted;

  @override
  int get hashCode => id.hashCode ^ title.hashCode ^ isCompleted.hashCode;
}
