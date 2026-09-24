import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../tasks/presentation/screens/main_nav_screen.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onFinished;
  final VoidCallback? onToggleTheme;
  final bool isDarkMode;

  const OnboardingScreen({
    super.key,
    this.onFinished,
    this.onToggleTheme,
    this.isDarkMode = false,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = const [
    _OnboardingItem(
      title: 'نظم مهامك اليومية بدقة 📋',
      description: 'رتّب أهدافك اليومية، حدد الفئات ومستويات الأولوية، وتابع تقدم إنجازك خطوة بخطوة.',
      icon: Icons.checklist_rounded,
      gradient: [AppColors.primary, AppColors.secondary],
    ),
    _OnboardingItem(
      title: 'تنبيهات فورية ومتابعة ذكية ⏰',
      description: 'لا تفوّت أي موعد استحقاق مهم مع نظام الإشعارات والتذكيرات المجدولة على جهازك.',
      icon: Icons.notifications_active_rounded,
      gradient: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    ),
    _OnboardingItem(
      title: 'أمان وسرعة بالبصمة الحيوية 🔒',
      description: 'سجّل دخولك بلمسة واحدة عبر بصمة الإصبع أو التعرف على الوجه مع حفظ بياناتك بأمان تام.',
      icon: Icons.fingerprint_rounded,
      gradient: [Color(0xFF10B981), Color(0xFF06B6D4)],
    ),
  ];

  void _finishOnboarding({bool enterDirectly = true}) async {
    await context.read<AuthCubit>().completeOnboarding();
    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }
    if (!mounted) return;

    if (enterDirectly) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => MainNavScreen(
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) => LoginScreen(
            onToggleTheme: widget.onToggleTheme,
            isDarkMode: widget.isDarkMode,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding(enterDirectly: true);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // زر التخطي في الأعلى
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48), // لموازنة المكان
                  TextButton(
                    onPressed: () => _finishOnboarding(enterDirectly: true),
                    child: Text(
                      'تخطي',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // صفحات العرض
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // أيقونة بطابع عصري وتدرج لوني
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.gradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(38),
                            boxShadow: [
                              BoxShadow(
                                color: item.gradient.first.withAlpha(isDark ? 60 : 90),
                                blurRadius: 28,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Icon(
                            item.icon,
                            size: 70,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // العنوان
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // الوصف التوضيحي
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.6,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // مؤشرات الصفحات وزر المتابعة
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
              child: Column(
                children: [
                  // نقاط المؤشر
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _items.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppColors.primary
                              : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // زر التالي أو البدء
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      child: Text(
                        _currentPage == _items.length - 1 ? 'ابدأ رحلتك الآن 🚀' : 'التالي',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  if (_currentPage == _items.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => _finishOnboarding(enterDirectly: false),
                      child: Text(
                        'لديك حساب بالفعل؟ تسجيل الدخول',
                        style: TextStyle(
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingItem {
  final String title;
  final String description;
  final IconData icon;
  final List<Color> gradient;

  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
  });
}
