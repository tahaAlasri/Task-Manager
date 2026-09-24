import '../../../../core/services/biometric_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthLocalDataSource localDataSource;
  final BiometricService biometricService;

  AuthRepositoryImpl({
    required this.localDataSource,
    BiometricService? biometricService,
  }) : biometricService = biometricService ?? BiometricService.instance;

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await localDataSource.getCurrentUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  @override
  Future<UserEntity> login(String email, String password) async {
    return await localDataSource.login(email, password);
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    return await localDataSource.register(name, email, password);
  }

  @override
  Future<void> deleteAccount() async {
    await localDataSource.deleteAccount();
  }

  @override
  Future<UserEntity> updateProfile({required String name, String? newPassword}) async {
    return await localDataSource.updateProfile(name: name, newPassword: newPassword);
  }

  @override
  Future<UserEntity?> loginWithBiometrics() async {
    final isSupported = await biometricService.isBiometricsSupported();
    if (!isSupported) {
      throw 'الجهاز لا يدعم مستشعرات المصادقة الحيوية (البصمة أو الوجه)';
    }

    final isEnabled = await localDataSource.isBiometricsEnabled();
    if (!isEnabled) {
      throw 'المصادقة الحيوية معطلة في الإعدادات';
    }

    final lastUser = await localDataSource.getCurrentUser();
    if (lastUser == null) {
      throw 'لم يتم العثور على حساب مسجل سابقاً. يرجى تسجيل الدخول بالبريد الإلكتروني أولاً لتفعيل البصمة';
    }

    final isAuthenticated = await biometricService.authenticate(
      reason: 'يرجى تأكيد بصمة إصبعك لتسجيل الدخول السريع كـ ${lastUser.name}',
    );

    if (isAuthenticated) {
      await localDataSource.saveCurrentUser(lastUser);
      return lastUser;
    } else {
      throw 'فشلت المصادقة بالبصمة، يرجى المحاولة مجدداً أو استخدام كلمة المرور';
    }
  }

  @override
  Future<void> logout() async {
    await localDataSource.logout();
  }

  @override
  Future<bool> isBiometricsSupported() async {
    return await biometricService.isBiometricsSupported();
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    return await localDataSource.isBiometricsEnabled();
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await localDataSource.setBiometricsEnabled(enabled);
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    return await localDataSource.hasSeenOnboarding();
  }

  @override
  Future<void> completeOnboarding() async {
    await localDataSource.setHasSeenOnboarding(true);
  }
}
