import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// خدمة إدارة المصادقة الحيوية عبر بصمة الإصبع أو الوجه
class BiometricService {
  BiometricService._();
  static final BiometricService instance = BiometricService._();

  final LocalAuthentication _auth = LocalAuthentication();

  /// التحقق مما إذا كان الجهاز يدعم المستشعرات الحيوية
  Future<bool> isBiometricsSupported() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck || isSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// جلب أنواع المصادقة الحيوية المتوفرة في الجهاز (بصمة، وجه، إلخ)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// طلب مصادقة المستخدم عبر المستشعر الحيوي
  Future<bool> authenticate({
    String reason = 'يرجى تأكيد هويتك لتسجيل الدخول إلى حسابك بأمان',
  }) async {
    try {
      final supported = await isBiometricsSupported();
      if (!supported) return false;

      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
