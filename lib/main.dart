import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import 'core/constants/app_constants.dart';
import 'core/services/local_database_service.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/pomodoro/presentation/cubit/pomodoro_cubit.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/tasks/data/datasources/task_local_data_source.dart';
import 'features/tasks/data/models/task_model.dart';
import 'features/tasks/data/repositories/task_repository_impl.dart';
import 'features/tasks/domain/entities/task_entity.dart';
import 'features/tasks/domain/repositories/task_repository.dart';
import 'features/tasks/presentation/cubit/category_cubit.dart';
import 'features/tasks/presentation/cubit/task_cubit.dart';
import 'features/tasks/presentation/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة قاعدة البيانات المحلية Hive وفتح الصناديق الأساسية
  await Hive.initFlutter();
  final tasksBox = await Hive.openBox(AppConstants.tasksBoxName);
  final settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
  final authBox = await Hive.openBox(AppConstants.authBoxName);
  await Hive.openBox(AppConstants.categoriesBoxName);
  await Hive.openBox(PomodoroCubit.boxName);

  // مسح وحذف أي حساب مؤقت ومستخدم "مستخدم إنجاز" (offline@injaz.local) وبياناته كلياً ليعود التطبيق كأول تثبيت نظيف
  final currentUserData = authBox.get(AppConstants.keyCurrentUser);
  bool shouldPurgeDummyUser = false;
  if (currentUserData is Map) {
    final email = currentUserData['email']?.toString().toLowerCase() ?? '';
    final name = currentUserData['name']?.toString() ?? '';
    final id = currentUserData['id']?.toString() ?? '';
    if (email.contains('injaz.local') || name.contains('إنجاز') || id.startsWith('guest')) {
      shouldPurgeDummyUser = true;
    }
  }

  if (shouldPurgeDummyUser) {
    await authBox.delete(AppConstants.keyCurrentUser);
    await authBox.put(AppConstants.keyIsLoggedIn, false);

    // مسح مفاتيح الحساب التجريبي من صندوق المصادقة
    final authKeysToDelete = <dynamic>[];
    for (var key in authBox.keys) {
      final keyStr = key.toString().toLowerCase();
      if (keyStr.contains('injaz.local') || keyStr.contains('guest')) {
        authKeysToDelete.add(key);
      }
    }
    for (var k in authKeysToDelete) {
      await authBox.delete(k);
    }

    // مسح أي مهام كانت مرتبطة بهذا المستخدم
    final taskKeysToDelete = <dynamic>[];
    for (var key in tasksBox.keys) {
      final taskData = tasksBox.get(key);
      if (taskData is Map) {
        final taskUserId = taskData['userId']?.toString() ?? '';
        if (taskUserId.startsWith('guest_') || taskUserId.contains('injaz.local')) {
          taskKeysToDelete.add(key);
        }
      }
    }
    for (var k in taskKeysToDelete) {
      await tasksBox.delete(k);
    }
  }

  // زرع مهام تمهيدية افتراضية بدون حساب في حالة أول تشغيل أو بعد مسح بيانات المستخدم القديمة
  if (tasksBox.isEmpty) {
    await _seedInitialTasks(tasksBox);
  }

  // تهيئة خدمة الإشعارات المحلية
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // صيانة وتحسين قاعدة البيانات المحلية (Hive)
  await LocalDatabaseService.instance.compactAllBoxes();

  // إعداد طبقات Clean Architecture للمهام والمصادقة
  final localDataSource = TaskLocalDataSourceImpl(box: tasksBox);
  final taskRepository = TaskRepositoryImpl(localDataSource: localDataSource);

  final authLocalDataSource = AuthLocalDataSourceImpl(authBox: authBox, settingsBox: settingsBox);
  final authRepository = AuthRepositoryImpl(localDataSource: authLocalDataSource);

  runApp(MyApp(
    taskRepository: taskRepository,
    authRepository: authRepository,
    settingsBox: settingsBox,
  ));
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

/// التطبيق الرئيسي وإدارة الثيم والمصادقة وحالة التطبيق عبر Cubit
class MyApp extends StatelessWidget {
  final TaskRepository taskRepository;
  final AuthRepository authRepository;
  final Box settingsBox;

  const MyApp({
    super.key,
    required this.taskRepository,
    required this.authRepository,
    required this.settingsBox,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ThemeCubit(settingsBox: settingsBox),
        ),
        BlocProvider(
          create: (context) => TaskCubit(repository: taskRepository),
        ),
        BlocProvider(
          create: (context) => AuthCubit(repository: authRepository)..checkAuthStatus(),
        ),
        BlocProvider(
          create: (context) => PomodoroCubit(),
        ),
        BlocProvider(
          create: (context) => CategoryCubit(),
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

          return MaterialApp(
            title: 'إنجاز | Injaz',
            debugShowCheckedModeBanner: false,

            // إعدادات المظهر الفاتح والداكن (Material 3)
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeMode,

            // دعم اللغة العربية والاتجاه من اليمين لليسار (RTL)
            locale: const Locale('ar'),
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
      ),
    );
  }
}
