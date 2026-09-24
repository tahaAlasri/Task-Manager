import 'package:flutter/foundation.dart';
import 'biometric_service.dart';
import 'notification_service.dart';

class PermissionStatusReport {
  final bool notifications;
  final bool biometrics;
  final bool exactAlarms;

  const PermissionStatusReport({
    required this.notifications,
    required this.biometrics,
    required this.exactAlarms,
  });

  bool get allGranted => notifications && biometrics;
}

/// خدمة فحص وإدارة الأذونات في التطبيق
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// فحص حالة الأذونات الحالية
  Future<PermissionStatusReport> checkPermissions() async {
    bool notifs = false;
    bool biometrics = false;

    try {
      notifs = await NotificationService.instance.areNotificationsEnabled();
    } catch (_) {}

    try {
      biometrics = await BiometricService.instance.isBiometricsSupported();
    } catch (_) {}

    return PermissionStatusReport(
      notifications: notifs,
      biometrics: biometrics,
      exactAlarms: true,
    );
  }

  /// طلب إذن الإشعارات والتنبيهات
  Future<bool> requestNotificationPermission() async {
    try {
      final res = await NotificationService.instance.requestPermissions();
      return res ?? false;
    } catch (e) {
      debugPrint('Notification permission request error: $e');
      return false;
    }
  }

  /// طلب كافة الأذونات اللازمة للعمل بأفضل كفاءة
  Future<PermissionStatusReport> requestAllPermissions() async {
    final notifs = await requestNotificationPermission();
    final bio = await BiometricService.instance.isBiometricsSupported();

    return PermissionStatusReport(
      notifications: notifs,
      biometrics: bio,
      exactAlarms: true,
    );
  }
}
