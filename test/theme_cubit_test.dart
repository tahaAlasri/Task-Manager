import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager/core/constants/app_constants.dart';
import 'package:task_manager/core/theme/theme_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box settingsBox;
  late ThemeCubit cubit;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('theme_cubit_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    settingsBox = await Hive.openBox('test_settings_box_${DateTime.now().microsecondsSinceEpoch}');
    cubit = ThemeCubit(settingsBox: settingsBox);
  });

  tearDown(() async {
    await cubit.close();
    await settingsBox.close();
  });

  group('ThemeCubit Tests', () {
    test('الحالة الافتراضية تكون system إذا لم يتم حفظ تفضيل مسبق', () {
      expect(cubit.state, equals(ThemeMode.system));
    });

    test('تعيين المظهر إلى داكن يحدث الحالة ويحفظها في Hive', () {
      cubit.setThemeMode(ThemeMode.dark);
      expect(cubit.state, equals(ThemeMode.dark));
      expect(cubit.isDarkMode, isTrue);
      expect(settingsBox.get(AppConstants.keyThemeMode), equals('dark'));
    });

    test('تعيين المظهر إلى فاتح يحدث الحالة ويحفظها في Hive', () {
      cubit.setThemeMode(ThemeMode.light);
      expect(cubit.state, equals(ThemeMode.light));
      expect(cubit.isDarkMode, isFalse);
      expect(settingsBox.get(AppConstants.keyThemeMode), equals('light'));
    });

    test('toggleTheme يبدل بين الفاتح والداكن بالتناوب', () {
      cubit.setThemeMode(ThemeMode.light);
      cubit.toggleTheme();
      expect(cubit.state, equals(ThemeMode.dark));

      cubit.toggleTheme();
      expect(cubit.state, equals(ThemeMode.light));
    });
  });
}
