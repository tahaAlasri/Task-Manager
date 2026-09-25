import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection_container.dart';
import 'core/localization/locale_cubit.dart';
import 'core/services/local_database_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/pomodoro/presentation/cubit/pomodoro_cubit.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/domain/entities/task_entity.dart';
import 'features/tasks/presentation/cubit/category_cubit.dart';
import 'features/tasks/presentation/cubit/task_cubit.dart';
import 'features/tasks/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. تهيئة قاعدة البيانات المحلية Hive
  await Hive.initFlutter();

  // 2. إعداد وحقن التبعيات (GetIt Service Locator)
  await initDependencies();

  final tasksBox = sl<Box>(instanceName: AppConstants.tasksBoxName);

  // 3. زرع مهام تمهيدية توضيحية عند أول تشغيل فقط
  if (tasksBox.isEmpty) {
    await _seedInitialTasks(tasksBox);
  }

  // 4. تهيئة خدمة التنبيهات المحلية
  await sl<INotificationService>().initialize();
  await sl<INotificationService>().requestPermissions();

  // 5. صيانة دورية لضغط صناديق البيانات المحلية
  await sl<LocalDatabaseService>().compactAllBoxes();

  runApp(const MyApp());
}

/// إضافة بيانات توضيحية لتعريف المستخدم بميزات التطبيق عند الفتح لأول مرة
Future<void> _seedInitialTasks(Box box) async {
  const uuid = Uuid();
  final now = DateTime.now();

  final initialTasks = [
    TaskModel(
      id: uuid.v4(),
      title: 'مرحباً بك في منظم المهام اليومية! 🚀',
      description: 'انقر على الدائرة لتحديد المهمة كمكتملة، أو اضغط مطولاً للتعديل.',
      dueDate: now.add(const Duration(hours: 3)),
      priority: TaskPriority.high,
      categoryId: 'personal',
      isCompleted: false,
      isReminderEnabled: true,
      isFavorite: true,
      createdAt: now,
    ),
    TaskModel(
      id: uuid.v4(),
      title: 'مراجعة خطة العمل للمشروع الجديد 📊',
      description: 'الاطلاع على المتطلبات الفنية وتوزيع المهام على الفريق.',
      dueDate: now.add(const Duration(hours: 6)),
      priority: TaskPriority.medium,
      categoryId: 'work',
      isCompleted: false,
      isReminderEnabled: false,
      isFavorite: true,
      createdAt: now,
    ),
    TaskModel(
      id: uuid.v4(),
      title: 'قراءة فصل من كتاب البرمجة النظيفة 📖',
      description: 'تطبيق Clean Architecture في Flutter.',
      dueDate: now.add(const Duration(days: 1)),
      priority: TaskPriority.low,
      categoryId: 'study',
      isCompleted: true,
      isReminderEnabled: false,
      isFavorite: false,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    TaskModel(
      id: uuid.v4(),
      title: 'ممارسة الرياضة الصباحية 🏃‍♂️',
      description: 'مهمة تتكرر يومياً تلقائياً بمجرد إنجازها.',
      dueDate: now.add(const Duration(hours: 1)),
      priority: TaskPriority.medium,
      categoryId: 'fitness',
      isCompleted: false,
      isReminderEnabled: true,
      isFavorite: false,
      recurrenceType: RecurrenceType.daily,
      createdAt: now,
    ),
  ];

  for (final task in initialTasks) {
    await box.put(task.id, task.toMap());
  }
}

/// التطبيق الرئيسي وإدارة الثيم والمصادقة واللغة وحالة التطبيق عبر Cubit
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => sl<ThemeCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<LocaleCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<TaskCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<AuthCubit>()..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) => sl<PomodoroCubit>(),
        ),
        BlocProvider(
          create: (context) => sl<CategoryCubit>(),
        ),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          final isDark = themeMode == ThemeMode.dark;
          void toggleTheme() {
            context.read<ThemeCubit>().toggleTheme(
              platformBrightness: MediaQuery.maybeOf(context)?.platformBrightness,
            );
          }

          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, currentLocale) {
              return MaterialApp(
                title: 'إنجاز | Injaz',
                debugShowCheckedModeBanner: false,

                // إعدادات المظهر الفاتح والداكن (Material 3)
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,

                // دعم اللغات (العربية والإنجليزية)
                locale: currentLocale,
                supportedLocales: const [
                  Locale('ar'),
                  Locale('en'),
                ],
                localizationsDelegates: const [
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // الشاشة التمهيدية للانطلاق
                home: SplashScreen(
                  onToggleTheme: toggleTheme,
                  isDarkMode: isDark,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
