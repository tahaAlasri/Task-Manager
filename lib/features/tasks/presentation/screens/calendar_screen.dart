import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_helper.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/add_edit_task_dialog.dart';
import '../widgets/empty_tasks_view.dart';
import '../widgets/task_card.dart';

/// شاشة التقويم التفاعلية لعرض وتوزيع المهام على مدار الشهر والأسبوع
class CalendarScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const CalendarScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<TaskEntity> _getTasksForDay(DateTime day, List<TaskEntity> allTasks) {
    return allTasks.where((task) => _isSameDay(task.dueDate, day)).toList();
  }

  void _openAddTaskForSelectedDay() {
    AddEditTaskBottomSheet.show(
      context,
      onSave: (newTask) {
        context.read<TaskCubit>().addTask(newTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المهمة لليوم المحدد بنجاح 📅'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _openEditTaskSheet(TaskEntity task) {
    AddEditTaskBottomSheet.show(
      context,
      taskToEdit: task,
      onSave: (updatedTask) {
        context.read<TaskCubit>().updateTask(updatedTask);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'تقويم المهام',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // زر الانتقال إلى اليوم الحالي
          IconButton(
            icon: const Icon(Icons.today_rounded),
            tooltip: 'الانتقال إلى اليوم',
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
            },
          ),
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                widget.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: widget.onToggleTheme,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTaskForSelectedDay,
        icon: const Icon(Icons.add_rounded),
        label: const Text('مهمة لهذا اليوم', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          final allTasks = state.tasks;
          final selectedDayTasks = _getTasksForDay(_selectedDay, allTasks);

          return Column(
            children: [
              // بطاقة التقويم التفاعلي بتصميم عصري
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 30 : 10),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TableCalendar<TaskEntity>(
                  firstDay: DateTime.now().subtract(const Duration(days: 365)),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  startingDayOfWeek: StartingDayOfWeek.saturday,
                  selectedDayPredicate: (day) => _isSameDay(_selectedDay, day),
                  eventLoader: (day) => _getTasksForDay(day, allTasks),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: true,
                    titleCentered: true,
                    formatButtonShowsNext: false,
                    formatButtonDecoration: BoxDecoration(
                      color: isDark ? AppColors.primary.withAlpha(50) : AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    formatButtonTextStyle: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    titleTextStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    // اليوم المحدد
                    selectedDecoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    // اليوم الحالي
                    todayDecoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(60),
                      shape: BoxShape.circle,
                    ),
                    todayTextStyle: TextStyle(
                      color: isDark ? Colors.white : AppColors.primaryDark,
                      fontWeight: FontWeight.bold,
                    ),
                    markersMaxCount: 3,
                    markerSize: 6,
                    markerDecoration: const BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                      if (events.isEmpty) return null;
                      final hasPendingHighPriority = events.any(
                        (t) => !t.isCompleted && t.priority == TaskPriority.high,
                      );
                      final allCompleted = events.every((t) => t.isCompleted);

                      Color markerColor;
                      if (allCompleted) {
                        markerColor = AppColors.completed;
                      } else if (hasPendingHighPriority) {
                        markerColor = AppColors.priorityHigh;
                      } else {
                        markerColor = AppColors.primary;
                      }

                      return Positioned(
                        bottom: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: markerColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            if (events.length > 1) ...[
                              const SizedBox(width: 2),
                              Container(
                                width: 4,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: markerColor.withAlpha(150),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    setState(() {
                      _calendarFormat = format;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                ),
              ),

              // شريط تفاصيل اليوم المحدد
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.event_note_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          DateHelper.formatSmartDate(_selectedDay),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selectedDayTasks.isEmpty
                            ? Colors.grey.withAlpha(30)
                            : AppColors.primary.withAlpha(isDark ? 40 : 25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${selectedDayTasks.length} مهام',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: selectedDayTasks.isEmpty ? Colors.grey : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // قائمة مهام اليوم المحدد
              Expanded(
                child: selectedDayTasks.isEmpty
                    ? Center(
                        child: EmptyTasksView(
                          title: 'لا توجد مهام لهذا اليوم 🎉',
                          subtitle: 'يمكنك إضافة مهمة مجدولة لهذا التاريخ بالنقر على الزر بالأسفل',
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: selectedDayTasks.length,
                        itemBuilder: (context, index) {
                          final task = selectedDayTasks[index];
                          return TaskCard(
                            key: ValueKey('cal_${task.id}'),
                            task: task,
                            onToggle: () => context.read<TaskCubit>().toggleTaskStatus(task.id),
                            onToggleFavorite: () => context.read<TaskCubit>().toggleFavorite(task.id),
                            onEdit: () => _openEditTaskSheet(task),
                            onDelete: () => context.read<TaskCubit>().deleteTask(task.id),
                            onArchive: () => context.read<TaskCubit>().archiveTask(task.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
