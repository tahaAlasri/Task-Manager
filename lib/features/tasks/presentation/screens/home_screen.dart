import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/local_database_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../cubit/category_cubit.dart';
import '../widgets/add_edit_task_dialog.dart';
import '../widgets/category_manage_dialog.dart';
import '../widgets/empty_tasks_view.dart';
import '../widgets/permissions_dialog.dart';
import '../widgets/task_card.dart';
import 'archive_screen.dart';
import 'trash_screen.dart';

/// الشاشة الرئيسية لعرض وإدارة المهام اليومية
class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const HomeScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // تحميل المهام المناسبة للمستخدم الحالي عند بدء الشاشة
    final authState = context.read<AuthCubit>().state;
    final taskCubit = context.read<TaskCubit>();
    if (authState.isAuthenticated && authState.user != null && taskCubit.currentUserId != authState.user!.id) {
      taskCubit.setCurrentUser(authState.user!.id);
    } else {
      taskCubit.loadTasks();
    }

    // ربط callback المهام المتكررة لعرض SnackBar
    taskCubit.onRecurringTaskCreated = (message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.repeat_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(message)),
              ],
            ),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    };
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddTaskSheet() {
    AddEditTaskBottomSheet.show(
      context,
      onSave: (newTask) {
        context.read<TaskCubit>().addTask(newTask);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تمت إضافة المهمة بنجاح'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث المهمة بنجاح'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  void _confirmDeleteTask(TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف المهمة'),
        content: Text('هل أنت متأكد من رغبتك في حذف المهمة "${task.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              final deletedTask = task;
              context.read<TaskCubit>().deleteTask(task.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('تم حذف المهمة "${deletedTask.title}"'),
                  duration: const Duration(seconds: 4),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'تراجع ↩️',
                    textColor: Colors.amber,
                    onPressed: () {
                      context.read<TaskCubit>().addTask(deletedTask);
                    },
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
              foregroundColor: Colors.white,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCompleted() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف المهام المكتملة'),
        content: const Text('هل تريد إزالة جميع المهام المكتملة دفعة واحدة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              context.read<TaskCubit>().deleteCompletedTasks();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف جميع المهام المكتملة'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _archiveTask(TaskEntity task) {
    context.read<TaskCubit>().archiveTask(task.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نقل المهمة "${task.title}" إلى الأرشيف 📦'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'تراجع ↩️',
          textColor: Colors.amber,
          onPressed: () {
            context.read<TaskCubit>().unarchiveTask(task.id);
          },
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من الحساب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
              foregroundColor: Colors.white,
            ),
            child: const Text('خروج'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'إنجاز | مهامي',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          // زر تبديل الوضع الداكن / الفاتح إن كان متوفراً
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                widget.isDarkMode
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: widget.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            ),

          // قائمة الخيارات الإضافية
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            onSelected: (val) async {
              if (val == 'categories') {
                CategoryManageDialog.show(context);
              } else if (val == 'archive') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ArchiveScreen()),
                );
              } else if (val == 'trash') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TrashScreen()),
                );
              } else if (val == 'permissions') {
                PermissionsDialog.show(context);
              } else if (val == 'local_backup') {
                final tasks = context.read<TaskCubit>().state.tasks;
                final success = await LocalDatabaseService.instance.createLocalBackup(tasks);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            success ? Icons.save_rounded : Icons.error_outline_rounded,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(success
                                ? 'تم النسخ الاحتياطي في قاعدة بيانات Hive المحلية بنجاح 💾 (بدون إنترنت)'
                                : 'تعذر حفظ النسخة الاحتياطية المحلية'),
                          ),
                        ],
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } else if (val == 'local_restore') {
                showDialog(
                  context: context,
                  builder: (dialogCtx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    title: const Text('استعادة النسخة الاحتياطية'),
                    content: const Text(
                      'هل أنت متأكد من استعادة المهام من آخر نسخة احتياطية محلية؟',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogCtx),
                        child: const Text('إلغاء'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final taskCubit = context.read<TaskCubit>();
                          final scaffold = ScaffoldMessenger.of(context);
                          Navigator.pop(dialogCtx);
                          final count = await LocalDatabaseService.instance.restoreBackupToActiveBox();
                          if (context.mounted) {
                            if (count != null && count > 0) {
                              await taskCubit.loadTasks();
                              scaffold.showSnackBar(
                                SnackBar(
                                  content: Text('تمت استعادة $count مهمة بنجاح 🚀'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              scaffold.showSnackBar(
                                const SnackBar(
                                  content: Text('لم يتم العثور على نسخة احتياطية صالحة'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('تأكيد الاستعادة'),
                      ),
                    ],
                  ),
                );
              } else if (val == 'clear_completed') {
                _confirmDeleteCompleted();
              } else if (val == 'logout') {
                _confirmLogout();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'categories',
                child: Row(
                  children: [
                    Icon(Icons.category_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('إدارة الفئات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'archive',
                child: Row(
                  children: [
                    Icon(Icons.archive_outlined, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 8),
                    Text('الأرشيف'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'trash',
                child: Row(
                  children: [
                    Icon(Icons.delete_sweep_outlined, size: 18, color: AppColors.overdue),
                    SizedBox(width: 8),
                    Text('سلة المهملات'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'permissions',
                child: Row(
                  children: [
                    Icon(Icons.security_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('مركز الأذونات'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'local_backup',
                child: Row(
                  children: [
                    Icon(Icons.save_rounded, size: 18, color: AppColors.secondary),
                    SizedBox(width: 8),
                    Text('نسخ احتياطي محلي (Hive)'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'local_restore',
                child: Row(
                  children: [
                    Icon(Icons.restore_rounded, size: 18, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text('استعادة نسخة احتياطية'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'clear_completed',
                child: Row(
                  children: [
                    Icon(Icons.cleaning_services_rounded, size: 18, color: AppColors.overdue),
                    SizedBox(width: 8),
                    Text('حذف المكتملة'),
                  ],
                ),
              ),
              if (context.read<AuthCubit>().state.isAuthenticated)
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout_rounded, size: 18, color: AppColors.overdue),
                      SizedBox(width: 8),
                      Text('تسجيل الخروج'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddTaskSheet,
        icon: const Icon(Icons.add_rounded, size: 22),
        label: const Text(
          'مهمة جديدة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          if (state.status == TaskStateStatus.loading && state.tasks.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredTasks = state.filteredTasks;

          return CustomScrollView(
            slivers: [
              // 1. بطاقة ملخص الإنجاز والتقدم (Stats Card)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF312E81), const Color(0xFF1E1B4B)]
                            : [AppColors.primary, const Color(0xFF4F46E5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(isDark ? 50 : 60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'إنجازاتك اليوم ✨',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withAlpha(40),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(state.completionRatio * 100).toInt()}% مكتمل',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: state.completionRatio,
                            minHeight: 8,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('المهام الكلية', '${state.totalCount}'),
                            _buildStatItem('قيد الإنجاز', '${state.pendingCount}'),
                            _buildStatItem('المكتملة', '${state.completedCount}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. شريط البحث السريع
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) => context.read<TaskCubit>().setSearchQuery(query),
                    decoration: InputDecoration(
                      hintText: 'ابحث عن مهمة بالاسم أو الوصف...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                context.read<TaskCubit>().setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDark ? AppColors.darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // شريط الفرز واختيار الأولوية
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      PopupMenuButton<TaskSortOption>(
                        tooltip: 'فرز المهام',
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        onSelected: (option) => context.read<TaskCubit>().setSortOption(option),
                        itemBuilder: (ctx) => TaskSortOption.values.map((option) {
                          final isSelected = state.sortOption == option;
                          return PopupMenuItem(
                            value: option,
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isSelected ? AppColors.primary : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  option.labelAr,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                    color: isSelected ? AppColors.primary : null,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.sort_rounded, size: 16, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text(
                                state.sortOption.labelAr.split(' ').first,
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const Icon(Icons.arrow_drop_down_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: TaskPriority.values.map((p) {
                              final isSelected = state.selectedPriority == p;
                              Color pColor;
                              switch (p) {
                                case TaskPriority.high:
                                  pColor = AppColors.priorityHigh;
                                  break;
                                case TaskPriority.medium:
                                  pColor = AppColors.priorityMedium;
                                  break;
                                case TaskPriority.low:
                                  pColor = AppColors.priorityLow;
                                  break;
                              }
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Text(p.labelAr),
                                  selectedColor: pColor.withAlpha(40),
                                  checkmarkColor: pColor,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: isSelected ? pColor : (isDark ? Colors.white70 : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (_) => context.read<TaskCubit>().setSelectedPriority(p),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. أزرار تصفية الحالة (الكل، اليوم، المكتملة، المؤجلة)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TaskFilterStatus.values.map((filter) {
                        final isSelected = state.filterStatus == filter;
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: FilterChip(
                            selected: isSelected,
                            label: Text(filter.labelAr),
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (_) =>
                                context.read<TaskCubit>().setFilterStatus(filter),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

              // 4. أزرار الفئات (التصنيفات: عمل، شخصي، دراسة، صحة... والفئات المخصصة)
              SliverToBoxAdapter(
                child: BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, catState) {
                    final categories = catState.categories;
                    return Padding(
                      padding: const EdgeInsets.only(right: 16, top: 4, bottom: 12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // خيار "جميع الفئات"
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ChoiceChip(
                                selected: state.selectedCategoryId == 'all',
                                label: const Text('جميع الفئات'),
                                selectedColor: isDark ? AppColors.primaryLight.withAlpha(40) : AppColors.primaryLight,
                                labelStyle: TextStyle(
                                  color: state.selectedCategoryId == 'all'
                                      ? AppColors.primary
                                      : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: state.selectedCategoryId == 'all'
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (_) =>
                                    context.read<TaskCubit>().setSelectedCategory('all'),
                              ),
                            ),
                            // بقية الفئات (الافتراضية + المخصصة)
                            ...categories.map((cat) {
                              final isSelected = state.selectedCategoryId == cat.id;
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(cat.icon, size: 15, color: isSelected ? Colors.white : cat.color),
                                      const SizedBox(width: 6),
                                      Text(cat.nameAr),
                                    ],
                                  ),
                                  selectedColor: cat.color,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark ? Colors.white70 : Colors.black87),
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  onSelected: (_) =>
                                      context.read<TaskCubit>().setSelectedCategory(cat.id),
                                ),
                              );
                            }),
                            // زر إدارة أو إضافة فئة
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: ActionChip(
                                avatar: const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                                label: const Text('فئة جديدة'),
                                onPressed: () => CategoryManageDialog.show(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 5. قائمة المهام أو العرض الفارغ
              if (filteredTasks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyTasksView(
                    title: state.searchQuery.isNotEmpty
                        ? 'لم يتم العثور على نتائج'
                        : 'لا توجد مهام في هذا التصنيف',
                    subtitle: state.searchQuery.isNotEmpty
                        ? 'جرّب البحث بكلمة أخرى أو تعديل خيارات التصفية'
                        : 'انقر على زر "مهمة جديدة" بالأسفل لبدء إنجازك',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredTasks[index];
                        return Dismissible(
                          key: ValueKey('dismiss_${task.id}'),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              // السحب لليمين → تبديل حالة الإنجاز
                              context.read<TaskCubit>().toggleTaskStatus(task.id);
                              return false; // لا نُزيل العنصر بصرياً
                            } else if (direction == DismissDirection.endToStart) {
                              // السحب لليسار → حذف مع تراجع
                              final deletedTask = task;
                              context.read<TaskCubit>().deleteTask(task.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('تم حذف المهمة "${deletedTask.title}"'),
                                  duration: const Duration(seconds: 4),
                                  behavior: SnackBarBehavior.floating,
                                  action: SnackBarAction(
                                    label: 'تراجع ↩️',
                                    textColor: Colors.amber,
                                    onPressed: () {
                                      context.read<TaskCubit>().addTask(deletedTask);
                                    },
                                  ),
                                ),
                              );
                              return false;
                            }
                            return false;
                          },
                          background: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.completed,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'إنجاز',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          secondaryBackground: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.overdue,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'حذف',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                              ],
                            ),
                          ),
                          child: TaskCard(
                            key: ValueKey(task.id),
                            task: task,
                            onToggle: () => context.read<TaskCubit>().toggleTaskStatus(task.id),
                            onToggleFavorite: () => context.read<TaskCubit>().toggleFavorite(task.id),
                            onEdit: () => _openEditTaskSheet(task),
                            onArchive: () => _archiveTask(task),
                            onDelete: () => _confirmDeleteTask(task),
                          ),
                        );
                      },
                      childCount: filteredTasks.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
