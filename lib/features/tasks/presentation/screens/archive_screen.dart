import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/category_cubit.dart';
import '../cubit/task_cubit.dart';
import '../../data/models/category_model.dart';

/// شاشة الأرشيف لعرض المهام المؤرشفة وإمكانية إلغاء أرشفتها أو نقلها للسلة
class ArchiveScreen extends StatefulWidget {
  const ArchiveScreen({super.key});

  @override
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  List<TaskEntity> _archivedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArchivedTasks();
  }

  Future<void> _loadArchivedTasks() async {
    setState(() => _isLoading = true);
    final tasks = await context.read<TaskCubit>().getArchivedTasks();
    if (mounted) {
      setState(() {
        _archivedTasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _unarchiveTask(TaskEntity task) async {
    await context.read<TaskCubit>().unarchiveTask(task.id);
    await _loadArchivedTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إعادة "${task.title}" إلى قائمة المهام النشطة 📂'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _moveToTrash(TaskEntity task) async {
    await context.read<TaskCubit>().softDeleteTask(task.id);
    await _loadArchivedTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم نقل المهمة لسلة المهملات 🗑️'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.archive_outlined, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('الأرشيف', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _archivedTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.grey.shade800 : Colors.grey.shade200).withAlpha(120),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'لا توجد مهام مؤرشفة 🗄️',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'يمكنك أرشفة المهام القديمة لحفظها بعيداً عن القائمة الرئيسية دون حذفها',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : BlocBuilder<CategoryCubit, CategoryState>(
                  builder: (context, catState) {
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: _archivedTasks.length,
                      itemBuilder: (context, index) {
                        final task = _archivedTasks[index];
                        final category = CategoryModel.findById(task.categoryId, customCategories: catState.categories);

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: category.color.withAlpha(35),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(category.icon, size: 16, color: category.color),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        task.title,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withAlpha(30),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'مؤرشفة',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                if (task.description != null && task.description!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    task.description!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _unarchiveTask(task),
                                      icon: const Icon(Icons.unarchive_rounded, size: 18),
                                      label: const Text('إلغاء الأرشفة'),
                                      style: TextButton.styleFrom(foregroundColor: AppColors.secondary),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.overdue),
                                      onPressed: () => _moveToTrash(task),
                                      tooltip: 'نقل للمهملات',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
}
