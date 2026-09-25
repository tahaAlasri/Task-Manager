import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/localization/locale_cubit.dart';
import '../../../../core/services/local_database_service.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../pomodoro/presentation/cubit/pomodoro_cubit.dart';
import '../../../pomodoro/presentation/cubit/pomodoro_state.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';
import '../../../tasks/presentation/screens/archive_screen.dart';
import '../../../tasks/presentation/screens/trash_screen.dart';
import '../../../tasks/presentation/widgets/category_manage_dialog.dart';
import '../../../tasks/presentation/widgets/permissions_dialog.dart';

/// شاشة الإعدادات المتكاملة، الملف الشخصي، وإدارة النسخ الاحتياطي
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const SettingsScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, dynamic> _dbStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await LocalDatabaseService.instance.getDatabaseStats();
    if (mounted) {
      setState(() {
        _dbStats = stats;
      });
    }
  }

  void _showEditProfileDialog(BuildContext context, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.manage_accounts_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('تعديل الملف الشخصي'),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'الاسم الكامل',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (val) =>
                    (val == null || val.trim().isEmpty) ? 'يرجى كتابة الاسم' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور الجديدة (اختياري)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                  hintText: 'اتركه فارغاً إذا كنت لا تريد التغيير',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                final newPass = passwordController.text.trim().isEmpty
                    ? null
                    : passwordController.text.trim();
                await context.read<AuthCubit>().updateProfile(
                      name: nameController.text.trim(),
                      newPassword: newPass,
                    );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم تحديث الملف الشخصي بنجاح ✅'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLocalBackup() async {
    final tasks = context.read<TaskCubit>().state.tasks;
    final success = await LocalDatabaseService.instance.createLocalBackup(tasks);
    await _loadStats();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success
              ? 'تم حفظ النسخة الاحتياطية بنجاح داخل قاعدة Hive 💾'
              : 'فشل إنشاء النسخة الاحتياطية'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLocalRestore() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('استعادة النسخة الاحتياطية'),
        content: const Text(
          'هل أنت متأكد من رغبتك في استعادة المهام من آخر نسخة احتياطية محفوظة محلياً؟ سيتم دمج وتحديث المهام الحالية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final taskCubit = context.read<TaskCubit>();
              final scaffold = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final count = await LocalDatabaseService.instance.restoreBackupToActiveBox();
              if (mounted) {
                if (count != null && count > 0) {
                  await taskCubit.loadTasks();
                  await _loadStats();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('تمت استعادة $count مهمة بنجاح 🚀'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('لم يتم العثور على نسخة احتياطية صالحة لاستعادتها'),
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
  }

  Future<void> _handleExportJson() async {
    final jsonStr = await LocalDatabaseService.instance.exportToJsonString();
    if (jsonStr == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر تصدير البيانات')),
        );
      }
      return;
    }

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.file_download_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('تصدير كملف JSON'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'تم تجهيز بياناتك بنجاح. يمكنك نسخ النص التالي وحفظه في أي مكان أو نقله لجهاز آخر:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              Container(
                height: 140,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    jsonStr,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم نسخ بيانات JSON إلى الحافظة بنجاح 📋'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('نسخ للحافظة'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleImportJson() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.file_upload_outlined, color: AppColors.secondary),
            SizedBox(width: 8),
            Text('استيراد مهام من JSON'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الصق كود JSON الذي قمت بنسخه مسبقاً لاستيراد المهام:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: '{"version": "1.0", "tasks": [...]}',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;

              final taskCubit = context.read<TaskCubit>();
              final scaffold = ScaffoldMessenger.of(context);
              Navigator.pop(ctx);
              final count = await LocalDatabaseService.instance.importFromJsonString(text);
              if (mounted) {
                if (count != null && count > 0) {
                  await taskCubit.loadTasks();
                  await _loadStats();
                  scaffold.showSnackBar(
                    SnackBar(
                      content: Text('تم استيراد $count مهمة بنجاح! 🚀'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  scaffold.showSnackBar(
                    const SnackBar(
                      content: Text('صيغة الـ JSON غير صالحة أو لا تحتوي على مهام'),
                      backgroundColor: AppColors.overdue,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, foregroundColor: Colors.white),
            child: const Text('استيراد'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟'),
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

  void _confirmDeleteAccount(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('حذف الحساب نهائياً'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في حذف الحساب نهائياً؟ سيتم مسح بيانات الحساب وجميع المهام المرتبطة به.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authCubit.deleteAccount();
              if (mounted) {
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('تم حذف الحساب وبياناته بنجاح ✅'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تأكيد الحذف'),
          ),
        ],
      ),
    );
  }

  void _confirmResetAppData(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final taskCubit = context.read<TaskCubit>();
    final scaffold = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.restart_alt_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('إعادة ضبط التطبيق'),
          ],
        ),
        content: const Text(
          'هل تريد إعادة التطبيق لحالته الأصلية تماماً كأول مرة يُفتح فيها؟ سيتم تصفير أي حسابات واستعادة المهام التمهيدية الافتراضية.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await authCubit.deleteAccount();
              final tasksBox = Hive.box(AppConstants.tasksBoxName);
              await tasksBox.clear();
              if (mounted) {
                await taskCubit.loadTasks();
                await _loadStats();
                scaffold.showSnackBar(
                  const SnackBar(
                    content: Text('تمت إعادة ضبط التطبيق بنجاح كأول تشغيل 🚀'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('إعادة الضبط الآن'),
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
        title: const Text(
          'الإعدادات والملف الشخصي',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isRealUser = authState.isAuthenticated &&
              authState.user != null &&
              !authState.user!.email.contains('injaz.local') &&
              !authState.user!.name.contains('إنجاز') &&
              !authState.user!.id.startsWith('guest');
          final user = isRealUser ? authState.user : null;

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            children: [
              // 1. بطاقة الملف الشخصي
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                        : [AppColors.primaryLight, Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: user != null
                          ? AppColors.primary
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      child: user != null
                          ? Text(
                              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                              style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : Icon(
                              Icons.phone_android_rounded,
                              color: isDark ? Colors.white70 : AppColors.primary,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.name ?? 'الوضع المحلي (بدون حساب)',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user != null ? user.email : 'يعمل 100% بدون إنترنت ولا يتطلب أي حساب',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (user != null)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: AppColors.primary),
                        onPressed: () => _showEditProfileDialog(context, user.name),
                        tooltip: 'تعديل الاسم أو كلمة المرور',
                      )
                    else
                      TextButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('دخول'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => LoginScreen(
                                onToggleTheme: widget.onToggleTheme,
                                isDarkMode: widget.isDarkMode,
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. إعدادات المظهر والوضع واللغة
              _buildSectionTitle('المظهر والتخصيص واللغة', isDark),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: Icon(
                        widget.isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                        color: AppColors.primary,
                      ),
                      title: const Text('الوضع الداكن (Dark Mode)'),
                      subtitle: Text(widget.isDarkMode ? 'مفعل' : 'معطل'),
                      value: widget.isDarkMode,
                      onChanged: (val) {
                        if (widget.onToggleTheme != null) {
                          widget.onToggleTheme!();
                        }
                      },
                    ),
                    const Divider(height: 1),
                    BlocBuilder<LocaleCubit, Locale>(
                      builder: (context, currentLocale) {
                        final isArabic = currentLocale.languageCode == 'ar';
                        return ListTile(
                          leading: const Icon(Icons.language_rounded, color: AppColors.primary),
                          title: const Text('لغة التطبيق / Application Language'),
                          subtitle: Text(isArabic ? 'العربية (Arabic)' : 'English (الإنجليزية)'),
                          trailing: DropdownButton<String>(
                            value: currentLocale.languageCode,
                            underline: const SizedBox(),
                            borderRadius: BorderRadius.circular(12),
                            items: const [
                              DropdownMenuItem(value: 'ar', child: Text('🇾🇪 العربية')),
                              DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                            ],
                            onChanged: (code) {
                              if (code != null) {
                                context.read<LocaleCubit>().setLocale(Locale(code));
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. إعدادات مؤقت التركيز (Pomodoro)
              _buildSectionTitle('مؤقت التركيز الذكي (Pomodoro)', isDark),
              BlocBuilder<PomodoroCubit, PomodoroState>(
                builder: (context, pomoState) {
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.timer_outlined, color: AppColors.secondary, size: 20),
                              SizedBox(width: 8),
                              Text('مدة جلسة التركيز (دقائق)', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [15, 25, 45, 50, 60].map((mins) {
                              final isSelected = pomoState.focusDurationMinutes == mins;
                              return ChoiceChip(
                                label: Text('$mins دقيقة'),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  context.read<PomodoroCubit>().updateDurations(
                                        focusMinutes: mins,
                                        shortBreakMinutes: pomoState.shortBreakMinutes,
                                        longBreakMinutes: pomoState.longBreakMinutes,
                                      );
                                },
                              );
                            }).toList(),
                          ),
                          const Divider(height: 24),
                          const Row(
                            children: [
                              Icon(Icons.coffee_outlined, color: Colors.orange, size: 20),
                              SizedBox(width: 8),
                              Text('مدة الاستراحة القصيرة', style: TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [3, 5, 10, 15].map((mins) {
                              final isSelected = pomoState.shortBreakMinutes == mins;
                              return ChoiceChip(
                                label: Text('$mins دقائق'),
                                selected: isSelected,
                                selectedColor: AppColors.secondary,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                                onSelected: (_) {
                                  context.read<PomodoroCubit>().updateDurations(
                                        focusMinutes: pomoState.focusDurationMinutes,
                                        shortBreakMinutes: mins,
                                        longBreakMinutes: pomoState.longBreakMinutes,
                                      );
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // إدارة المهام والتصنيفات
              _buildSectionTitle('إدارة المهام والتصنيفات 🗂️', isDark),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_rounded, color: AppColors.primary),
                      title: const Text('إدارة الفئات المخصصة'),
                      subtitle: const Text('إنشاء وتعديل وحذف تصنيفات المهام بألوان وأيقونات خاصة'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => CategoryManageDialog.show(context),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.archive_outlined, color: Colors.blueGrey),
                      title: const Text('أرشيف المهام'),
                      subtitle: const Text('عرض المهام المؤرشفة والرجوع إليها أو استعادتها'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ArchiveScreen()),
                      ),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.delete_sweep_outlined, color: AppColors.overdue),
                      title: const Text('سلة المهملات (Trash)'),
                      subtitle: const Text('استعادة المهام المحذوفة مؤقتاً أو إفراغ السلة'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TrashScreen()),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. مركز النسخ الاحتياطي وإدارة البيانات
              _buildSectionTitle('النسخ الاحتياطي واسترجاع البيانات 💾', isDark),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.save_rounded, color: AppColors.secondary),
                      title: const Text('إنشاء نسخة احتياطية محلية (Hive)'),
                      subtitle: const Text('حفظ لقطة فورية لجميع المهام داخل الجهاز بدون إنترنت'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: _handleLocalBackup,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.restore_rounded, color: AppColors.primary),
                      title: const Text('استعادة آخر نسخة احتياطية'),
                      subtitle: Text(
                        _dbStats['lastBackup'] != null
                            ? 'آخر نسخة: ${_formatBackupDate(_dbStats['lastBackup'])}'
                            : 'لا توجد نسخة محفوظة بعد',
                      ),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: _handleLocalRestore,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_download_outlined, color: Colors.teal),
                      title: const Text('تصدير كملف JSON'),
                      subtitle: const Text('تصدير المهام كنص للمشاركة أو النسخ الخارجي'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: _handleExportJson,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.file_upload_outlined, color: Colors.deepPurple),
                      title: const Text('استيراد من كود JSON'),
                      subtitle: const Text('لصق ملف مهام سابق واستعادته على هذا الجهاز'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: _handleImportJson,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. الأمان والأذونات
              _buildSectionTitle('الأمان ومركز الأذونات 🛡️', isDark),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.security_rounded, color: AppColors.primary),
                      title: const Text('مركز إدارة الأذونات'),
                      subtitle: const Text('فحص أذونات الإشعارات والبصمة والمنبه الدقيق'),
                      trailing: const Icon(Icons.chevron_left_rounded),
                      onTap: () => PermissionsDialog.show(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 6. بطاقة معلومات التطبيق
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.task_alt, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'تطبيق إنجاز | Injaz',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.completed.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'v1.0.0+1',
                            style: TextStyle(color: AppColors.completed, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'نظام إدارة مهام أوفلاين 100% مدعوم بمحرك Hive NoSQL المحلي',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 7. زر الحساب (تسجيل الدخول أو الخروج)
              if (user != null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(Icons.logout_rounded, color: AppColors.overdue),
                    label: const Text(
                      'تسجيل الخروج من الحساب',
                      style: TextStyle(color: AppColors.overdue, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.overdue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton.icon(
                    onPressed: () => _confirmDeleteAccount(context),
                    icon: const Icon(Icons.delete_forever_rounded, color: Colors.red),
                    label: const Text(
                      'حذف الحساب نهائياً مع كافة البيانات',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(
                            onToggleTheme: widget.onToggleTheme,
                            isDarkMode: widget.isDarkMode,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.login_rounded, color: Colors.white),
                    label: const Text(
                      'تسجيل الدخول / إنشاء حساب (اختياري)',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton.icon(
                    onPressed: () => _confirmResetAppData(context),
                    icon: const Icon(Icons.restart_alt_rounded, color: Colors.orange),
                    label: const Text(
                      'إعادة ضبط التطبيق والبيانات كأول تثبيت',
                      style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }

  String _formatBackupDate(dynamic date) {
    if (date is DateTime) {
      return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return date.toString();
  }
}
