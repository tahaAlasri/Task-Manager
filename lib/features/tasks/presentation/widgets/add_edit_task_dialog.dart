import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/attachment_service.dart';
import '../../../../core/utils/date_helper.dart';
import '../../data/models/category_model.dart';
import '../../domain/entities/subtask_entity.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/category_cubit.dart';
import '../cubit/task_cubit.dart';
import 'category_manage_dialog.dart';
import 'image_viewer_dialog.dart';

/// نافذة سفلية (BottomSheet) لإضافة أو تعديل تفاصيل المهمة
class AddEditTaskBottomSheet extends StatefulWidget {
  final TaskEntity? taskToEdit;
  final Function(TaskEntity task) onSave;

  const AddEditTaskBottomSheet({
    super.key,
    this.taskToEdit,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    TaskEntity? taskToEdit,
    required Function(TaskEntity task) onSave,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddEditTaskBottomSheet(
        taskToEdit: taskToEdit,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddEditTaskBottomSheet> createState() => _AddEditTaskBottomSheetState();
}

class _AddEditTaskBottomSheetState extends State<AddEditTaskBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final TextEditingController _subtaskController = TextEditingController();
  late TextEditingController _estimatedTimeController;

  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  late String _selectedCategoryId;
  late bool _isReminderEnabled;
  late int _reminderMinutesBefore;
  late List<SubTaskEntity> _subtasks;
  late List<String> _tags;
  final TextEditingController _tagController = TextEditingController();
  late List<String> _attachments;
  late RecurrenceType _selectedRecurrenceType;
  DateTime? _recurrenceEndDate;

  @override
  void initState() {
    super.initState();
    final task = widget.taskToEdit;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _estimatedTimeController = TextEditingController(
      text: (task?.estimatedMinutes != null && task!.estimatedMinutes > 0)
          ? task.estimatedMinutes.toString()
          : '',
    );
    _subtasks = List<SubTaskEntity>.from(task?.subtasks ?? []);
    _tags = List<String>.from(task?.tags ?? []);
    _attachments = List<String>.from(task?.attachments ?? []);
    _reminderMinutesBefore = task?.reminderMinutesBefore ?? 0;

    if (task != null) {
      _selectedDate = task.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(task.dueDate);
      _selectedPriority = task.priority;
      _selectedCategoryId = task.categoryId;
      _isReminderEnabled = task.isReminderEnabled;
      _selectedRecurrenceType = task.recurrenceType;
      _recurrenceEndDate = task.recurrenceEndDate;
    } else {
      _selectedDate = DateTime.now().add(const Duration(hours: 2));
      _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
      _selectedPriority = TaskPriority.medium;
      _selectedCategoryId = CategoryModel.defaultCategories.first.id;
      _isReminderEnabled = true;
      _selectedRecurrenceType = RecurrenceType.none;
      _recurrenceEndDate = null;
    }
  }

  Future<void> _pickAttachment(bool fromCamera) async {
    final path = fromCamera
        ? await AttachmentService.instance.pickImageFromCamera()
        : await AttachmentService.instance.pickImageFromGallery();
    if (path != null && mounted) {
      setState(() => _attachments.add(path));
    }
  }

  void _removeAttachment(int index) {
    setState(() => _attachments.removeAt(index));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _subtaskController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addTag() {
    final text = _tagController.text.trim().replaceAll('#', '');
    if (text.isEmpty) return;
    if (!_tags.contains(text)) {
      setState(() {
        _tags.add(text);
        _tagController.clear();
      });
    } else {
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _addSubtask() {
    final text = _subtaskController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _subtasks.add(SubTaskEntity(
        id: const Uuid().v4(),
        title: text,
        isCompleted: false,
      ));
      _subtaskController.clear();
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks.removeWhere((s) => s.id == id);
    });
  }

  void _toggleSubtask(String id) {
    setState(() {
      final index = _subtasks.indexWhere((s) => s.id == id);
      if (index != -1) {
        _subtasks[index] = _subtasks[index].copyWith(
          isCompleted: !_subtasks[index].isCompleted,
        );
      }
    });
  }

  Future<void> _pickRecurrenceEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) {
      setState(() => _recurrenceEndDate = picked);
    }
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final dueDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final estimatedMins = int.tryParse(_estimatedTimeController.text.trim()) ?? 0;

      final task = TaskEntity(
        id: widget.taskToEdit?.id ?? const Uuid().v4(),
        title: _titleController.text.trim(),
        description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
        dueDate: dueDate,
        priority: _selectedPriority,
        categoryId: _selectedCategoryId,
        isCompleted: widget.taskToEdit?.isCompleted ?? false,
        isReminderEnabled: _isReminderEnabled,
        isFavorite: widget.taskToEdit?.isFavorite ?? false,
        userId: widget.taskToEdit?.userId ?? context.read<TaskCubit>().currentUserId,
        subtasks: _subtasks,
        createdAt: widget.taskToEdit?.createdAt ?? DateTime.now(),
        recurrenceType: _selectedRecurrenceType,
        isArchived: widget.taskToEdit?.isArchived ?? false,
        isDeleted: widget.taskToEdit?.isDeleted ?? false,
        deletedAt: widget.taskToEdit?.deletedAt,
        tags: _tags,
        reminderMinutesBefore: _isReminderEnabled ? _reminderMinutesBefore : 0,
        attachments: _attachments,
        estimatedMinutes: estimatedMins,
      );

      widget.onSave(task);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.taskToEdit != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // مقبض السحب (Drag handle)
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),

              // العنوان الرئيسي للنافذة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'تعديل المهمة' : 'إضافة مهمة جديدة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // حقل عنوان المهمة
              TextFormField(
                controller: _titleController,
                autofocus: !isEditing,
                decoration: InputDecoration(
                  hintText: 'ما الذي تخطط لإنجازه؟',
                  labelText: 'عنوان المهمة *',
                  prefixIcon: const Icon(Icons.title_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'يرجى إدخال عنوان المهمة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // حقل وصف المهمة
              TextFormField(
                controller: _descController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'ملاحظات إضافية أو تفاصيل (اختياري)',
                  labelText: 'الوصف',
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primary),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                ),
              ),
              const SizedBox(height: 16),

              // اختيار التصنيف (الفئة)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'التصنيف',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => CategoryManageDialog.show(context),
                    icon: const Icon(Icons.add_rounded, size: 16),
                    label: const Text('إدارة الفئات', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, catState) {
                  final categories = catState.categories;
                  return SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        final isSelected = _selectedCategoryId == cat.id;

                        return ChoiceChip(
                          selected: isSelected,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, size: 16, color: isSelected ? Colors.white : cat.color),
                              const SizedBox(width: 6),
                              Text(cat.nameAr),
                            ],
                          ),
                          selectedColor: cat.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategoryId = cat.id);
                            }
                          },
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // اختيار مستوى الأولوية
              Text(
                'مستوى الأولوية',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: TaskPriority.values.map((priority) {
                  final isSelected = _selectedPriority == priority;
                  Color priorityColor;
                  switch (priority) {
                    case TaskPriority.high:
                      priorityColor = AppColors.priorityHigh;
                      break;
                    case TaskPriority.medium:
                      priorityColor = AppColors.priorityMedium;
                      break;
                    case TaskPriority.low:
                      priorityColor = AppColors.priorityLow;
                      break;
                  }

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () => setState(() => _selectedPriority = priority),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? priorityColor : priorityColor.withAlpha(isDark ? 30 : 20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: priorityColor,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              priority.labelAr,
                              style: TextStyle(
                                color: isSelected ? Colors.white : priorityColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // حقل الوقت المتوقع للإنجاز (تقدير الوقت)
              TextFormField(
                controller: _estimatedTimeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'مثال: 30 (بالدقائق)',
                  labelText: 'الوقت المتوقع للإنجاز (بالدقائق - اختياري)',
                  prefixIcon: const Icon(Icons.timer_outlined, color: Colors.indigo),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // قائمة المهام الفرعية (Checklist)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'المهام الفرعية (قائمة التحقق)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (_subtasks.isNotEmpty)
                    Text(
                      '${_subtasks.where((s) => s.isCompleted).length}/${_subtasks.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // حقل إدخال مهمة فرعية جديدة
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subtaskController,
                      decoration: InputDecoration(
                        hintText: 'أضف خطوة فرعية أو بند إنجاز...',
                        isDense: true,
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _addSubtask(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSubtask,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    tooltip: 'إضافة بند',
                  ),
                ],
              ),
              if (_subtasks.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Column(
                    children: _subtasks.map((subtask) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => _toggleSubtask(subtask.id),
                              child: Icon(
                                subtask.isCompleted
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 20,
                                color: subtask.isCompleted ? AppColors.completed : Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                subtask.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  decoration: subtask.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                  color: subtask.isCompleted
                                      ? Colors.grey
                                      : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                              onPressed: () => _removeSubtask(subtask.id),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // اختيار التاريخ والوقت
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateHelper.formatSmartDate(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 18, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                DateHelper.formatTime(_selectedDate),
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // اختيار نمط تكرار المهمة
              Text(
                'تكرار المهمة 🔄',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: RecurrenceType.values.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final type = RecurrenceType.values[index];
                    final isSelected = _selectedRecurrenceType == type;
                    return ChoiceChip(
                      selected: isSelected,
                      label: Text(type.labelAr),
                      selectedColor: AppColors.secondary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedRecurrenceType = type;
                            if (type == RecurrenceType.none) {
                              _recurrenceEndDate = null;
                            }
                          });
                        }
                      },
                    );
                  },
                ),
              ),

              // حقل تاريخ انتهاء التكرار (يظهر فقط عند اختيار نمط تكرار)
              if (_selectedRecurrenceType != RecurrenceType.none) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickRecurrenceEndDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_repeat_rounded, size: 18, color: AppColors.secondary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _recurrenceEndDate != null
                                ? 'ينتهي التكرار: ${DateHelper.formatSmartDate(_recurrenceEndDate!)}'
                                : 'بدون تاريخ انتهاء (تكرار لا نهائي)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        if (_recurrenceEndDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                            onPressed: () => setState(() => _recurrenceEndDate = null),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // تفعيل التنبيه المحلي
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isReminderEnabled,
                activeThumbColor: AppColors.primary,
                title: const Text(
                  'تفعيل تذكير محلي بالموعد',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'إرسال إشعار على الجهاز في موعد استحقاق المهمة',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (val) => setState(() => _isReminderEnabled = val),
              ),
              if (_isReminderEnabled) ...[
                const SizedBox(height: 6),
                const Text(
                  'توقيت إرسال التنبيه:',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    {'mins': 0, 'label': 'في نفس الموعد'},
                    {'mins': 15, 'label': 'قبل 15 دقيقة'},
                    {'mins': 30, 'label': 'قبل 30 دقيقة'},
                    {'mins': 60, 'label': 'قبل ساعة'},
                    {'mins': 1440, 'label': 'قبل يوم'},
                  ].map((item) {
                    final mins = item['mins'] as int;
                    final isSelected = _reminderMinutesBefore == mins;
                    return ChoiceChip(
                      label: Text(item['label'] as String),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _reminderMinutesBefore = mins),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 16),

              // قسم الوسوم والكلمات الدلالية (Tags)
              Text(
                'الوسوم (#)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tagController,
                      decoration: InputDecoration(
                        hintText: 'أضف وسماً... (مثال: عاجل، تسوق)',
                        isDense: true,
                        prefixText: '# ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                        filled: true,
                        fillColor: isDark ? AppColors.darkCard : AppColors.lightBackground,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                        ),
                      ),
                      onSubmitted: (_) => _addTag(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addTag,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primaryLight,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                    tooltip: 'إضافة وسم',
                  ),
                ],
              ),
              if (_tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _tags.map((tag) {
                    return Chip(
                      label: Text('#$tag'),
                      deleteIcon: const Icon(Icons.close, size: 14),
                      onDeleted: () => _removeTag(tag),
                      backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    );
                  }).toList(),
                ),
              ],

              // قسم المرفقات والصور (Attachments)
              const SizedBox(height: 16),
              Text(
                'المرفقات والصور 📎',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _pickAttachment(false),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('المعرض'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => _pickAttachment(true),
                    icon: const Icon(Icons.camera_alt_outlined, size: 18),
                    label: const Text('الكاميرا'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
              if (_attachments.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _attachments.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final path = _attachments[index];
                      final file = File(path);
                      return Stack(
                        children: [
                          GestureDetector(
                            onTap: () => ImageViewerDialog.show(context, path),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: file.existsSync()
                                  ? Image.file(
                                      file,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 80,
                                      height: 80,
                                      color: Colors.grey.shade300,
                                      child: const Icon(Icons.broken_image),
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 2,
                            left: 2,
                            child: GestureDetector(
                              onTap: () => _removeAttachment(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // زر الحفظ
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  child: Text(
                    isEditing ? 'حفظ التعديلات' : 'إضافة المهمة الآن',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
