import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/category_cubit.dart';

/// نافذة منبثقة لإدارة الفئات المخصصة وإضافة فئة جديدة
class CategoryManageDialog extends StatefulWidget {
  const CategoryManageDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const CategoryManageDialog(),
    );
  }

  @override
  State<CategoryManageDialog> createState() => _CategoryManageDialogState();
}

class _CategoryManageDialogState extends State<CategoryManageDialog> {
  final TextEditingController _nameController = TextEditingController();
  Color _selectedColor = const Color(0xFF6366F1); // Indigo
  IconData _selectedIcon = Icons.folder_outlined;
  bool _isCreating = false;

  final List<Color> _palette = const [
    Color(0xFF6366F1), // Indigo
    Color(0xFFEC4899), // Pink
    Color(0xFF10B981), // Emerald
    Color(0xFFF59E0B), // Amber
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEF4444), // Red
    Color(0xFF3B82F6), // Blue
  ];

  final List<IconData> _iconList = const [
    Icons.folder_outlined,
    Icons.shopping_bag_outlined,
    Icons.home_outlined,
    Icons.laptop_chromebook_outlined,
    Icons.favorite_outline_rounded,
    Icons.flight_takeoff_rounded,
    Icons.palette_outlined,
    Icons.music_note_outlined,
    Icons.menu_book_rounded,
    Icons.fitness_center_rounded,
    Icons.local_cafe_outlined,
    Icons.star_outline_rounded,
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveNewCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى كتابة اسم الفئة')),
      );
      return;
    }

    await context.read<CategoryCubit>().addCategory(
          name: name,
          icon: _selectedIcon,
          color: _selectedColor,
        );

    _nameController.clear();
    setState(() => _isCreating = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تمت إضافة فئة "$name" بنجاح 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.category_rounded, color: AppColors.primary),
              SizedBox(width: 8),
              Text('إدارة الفئات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          IconButton(
            icon: Icon(_isCreating ? Icons.close_rounded : Icons.add_circle_outline_rounded,
                color: AppColors.primary),
            tooltip: _isCreating ? 'إلغاء الإضافة' : 'إضافة فئة جديدة',
            onPressed: () => setState(() => _isCreating = !_isCreating),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isCreating) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightBackground,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('اسم الفئة الجديدة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'مثال: تسوق، كتب، عائلة...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('اختر اللون:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _palette.map((color) {
                          final isSelected = _selectedColor == color;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColor = color),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected ? Border.all(color: Colors.white, width: 2.5) : null,
                                boxShadow: isSelected
                                    ? [BoxShadow(color: color.withAlpha(150), blurRadius: 6, spreadRadius: 1)]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Text('اختر الأيقونة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _iconList.map((icon) {
                          final isSelected = _selectedIcon == icon;
                          return GestureDetector(
                            onTap: () => setState(() => _selectedIcon = icon),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? _selectedColor.withAlpha(40) : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(10),
                                border: isSelected ? Border.all(color: _selectedColor, width: 1.5) : null,
                              ),
                              child: Icon(icon, size: 20, color: isSelected ? _selectedColor : (isDark ? Colors.white70 : Colors.black87)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saveNewCategory,
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('حفظ الفئة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _selectedColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const Text('الفئات الحالية:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              BlocBuilder<CategoryCubit, CategoryState>(
                builder: (context, state) {
                  return Column(
                    children: state.categories.map((cat) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: cat.color.withAlpha(35),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(cat.icon, size: 18, color: cat.color),
                        ),
                        title: Text(cat.nameAr, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(cat.isCustom ? 'فئة مخصصة' : 'فئة افتراضية', style: const TextStyle(fontSize: 11)),
                        trailing: cat.isCustom
                            ? IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.overdue),
                                tooltip: 'حذف الفئة',
                                onPressed: () async {
                                  await context.read<CategoryCubit>().deleteCategory(cat.id);
                                },
                              )
                            : null,
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}
