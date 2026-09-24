import '../entities/user_entity.dart';

/// واجهة مستودع المصادقة والمستخدم في طبقة الـ Domain
abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<UserEntity> login(String email, String password);
  Future<UserEntity> register(String name, String email, String password);
  Future<void> deleteAccount();
  Future<UserEntity> updateProfile({required String name, String? newPassword});
  Future<UserEntity?> loginWithBiometrics();
  Future<void> logout();
  Future<bool> isBiometricsSupported();
  Future<void> setBiometricsEnabled(bool enabled);
  Future<bool> isBiometricsEnabled();
  Future<bool> hasSeenOnboarding();
  Future<void> completeOnboarding();
}
