import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/task_entity.dart';
import '../cubit/category_cubit.dart';
import '../cubit/task_cubit.dart';
import '../../data/models/category_model.dart';

/// شاشة سلة المهملات لإدارة المهام المحذوفة مؤقتاً واستعادتها أو حذفها نهائياً
class TrashScreen extends StatefulWidget {
  const TrashScreen({super.key});

  @override
  State<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends State<TrashScreen> {
  List<TaskEntity> _deletedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeletedTasks();
  }

  Future<void> _loadDeletedTasks() async {
    setState(() => _isLoading = true);
    final tasks = await context.read<TaskCubit>().getDeletedTasks();
    if (mounted) {
      setState(() {
        _deletedTasks = tasks;
        _isLoading = false;
      });
    }
  }

  void _restoreTask(TaskEntity task) async {
    await context.read<TaskCubit>().restoreTask(task.id);
    await _loadDeletedTasks();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت استعادة المهمة "${task.title}" بنجاح ♻️'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmPermanentDelete(TaskEntity task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('حذف نهائي'),
        content: Text('هل أنت متأكد من رغبتك في حذف المهمة "${task.title}" نهائياً؟ لا يمكن التراجع عن هذا الإجراء.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TaskCubit>().permanentDeleteTask(task.id);
              await _loadDeletedTasks();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم الحذف النهائي للمهمة'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
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

  void _confirmEmptyTrash() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.overdue),
            SizedBox(width: 8),
            Text('تفريغ سلة المهملات'),
          ],
        ),
        content: const Text('سيتم حذف جميع المهام الموجودة في السلة نهائياً وبلا رجعة. هل تريد الاستمرار؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<TaskCubit>().emptyTrash();
              await _loadDeletedTasks();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تفريغ سلة المهملات بالكامل 🗑️'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.overdue,
              foregroundColor: Colors.white,
            ),
            child: const Text('تفريغ الكل'),
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
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppColors.overdue),
            SizedBox(width: 8),
            Text('سلة المهملات', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          if (_deletedTasks.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: AppColors.overdue),
              tooltip: 'تفريغ سلة المهملات',
              onPressed: _confirmEmptyTrash,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deletedTasks.isEmpty
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
                          Icons.delete_outline_rounded,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'سلة المهملات فارغة ✨',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'المهام التي تقوم بحذفها تنتقل إلى هنا أولاً لحمايتها من الفقدان',
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
                      itemCount: _deletedTasks.length,
                      itemBuilder: (context, index) {
                        final task = _deletedTasks[index];
                        final category = CategoryModel.findById(task.categoryId, customCategories: catState.categories);
                        final deletedDateStr = task.deletedAt != null
                            ? DateFormat('yyyy/MM/dd - hh:mm a', 'ar').format(task.deletedAt!)
                            : null;

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
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (deletedDateStr != null)
                                      Text(
                                        'حُذفت: $deletedDateStr',
                                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () => _restoreTask(task),
                                          icon: const Icon(Icons.restore_from_trash_rounded, size: 18),
                                          label: const Text('استعادة'),
                                          style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_forever_rounded, size: 20, color: AppColors.overdue),
                                          onPressed: () => _confirmPermanentDelete(task),
                                          tooltip: 'حذف نهائي',
                                        ),
                                      ],
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
