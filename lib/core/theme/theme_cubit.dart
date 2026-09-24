import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// Cubit لإدارة مظهر التطبيق (فاتح / داكن / بحسب النظام) مع الحفظ التلقائي في Hive
class ThemeCubit extends Cubit<ThemeMode> {
  final Box _settingsBox;

  ThemeCubit({Box? settingsBox})
      : _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName),
        super(_loadInitialTheme(settingsBox ?? Hive.box(AppConstants.settingsBoxName)));

  static ThemeMode _loadInitialTheme(Box box) {
    final saved = box.get(AppConstants.keyThemeMode, defaultValue: 'system');
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  /// تبديل المظهر بين الداكن والفاتح
  void toggleTheme({Brightness? platformBrightness}) {
    ThemeMode nextMode;
    if (state == ThemeMode.dark) {
      nextMode = ThemeMode.light;
    } else if (state == ThemeMode.light) {
      nextMode = ThemeMode.dark;
    } else {
      // إذا كان بحسب النظام، نعكس الحالة الحالية
      final isDarkNow = platformBrightness == Brightness.dark;
      nextMode = isDarkNow ? ThemeMode.light : ThemeMode.dark;
    }
    setThemeMode(nextMode);
  }

  /// تعيين مظهر محدد وحفظه
  void setThemeMode(ThemeMode mode) {
    final str = mode == ThemeMode.dark
        ? 'dark'
        : mode == ThemeMode.light
            ? 'light'
            : 'system';
    _settingsBox.put(AppConstants.keyThemeMode, str);
    emit(mode);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
