import 'package:flutter/material.dart';

/// نظام الألوان المخصص للتطبيق (متوافق مع Material 3 ويدعم الوضعين الفاتح والداكن)
class AppColors {
  AppColors._();

  // الألوان الأساسية
  static const Color primary = Color(0xFF6366F1); // Indigo ناصع وحديث
  static const Color primaryLight = Color(0xFFEEF2FF);
  static const Color primaryDark = Color(0xFF4338CA);

  static const Color secondary = Color(0xFF06B6D4); // Cyan مميز للتركيز
  static const Color accent = Color(0xFF8B5CF6);

  // درجات الخلفيات - الوضع الفاتح
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // درجات الخلفيات - الوضع الداكن
  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkCard = Color(0xFF1F2937);
  static const Color darkBorder = Color(0xFF374151);
  static const Color darkTextPrimary = Color(0xFFF9FAFB);
  static const Color darkTextSecondary = Color(0xFF9CA3AF);

  // ألوان مستويات الأولوية (Priority Colors)
  static const Color priorityHigh = Color(0xFFEF4444); // أحمر
  static const Color priorityHighBg = Color(0xFFFEE2E2);

  static const Color priorityMedium = Color(0xFFF59E0B); // برتقالي / عنبري
  static const Color priorityMediumBg = Color(0xFFFEF3C7);

  static const Color priorityLow = Color(0xFF10B981); // أخضر زمردي
  static const Color priorityLowBg = Color(0xFFD1FAE5);

  // ألوان تصنيفات المهام الافتراضية
  static const Color categoryWork = Color(0xFF3B82F6);
  static const Color categoryPersonal = Color(0xFF8B5CF6);
  static const Color categoryStudy = Color(0xFFF59E0B);
  static const Color categoryHealth = Color(0xFF10B981);
  static const Color categoryFinance = Color(0xFFEC4899);
  static const Color categoryOther = Color(0xFF64748B);

  // حالات الإنجاز
  static const Color completed = Color(0xFF10B981);
  static const Color inProgress = Color(0xFF3B82F6);
  static const Color overdue = Color(0xFFEF4444);
}
