import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';
import '../localization/locale_cubit.dart';
import '../services/ambient_audio_service.dart';
import '../services/attachment_service.dart';
import '../services/biometric_service.dart';
import '../services/local_database_service.dart';
import '../services/notification_service.dart';
import '../theme/theme_cubit.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/pomodoro/presentation/cubit/pomodoro_cubit.dart';
import '../../features/tasks/data/datasources/task_local_data_source.dart';
import '../../features/tasks/data/repositories/task_repository_impl.dart';
import '../../features/tasks/domain/repositories/task_repository.dart';
import '../../features/tasks/presentation/cubit/category_cubit.dart';
import '../../features/tasks/presentation/cubit/task_cubit.dart';

/// نظام حقن التبعيات الخفيف الخالي من الحزم الخارجية (Service Locator Pattern)
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;

  ServiceLocator._internal();

  final Map<String, dynamic Function()> _factories = {};
  final Map<String, dynamic> _singletons = {};

  String _getKey<T>([String? instanceName]) =>
      '${T.toString()}${instanceName != null ? '#$instanceName' : ''}';

  void registerLazySingleton<T>(T Function() factory, {String? instanceName}) {
    final key = _getKey<T>(instanceName);
    _factories[key] = () {
      if (!_singletons.containsKey(key)) {
        _singletons[key] = factory();
      }
      return _singletons[key];
    };
  }

  void registerFactory<T>(T Function() factory, {String? instanceName}) {
    final key = _getKey<T>(instanceName);
    _factories[key] = factory;
  }

  bool isRegistered<T>({String? instanceName}) {
    final key = _getKey<T>(instanceName);
    return _factories.containsKey(key) || _singletons.containsKey(key);
  }

  T get<T>({String? instanceName}) {
    final key = _getKey<T>(instanceName);
    if (_singletons.containsKey(key)) {
      return _singletons[key] as T;
    }
    if (_factories.containsKey(key)) {
      return _factories[key]!() as T;
    }
    throw StateError('Service not registered: $key');
  }

  T call<T>({String? instanceName}) => get<T>(instanceName: instanceName);

  void reset() {
    _factories.clear();
    _singletons.clear();
  }
}

final sl = ServiceLocator.instance;

/// تهيئة وحقن كافة التبعيات والخدمات (Dependency Injection)
Future<void> initDependencies() async {
  // 1. صناديق البيانات المحلية (Hive Boxes)
  if (!sl.isRegistered<Box>(instanceName: AppConstants.tasksBoxName)) {
    final tasksBox = await Hive.openBox(AppConstants.tasksBoxName);
    sl.registerLazySingleton<Box>(() => tasksBox, instanceName: AppConstants.tasksBoxName);
  }

  if (!sl.isRegistered<Box>(instanceName: AppConstants.settingsBoxName)) {
    final settingsBox = await Hive.openBox(AppConstants.settingsBoxName);
    sl.registerLazySingleton<Box>(() => settingsBox, instanceName: AppConstants.settingsBoxName);
  }

  if (!sl.isRegistered<Box>(instanceName: AppConstants.authBoxName)) {
    final authBox = await Hive.openBox(AppConstants.authBoxName);
    sl.registerLazySingleton<Box>(() => authBox, instanceName: AppConstants.authBoxName);
  }

  if (!sl.isRegistered<Box>(instanceName: AppConstants.categoriesBoxName)) {
    final categoriesBox = await Hive.openBox(AppConstants.categoriesBoxName);
    sl.registerLazySingleton<Box>(() => categoriesBox, instanceName: AppConstants.categoriesBoxName);
  }

  if (!sl.isRegistered<Box>(instanceName: PomodoroCubit.boxName)) {
    final pomodoroBox = await Hive.openBox(PomodoroCubit.boxName);
    sl.registerLazySingleton<Box>(() => pomodoroBox, instanceName: PomodoroCubit.boxName);
  }

  // 2. الخدمات الأساسية (Core Services)
  if (!sl.isRegistered<INotificationService>()) {
    sl.registerLazySingleton<INotificationService>(() => NotificationService.instance);
  }
  if (!sl.isRegistered<IAmbientAudioService>()) {
    sl.registerLazySingleton<IAmbientAudioService>(() => AmbientAudioService.instance);
  }
  if (!sl.isRegistered<LocalDatabaseService>()) {
    sl.registerLazySingleton<LocalDatabaseService>(() => LocalDatabaseService.instance);
  }
  if (!sl.isRegistered<BiometricService>()) {
    sl.registerLazySingleton<BiometricService>(() => BiometricService.instance);
  }
  if (!sl.isRegistered<AttachmentService>()) {
    sl.registerLazySingleton<AttachmentService>(() => AttachmentService.instance);
  }

  // 3. مصادر البيانات (Data Sources)
  if (!sl.isRegistered<TaskLocalDataSource>()) {
    sl.registerLazySingleton<TaskLocalDataSource>(
      () => TaskLocalDataSourceImpl(box: sl<Box>(instanceName: AppConstants.tasksBoxName)),
    );
  }
  if (!sl.isRegistered<AuthLocalDataSource>()) {
    sl.registerLazySingleton<AuthLocalDataSource>(
      () => AuthLocalDataSourceImpl(
        authBox: sl<Box>(instanceName: AppConstants.authBoxName),
        settingsBox: sl<Box>(instanceName: AppConstants.settingsBoxName),
      ),
    );
  }

  // 4. المستودعات (Repositories)
  if (!sl.isRegistered<TaskRepository>()) {
    sl.registerLazySingleton<TaskRepository>(
      () => TaskRepositoryImpl(localDataSource: sl<TaskLocalDataSource>()),
    );
  }
  if (!sl.isRegistered<AuthRepository>()) {
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(localDataSource: sl<AuthLocalDataSource>()),
    );
  }

  // 5. إدارة الحالة (Cubits)
  if (!sl.isRegistered<ThemeCubit>()) {
    sl.registerFactory<ThemeCubit>(
      () => ThemeCubit(settingsBox: sl<Box>(instanceName: AppConstants.settingsBoxName)),
    );
  }
  if (!sl.isRegistered<TaskCubit>()) {
    sl.registerFactory<TaskCubit>(
      () => TaskCubit(
        repository: sl<TaskRepository>(),
        notificationService: sl<INotificationService>(),
      ),
    );
  }
  if (!sl.isRegistered<AuthCubit>()) {
    sl.registerFactory<AuthCubit>(
      () => AuthCubit(repository: sl<AuthRepository>()),
    );
  }
  if (!sl.isRegistered<PomodoroCubit>()) {
    sl.registerFactory<PomodoroCubit>(
      () => PomodoroCubit(
        box: sl<Box>(instanceName: PomodoroCubit.boxName),
        ambientAudioService: sl<IAmbientAudioService>(),
      ),
    );
  }
  if (!sl.isRegistered<CategoryCubit>()) {
    sl.registerFactory<CategoryCubit>(
      () => CategoryCubit(),
    );
  }
  if (!sl.isRegistered<LocaleCubit>()) {
    sl.registerFactory<LocaleCubit>(
      () => LocaleCubit(settingsBox: sl<Box>(instanceName: AppConstants.settingsBoxName)),
    );
  }
}
