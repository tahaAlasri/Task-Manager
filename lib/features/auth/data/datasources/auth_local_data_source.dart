import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(String name, String email, String password);
  Future<void> deleteAccount();
  Future<UserModel> updateProfile({required String name, String? newPassword});
  Future<void> saveCurrentUser(UserModel user);
  Future<void> logout();
  Future<bool> hasSeenOnboarding();
  Future<void> setHasSeenOnboarding(bool seen);
  Future<bool> isBiometricsEnabled();
  Future<void> setBiometricsEnabled(bool enabled);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box _authBox;
  final Box _settingsBox;

  AuthLocalDataSourceImpl({Box? authBox, Box? settingsBox})
      : _authBox = authBox ?? Hive.box(AppConstants.authBoxName),
        _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName);

  /// تجزئة كلمة المرور عبر خوارزمية SHA-256 مع التمليح لحماية تامة للبيانات
  String _hashPassword(String password) {
    const salt = 'injaz_secure_salt_2026';
    final bytes = utf8.encode('$salt$password');
    return sha256.convert(bytes).toString();
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final userData = _authBox.get(AppConstants.keyCurrentUser);
    if (userData is Map) {
      final email = userData['email']?.toString().toLowerCase() ?? '';
      final name = userData['name']?.toString() ?? '';
      final id = userData['id']?.toString() ?? '';
      if (email.contains('injaz.local') || name.contains('إنجاز') || id.startsWith('guest')) {
        await _authBox.delete(AppConstants.keyCurrentUser);
        await _authBox.put(AppConstants.keyIsLoggedIn, false);
        return null;
      }
      return UserModel.fromMap(userData);
    }
    return null;
  }

  @override
  Future<bool> isLoggedIn() async {
    final loggedIn = _authBox.get(AppConstants.keyIsLoggedIn, defaultValue: false) as bool;
    if (!loggedIn) return false;
    final user = await getCurrentUser();
    return user != null;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userKey = 'user_$normalizedEmail';
    final userData = _authBox.get(userKey);

    if (userData == null || userData is! Map) {
      throw 'الحساب غير مسجل، يرجى إنشاء حساب جديد أولاً';
    }

    final storedUser = UserModel.fromMap(userData);
    final hashedInput = _hashPassword(password);

    // التحقق من تطابق كلمة المرور المشفرة (أو غير المشفرة للبيانات السابقة مع ترقيتها)
    if (storedUser.password != hashedInput && storedUser.password != password) {
      throw 'كلمة المرور غير صحيحة، يرجى المحاولة مرة أخرى';
    }

    // ترقية كلمة المرور للتشفير الحديث إذا كانت مسجلة قديماً كنص عادي
    final activeUser = storedUser.password == password
        ? storedUser.copyWith(password: hashedInput)
        : storedUser;

    if (storedUser.password == password) {
      await _authBox.put(userKey, activeUser.toMap());
    }

    await saveCurrentUser(activeUser);
    return activeUser;
  }

  @override
  Future<UserModel> register(String name, String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final userKey = 'user_$normalizedEmail';

    if (_authBox.containsKey(userKey)) {
      throw 'هذا البريد الإلكتروني مسجل بالفعل';
    }

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name.trim(),
      email: normalizedEmail,
      password: _hashPassword(password),
      createdAt: DateTime.now(),
    );

    // حفظ المستخدم في سجل الحسابات
    await _authBox.put(userKey, newUser.toMap());
    // تعيينه كمستخدم حالي نشط
    await saveCurrentUser(newUser);
    return newUser;
  }

  @override
  Future<void> deleteAccount() async {
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      final userKey = 'user_${currentUser.email}';
      await _authBox.delete(userKey);
    }
    await _authBox.delete(AppConstants.keyCurrentUser);
    await _authBox.put(AppConstants.keyIsLoggedIn, false);
  }

  @override
  Future<UserModel> updateProfile({required String name, String? newPassword}) async {
    final currentUser = await getCurrentUser();
    if (currentUser == null) {
      throw 'لا يوجد مستخدم مسجل حالياً';
    }

    final userKey = 'user_${currentUser.email}';
    final updatedUser = currentUser.copyWith(
      name: name.trim(),
      password: (newPassword != null && newPassword.trim().isNotEmpty)
          ? _hashPassword(newPassword.trim())
          : currentUser.password,
    );

    await _authBox.put(userKey, updatedUser.toMap());
    await saveCurrentUser(updatedUser);
    return updatedUser;
  }

  @override
  Future<void> saveCurrentUser(UserModel user) async {
    await _authBox.put(AppConstants.keyCurrentUser, user.toMap());
    await _authBox.put(AppConstants.keyIsLoggedIn, true);
  }

  @override
  Future<void> logout() async {
    await _authBox.put(AppConstants.keyIsLoggedIn, false);
    await _authBox.delete(AppConstants.keyCurrentUser);
  }

  @override
  Future<bool> hasSeenOnboarding() async {
    return _settingsBox.get(AppConstants.keyHasSeenOnboarding, defaultValue: false) as bool;
  }

  @override
  Future<void> setHasSeenOnboarding(bool seen) async {
    await _settingsBox.put(AppConstants.keyHasSeenOnboarding, seen);
  }

  @override
  Future<bool> isBiometricsEnabled() async {
    return _settingsBox.get(AppConstants.keyBiometricsEnabled, defaultValue: true) as bool;
  }

  @override
  Future<void> setBiometricsEnabled(bool enabled) async {
    await _settingsBox.put(AppConstants.keyBiometricsEnabled, enabled);
  }
}
