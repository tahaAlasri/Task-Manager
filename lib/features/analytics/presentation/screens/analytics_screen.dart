import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pomodoro/presentation/cubit/pomodoro_cubit.dart';
import '../../../pomodoro/presentation/cubit/pomodoro_state.dart';
import '../../../tasks/data/models/category_model.dart';
import '../../../tasks/domain/entities/task_entity.dart';
import '../../../tasks/presentation/cubit/category_cubit.dart';
import '../../../tasks/presentation/cubit/task_cubit.dart';
import '../../../tasks/presentation/cubit/task_state.dart';

/// شاشة لوحة تحليلات الإنتاجية والرسوم البيانية المتقدمة
class AnalyticsScreen extends StatelessWidget {
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const AnalyticsScreen({
    super.key,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.insights_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text(
              'لوحة الإنتاجية والتحليلات',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          if (onToggleTheme != null)
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
              onPressed: onToggleTheme,
              tooltip: isDarkMode ? 'الوضع الفاتح' : 'الوضع الداكن',
            ),
        ],
      ),
      body: BlocBuilder<TaskCubit, TaskState>(
        builder: (context, taskState) {
          return BlocBuilder<PomodoroCubit, PomodoroState>(
            builder: (context, pomoState) {
              final tasks = taskState.tasks;
              final totalTasks = tasks.length;
              final completedTasks = tasks.where((t) => t.isCompleted).length;
              final completionRate =
                  totalTasks > 0 ? ((completedTasks / totalTasks) * 100).round() : 0;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. بطاقات المؤشرات الرقمية السريعة (KPIs)
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            isDark: isDark,
                            icon: Icons.check_circle_rounded,
                            iconColor: AppColors.completed,
                            title: 'نسبة الإنجاز',
                            value: '$completionRate%',
                            subtitle: '$completedTasks من $totalTasks مهمة',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            isDark: isDark,
                            icon: Icons.local_fire_department_rounded,
                            iconColor: Colors.deepOrange,
                            title: 'سلسلة الأيام',
                            value: '${pomoState.streakDays} أيام',
                            subtitle: 'استمرارية رائعة! 🔥',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            isDark: isDark,
                            icon: Icons.timer_rounded,
                            iconColor: AppColors.primary,
                            title: 'جلسات التركيز',
                            value: '${pomoState.completedSessions}',
                            subtitle: '${pomoState.completedSessions * pomoState.focusDurationMinutes} دقيقة تركيز',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            isDark: isDark,
                            icon: Icons.military_tech_rounded,
                            iconColor: Colors.amber,
                            title: 'نقاط الخبرة XP',
                            value: '${pomoState.xpPoints}',
                            subtitle: pomoState.levelTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // 2. الرسم البياني لمعدل إنجاز الأسبوع (Bar Chart)
                    _buildWeeklyBarChartSection(context, isDark, tasks),
                    const SizedBox(height: 24),

                    // 3. الرسم البياني لتوزيع المهام حسب التصنيف (Donut Pie Chart)
                    _buildCategoryPieChartSection(context, isDark, tasks),
                    const SizedBox(height: 24),

                    // 4. نظام الشارات والإنجازات (Gamification)
                    _buildBadgesSection(isDark, completedTasks, pomoState),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  static Widget _buildMetricCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha(25),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChartSection(BuildContext context, bool isDark, List<TaskEntity> tasks) {
    // حساب المهام المكتملة في آخر 7 أيام
    final now = DateTime.now();
    final List<int> dailyCompleted = List.filled(7, 0);
    final List<String> dayLabels = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      dayLabels.add(_getDayNameAr(date.weekday));
      final count = tasks.where((t) {
        return t.isCompleted &&
            t.dueDate.year == date.year &&
            t.dueDate.month == date.month &&
            t.dueDate.day == date.day;
      }).length;
      dailyCompleted[6 - i] = count;
    }

    final maxVal = dailyCompleted.reduce((a, b) => a > b ? a : b);
    final maxScale = maxVal < 5 ? 5 : maxVal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'المهام المنجزة خلال آخر 7 أيام',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                final count = dailyCompleted[index];
                final heightFactor = maxScale > 0 ? (count / maxScale) : 0.0;
                final isToday = index == 6;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          count > 0 ? '$count' : '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isToday ? AppColors.primary : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              heightFactor: heightFactor.clamp(0.06, 1.0),
                              child: Container(
                                width: 18,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: count > 0
                                        ? [
                                            AppColors.primary,
                                            isToday ? AppColors.secondary : AppColors.primary.withAlpha(180)
                                          ]
                                        : [Colors.grey.withAlpha(50), Colors.grey.withAlpha(30)],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dayLabels[index],
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            color: isToday
                                ? AppColors.primary
                                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPieChartSection(BuildContext context, bool isDark, List<TaskEntity> tasks) {
    final catList = context.watch<CategoryCubit?>()?.state.categories;

    final Map<String, int> counts = {};
    for (final t in tasks) {
      counts[t.categoryId] = (counts[t.categoryId] ?? 0) + 1;
    }

    if (counts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
        child: const Center(
          child: Text('لا توجد مهام حالية لتوزيع التصنيفات'),
        ),
      );
    }

    final total = tasks.length;
    final List<_CategorySlice> slices = [];
    final List<Widget> legends = [];

    counts.forEach((catId, count) {
      final category = CategoryModel.findById(catId, customCategories: catList);
      final pct = ((count / total) * 100).round();
      slices.add(_CategorySlice(color: category.color, percentage: count / total));

      legends.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${category.nameAr} ($count)',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_rounded, color: AppColors.secondary, size: 20),
              SizedBox(width: 8),
              Text(
                'توزيع المهام حسب التصنيف',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 4,
                child: Center(
                  child: SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          size: const Size(140, 140),
                          painter: _DonutChartPainter(slices: slices),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$total',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'مهمة',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: legends,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(bool isDark, int completedTasks, PomodoroState pomoState) {
    final badges = [
      {
        'icon': '🌱',
        'title': 'أول خطوة',
        'desc': 'إكمال أول مهمة في التطبيق',
        'unlocked': completedTasks >= 1,
      },
      {
        'icon': '🎯',
        'title': 'قناص الأهداف',
        'desc': 'إنجاز 10 مهام بنجاح',
        'unlocked': completedTasks >= 10,
      },
      {
        'icon': '🔥',
        'title': 'شعلة الاستمرار',
        'desc': 'الحفاظ على سلسلة 3 أيام متتالية',
        'unlocked': pomoState.streakDays >= 3,
      },
      {
        'icon': '⚡',
        'title': 'محارب التركيز',
        'desc': 'إكمال 5 جلسات بومودورو',
        'unlocked': pomoState.completedSessions >= 5,
      },
      {
        'icon': '👑',
        'title': 'خبير الإتقان',
        'desc': 'الوصول إلى 500 XP في إنجاز',
        'unlocked': pomoState.xpPoints >= 500,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'أوسمة وشارات الإنتاجية',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...badges.map((b) {
            final unlocked = b['unlocked'] as bool;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: unlocked ? Colors.amber.withAlpha(20) : Colors.grey.withAlpha(15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: unlocked ? Colors.amber.withAlpha(120) : Colors.grey.withAlpha(40),
                ),
              ),
              child: Row(
                children: [
                  Text(b['icon'] as String, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          b['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: unlocked ? null : Colors.grey,
                          ),
                        ),
                        Text(
                          b['desc'] as String,
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                    color: unlocked ? Colors.amber : Colors.grey,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _getDayNameAr(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }
}

class _CategorySlice {
  final Color color;
  final double percentage;

  _CategorySlice({required this.color, required this.percentage});
}

class _DonutChartPainter extends CustomPainter {
  final List<_CategorySlice> slices;

  _DonutChartPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 18.0;

    double startAngle = -math.pi / 2;

    for (final slice in slices) {
      final sweepAngle = slice.percentage * 2 * math.pi;
      final paint = Paint()
        ..color = slice.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2)),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) =>
      oldDelegate.slices != slices;
}
