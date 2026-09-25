import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(const AuthState());

  /// التحقق من حالة الجلسة عند تشغيل التطبيق
  Future<void> checkAuthStatus() async {
    try {
      final hasSeen = await repository.hasSeenOnboarding();
      final isLoggedIn = await repository.isLoggedIn();
      final user = isLoggedIn ? await repository.getCurrentUser() : null;

      emit(state.copyWith(
        status: (isLoggedIn && user != null) ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: user,
        hasSeenOnboarding: hasSeen,
        clearUser: !isLoggedIn || user == null,
      ));

      // فحص دعم البصمة بشكل منفصل حتى لا يؤخر فتح التطبيق
      try {
        final isBioAvailable = await repository.isBiometricsSupported();
        emit(state.copyWith(isBiometricsAvailable: isBioAvailable));
      } catch (_) {}
    } catch (_) {
      final hasSeen = await repository.hasSeenOnboarding().catchError((_) => false);
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
        hasSeenOnboarding: hasSeen,
      ));
    }
  }

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await repository.login(email, password);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// إنشاء حساب جديد
  Future<void> register(String name, String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await repository.register(name, email, password);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword(String email, String newPassword) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      await repository.resetPassword(email, newPassword);
      emit(state.copyWith(status: AuthStatus.unauthenticated, errorMessage: null));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// حذف الحساب نهائياً ومسح بياناته
  Future<void> deleteAccount() async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      await repository.deleteAccount();
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        clearUser: true,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// تحديث الملف الشخصي للمستخدم
  Future<void> updateProfile({required String name, String? newPassword}) async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final updatedUser = await repository.updateProfile(name: name, newPassword: newPassword);
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: updatedUser,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// تسجيل الدخول السريع بالمصادقة الحيوية (البصمة أو الوجه)
  Future<void> loginWithBiometrics() async {
    emit(state.copyWith(status: AuthStatus.loading, errorMessage: null));
    try {
      final user = await repository.loginWithBiometrics();
      if (user != null) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      } else {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          clearUser: true,
          errorMessage: 'لم تكتمل المصادقة الحيوية',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      ));
    }
  }

  /// تسجيل الخروج
  Future<void> logout() async {
    await repository.logout();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      clearUser: true,
    ));
  }

  /// إنهاء وإتمام مرحلة شاشة التعريف للمستخدم الجديد
  Future<void> completeOnboarding() async {
    await repository.completeOnboarding();
    emit(state.copyWith(hasSeenOnboarding: true));
  }
}
