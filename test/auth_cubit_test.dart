import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/auth/domain/entities/user_entity.dart';
import 'package:task_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:task_manager/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:task_manager/features/auth/presentation/cubit/auth_state.dart';

class FakeAuthRepository implements AuthRepository {
  UserEntity? _currentUser;
  bool _isLoggedIn = false;
  bool _hasSeenOnboarding = false;

  @override
  Future<UserEntity?> getCurrentUser() async => _currentUser;

  @override
  Future<bool> isLoggedIn() async => _isLoggedIn;

  @override
  Future<UserEntity> login(String email, String password) async {
    if (password != 'password123') throw Exception('كلمة المرور غير صحيحة');
    _currentUser = UserEntity(
      id: '1',
      name: 'مستخدم تجريبي',
      email: email,
      createdAt: DateTime.now(),
    );
    _isLoggedIn = true;
    return _currentUser!;
  }

  @override
  Future<UserEntity> register(String name, String email, String password) async {
    _currentUser = UserEntity(
      id: '2',
      name: name,
      email: email,
      createdAt: DateTime.now(),
    );
    _isLoggedIn = true;
    return _currentUser!;
  }

  @override
  Future<void> deleteAccount() async {
    _currentUser = null;
    _isLoggedIn = false;
  }

  @override
  Future<UserEntity> updateProfile({required String name, String? newPassword}) async {
    if (_currentUser == null) throw Exception('لا يوجد حساب');
    _currentUser = UserEntity(
      id: _currentUser!.id,
      name: name,
      email: _currentUser!.email,
      createdAt: _currentUser!.createdAt,
    );
    return _currentUser!;
  }

  @override
  Future<UserEntity?> loginWithBiometrics() async {
    if (_currentUser == null) throw Exception('لا يوجد حساب');
    _isLoggedIn = true;
    return _currentUser;
  }

  @override
  Future<void> logout() async {
    _isLoggedIn = false;
  }

  @override
  Future<bool> isBiometricsSupported() async => true;

  @override
  Future<bool> isBiometricsEnabled() async => true;

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {}

  @override
  Future<bool> hasSeenOnboarding() async => _hasSeenOnboarding;

  @override
  Future<void> completeOnboarding() async {
    _hasSeenOnboarding = true;
  }

  @override
  Future<void> resetPassword(String email, String newPassword) async {
    if (_currentUser == null || _currentUser!.email != email) {
      throw Exception('البريد الإلكتروني غير مسجل');
    }
  }
}

void main() {
  group('AuthCubit Tests', () {
    late FakeAuthRepository fakeRepo;
    late AuthCubit cubit;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      cubit = AuthCubit(repository: fakeRepo);
    });

    tearDown(() {
      cubit.close();
    });

    test('الحالة الابتدائية تكون initial', () {
      expect(cubit.state.status, equals(AuthStatus.initial));
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('تسجيل الدخول بنجاح يغير الحالة إلى authenticated', () async {
      await cubit.login('test@test.com', 'password123');

      expect(cubit.state.status, equals(AuthStatus.authenticated));
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.user?.email, equals('test@test.com'));
    });

    test('تسجيل الدخول بكلمة مرور خاطئة يغير الحالة إلى failure', () async {
      await cubit.login('test@test.com', 'wrong');

      expect(cubit.state.status, equals(AuthStatus.failure));
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
    });

    test('إنشاء حساب جديد يغير الحالة إلى authenticated', () async {
      await cubit.register('أحمد', 'ahmed@test.com', '123456');

      expect(cubit.state.status, equals(AuthStatus.authenticated));
      expect(cubit.state.user?.name, equals('أحمد'));
    });

    test('حذف الحساب يغير الحالة إلى unauthenticated ويفرغ بيانات المستخدم', () async {
      await cubit.register('أحمد', 'ahmed@test.com', '123456');
      expect(cubit.state.isAuthenticated, isTrue);

      await cubit.deleteAccount();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.user, isNull);
    });

    test('تسجيل الخروج يغير الحالة إلى unauthenticated ويفرغ المستخدم', () async {
      await cubit.register('أحمد', 'ahmed@test.com', '123456');
      expect(cubit.state.isAuthenticated, isTrue);

      await cubit.logout();
      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.user, isNull);
    });

    test('إتمام شاشة الترحيب Onboarding يحدث حالة hasSeenOnboarding', () async {
      await cubit.completeOnboarding();
      expect(cubit.state.hasSeenOnboarding, isTrue);
    });

    test('تحديث الملف الشخصي يغير بيانات المستخدم بنجاح', () async {
      await cubit.register('أحمد', 'ahmed@test.com', '123456');
      expect(cubit.state.user?.name, equals('أحمد'));

      await cubit.updateProfile(name: 'أحمد محمود');
      expect(cubit.state.user?.name, equals('أحمد محمود'));
      expect(cubit.state.status, equals(AuthStatus.authenticated));
    });

    test('إعادة تعيين كلمة المرور بنجاح أو إرجاع خطأ عند عدم وجود الحساب', () async {
      await cubit.register('أحمد', 'ahmed@test.com', '123456');
      await cubit.resetPassword('ahmed@test.com', 'newpass123');
      expect(cubit.state.status, equals(AuthStatus.unauthenticated));

      await cubit.resetPassword('unknown@test.com', 'newpass123');
      expect(cubit.state.status, equals(AuthStatus.failure));
      expect(cubit.state.errorMessage, contains('غير مسجل'));
    });
  });
}
