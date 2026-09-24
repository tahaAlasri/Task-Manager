import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/task_cubit.dart';
import '../cubit/task_state.dart';
import '../widgets/add_edit_task_dialog.dart';
import '../widgets/empty_tasks_view.dart';
import '../widgets/task_card.dart';

class FavoritesScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const FavoritesScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
              context.read<TaskCubit>().deleteTask(task.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('تم حذف المهمة'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
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
                  colors: [Colors.amber, Colors.orange],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.star_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'المهام المفضلة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          if (widget.onToggleTheme != null)
            IconButton(
              icon: Icon(
                widget.isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              ),
              onPressed: widget.onToggleTheme,
              tooltip: widget.isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            ),
        ],
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, state) {
          final allFavorites = state.favoriteTasks;
          final filteredFavorites = allFavorites.where((task) {
            if (_searchQuery.isEmpty) return true;
            final q = _searchQuery.trim().toLowerCase();
            return task.title.toLowerCase().contains(q) ||
                (task.description?.toLowerCase().contains(q) ?? false);
          }).toList();

          return CustomScrollView(
            slivers: [
              // بطاقة ترحيب وإحصائيات المفضلة
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF78350F), const Color(0xFF451A03)]
                            : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withAlpha(isDark ? 40 : 60),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'قائمتك الذهبية ⭐',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'المهام ذات الأولوية القصوى والأهمية الخاصة لديك',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(220),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(50),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${allFavorites.length} مهمة',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // حقل البحث في المفضلة إذا كانت تحتوي عناصر
              if (allFavorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'ابحث في المهام المفضلة...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Colors.amber),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
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

              // قائمة المهام المفضلة أو العرض الفارغ
              if (filteredFavorites.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyTasksView(
                    icon: Icons.star_border_rounded,
                    title: allFavorites.isEmpty
                        ? 'لا توجد مهام مفضلة حتى الآن'
                        : 'لا توجد نتائج بحث مطابقة',
                    subtitle: allFavorites.isEmpty
                        ? 'انقر على رمز النجمة ⭐ بجانب أي مهمة لإضافتها إلى قائمتك المفضلة هنا'
                        : 'جرّب البحث بكلمات أخرى',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredFavorites[index];
                        return Dismissible(
                          key: ValueKey('dismiss_fav_${task.id}'),
                          direction: DismissDirection.horizontal,
                          confirmDismiss: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              context.read<TaskCubit>().toggleTaskStatus(task.id);
                              return false;
                            } else if (direction == DismissDirection.endToStart) {
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
                            onDelete: () => _confirmDeleteTask(task),
                          ),
                        );
                      },
                      childCount: filteredFavorites.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
