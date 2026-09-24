import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/permission_service.dart';

/// نافذة مخصصة لفحص وإدارة أذونات التطبيق
class PermissionsDialog extends StatefulWidget {
  const PermissionsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const PermissionsDialog(),
    );
  }

  @override
  State<PermissionsDialog> createState() => _PermissionsDialogState();
}

class _PermissionsDialogState extends State<PermissionsDialog> {
  bool _isLoading = true;
  bool _notificationGranted = false;
  bool _biometricsAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    setState(() => _isLoading = true);
    final report = await PermissionService.instance.checkPermissions();
    if (mounted) {
      setState(() {
        _notificationGranted = report.notifications;
        _biometricsAvailable = report.biometrics;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestNotifications() async {
    final granted = await PermissionService.instance.requestNotificationPermission();
    if (mounted) {
      setState(() => _notificationGranted = granted);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(granted ? 'تم تفعيل إذن الإشعارات بنجاح' : 'لم يتم منح إذن الإشعارات'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // مقبض السحب
          Center(
            child: Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.security_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أذونات التطبيق والنظام',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'لضمان عمل التنبيهات والبصمة بأعلى كفاءة',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          if (_isLoading)
            const Center(child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ))
          else ...[
            // 1. إذن الإشعارات
            _buildPermissionItem(
              icon: Icons.notifications_active_rounded,
              title: 'إشعارات المواعيد والتذكيرات',
              subtitle: 'لإرسال تنبيه على جهازك عند موعد استحقاق المهمة',
              isGranted: _notificationGranted,
              onTap: _requestNotifications,
              actionLabel: _notificationGranted ? 'مفعّل' : 'تفعيل الإذن',
            ),
            const SizedBox(height: 12),

            // 2. إذن البصمة الحيوية
            _buildPermissionItem(
              icon: Icons.fingerprint_rounded,
              title: 'المصادقة بالبصمة أو الوجه',
              subtitle: 'لتسجيل الدخول السريع والآمن دون الحاجة لكلمة المرور',
              isGranted: _biometricsAvailable,
              actionLabel: _biometricsAvailable ? 'مدعوم' : 'غير متوفر',
            ),
            const SizedBox(height: 12),

            // 3. إذن المنبهات الدقيقة
            _buildPermissionItem(
              icon: Icons.alarm_on_rounded,
              title: 'جدولة التنبيهات الدقيقة',
              subtitle: 'لضمان انطلاق التنبيه في الوقت المحدد بدقة حتى أثناء قفل الشاشة',
              isGranted: true,
              actionLabel: 'مفعّل تلقائياً',
            ),
          ],
          const SizedBox(height: 24),

          // زر الإغلاق
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('تم', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isGranted,
    VoidCallback? onTap,
    required String actionLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isGranted
              ? AppColors.completed.withAlpha(80)
              : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isGranted ? AppColors.completed : AppColors.primary,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (onTap != null && !isGranted)
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(actionLabel, style: const TextStyle(fontSize: 11)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isGranted
                    ? AppColors.completed.withAlpha(30)
                    : Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isGranted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                    size: 13,
                    color: isGranted ? AppColors.completed : Colors.grey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    actionLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isGranted ? AppColors.completed : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
