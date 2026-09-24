import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';
import '../../../tasks/presentation/cubit/task_state.dart';
import '../cubit/pomodoro_cubit.dart';
import '../cubit/pomodoro_state.dart';

class PomodoroFocusScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const PomodoroFocusScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  void _showBadgesDialog(BuildContext context, PomodoroState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('🏆 شارات وإنجازاتك'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildBadgeItem(
              icon: '🔥',
              title: 'شعلة الاستمرار',
              desc: 'أنجزت مهام لمدة 3 أيام متتالية!',
              unlocked: true,
            ),
            const SizedBox(height: 12),
            _buildBadgeItem(
              icon: '🎯',
              title: 'سيد التركيز',
              desc: 'أكمل 4 جلسات بومودورو مركزة',
              unlocked: state.completedSessions >= 4,
            ),
            const SizedBox(height: 12),
            _buildBadgeItem(
              icon: '👑',
              title: 'بطل الإنتاجية',
              desc: 'الوصول إلى 500 نقطة خبرة (XP)',
              unlocked: state.xpPoints >= 500,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  static Widget _buildBadgeItem({
    required String icon,
    required String title,
    required String desc,
    required bool unlocked,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: unlocked ? Colors.amber.withAlpha(25) : Colors.grey.withAlpha(20),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: unlocked ? Colors.amber : Colors.grey.shade400,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: unlocked ? Colors.black87 : Colors.grey,
                  ),
                ),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (unlocked)
            const Icon(Icons.check_circle_rounded, color: Colors.amber, size: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BlocBuilder<PomodoroCubit, PomodoroState>(
      builder: (context, state) {
        Color activeColor;
        switch (state.mode) {
          case PomodoroMode.focus:
            activeColor = AppColors.primary;
            break;
          case PomodoroMode.shortBreak:
            activeColor = AppColors.secondary;
            break;
          case PomodoroMode.longBreak:
            activeColor = AppColors.completed;
            break;
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [activeColor, activeColor.withAlpha(180)]),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.timer_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  'وضع التركيز الذكي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
            actions: [
              // زر شارات الإنجاز
              IconButton(
                icon: const Icon(Icons.military_tech_rounded, color: Colors.amber),
                onPressed: () => _showBadgesDialog(context, state),
                tooltip: 'شارة الإنجاز',
              ),
              if (onToggleTheme != null)
                IconButton(
                  icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  onPressed: onToggleTheme,
                  tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              children: [
                // 1. بطاقة نقاط الخبرة وسلسلة الإنجاز (Gamification Bar)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [const Color(0xFF1F2937), const Color(0xFF111827)]
                          : [Colors.white, const Color(0xFFF1F5F9)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.streakDays} أيام متتالية',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const Text('سلسلة الإنجاز', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      Container(width: 1, height: 28, color: Colors.grey.withAlpha(60)),
                      Row(
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${state.xpPoints} XP',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                              ),
                              Text(state.levelTitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. أزرار اختيار النمط (تركيز، استراحة قصيرة، استراحة طويلة)
                Row(
                  children: PomodoroMode.values.map((mode) {
                    final isSelected = state.mode == mode;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () => context.read<PomodoroCubit>().switchMode(mode),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? activeColor
                                  : (isDark ? AppColors.darkCard : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? activeColor : Colors.grey.withAlpha(50),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                mode.labelAr,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white70 : Colors.black87),
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 36),

                // 3. المؤقت الدائري الكبير
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 250,
                        height: 250,
                        child: CircularProgressIndicator(
                          value: state.progress,
                          strokeWidth: 14,
                          backgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(activeColor),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.formattedTime,
                            style: TextStyle(
                              fontSize: 54,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: activeColor.withAlpha(30),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              state.isRunning ? 'الجلسة قيد التشغيل ⏳' : 'جاهز للبدء ✨',
                              style: TextStyle(
                                color: activeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // 4. أزرار التحكم (تشغيل / إيقاف / إعادة ضبط)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filledTonal(
                      iconSize: 26,
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => context.read<PomodoroCubit>().resetTimer(),
                      tooltip: 'إعادة الضبط',
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (state.isRunning) {
                          context.read<PomodoroCubit>().pauseTimer();
                        } else {
                          context.read<PomodoroCubit>().startTimer();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: activeColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 4,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(state.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            state.isRunning ? 'إيقاف مؤقت' : 'ابدأ الجلسة',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // 5. ربط المؤقت بمهمة معينة
                BlocBuilder<TaskCubit, TaskState>(
                  builder: (context, taskState) {
                    final pendingTasks = taskState.tasks.where((t) => !t.isCompleted).toList();

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.link_rounded, size: 18, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text(
                                'ربط جلسة التركيز بمهمة محددة',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (pendingTasks.isEmpty)
                            const Text(
                              'لا توجد مهام قيد التنفيذ حالياً، أنشئ مهمة جديدة لربطها بالجلسة',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            )
                          else
                            DropdownButtonFormField<String>(
                              initialValue: state.selectedTaskId,
                              decoration: InputDecoration(
                                hintText: 'اختر مهمة للتركيز عليها...',
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: pendingTasks.map((t) {
                                return DropdownMenuItem<String>(
                                  value: t.id,
                                  child: Text(
                                    t.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                );
                              }).toList(),
                              onChanged: (taskId) => context.read<PomodoroCubit>().bindTask(taskId),
                            ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 6. ملخص الجلسات اليومية المكتملة
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: activeColor.withAlpha(isDark ? 25 : 15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'جلسات التركيز المكتملة اليوم:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      Text(
                        '${state.completedSessions} جلسات 🎯',
                        style: TextStyle(
                          color: activeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }
}
