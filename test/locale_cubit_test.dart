import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:task_manager/core/localization/locale_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late Box settingsBox;
  late LocaleCubit cubit;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('locale_cubit_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    settingsBox = await Hive.openBox('test_locale_box_${DateTime.now().microsecondsSinceEpoch}');
    cubit = LocaleCubit(settingsBox: settingsBox);
  });

  tearDown(() async {
    await cubit.close();
    await settingsBox.close();
  });

  group('LocaleCubit Tests', () {
    test('الحالة الافتراضية تكون العربية (ar)', () {
      expect(cubit.state.languageCode, equals('ar'));
    });

    test('تغيير اللغة إلى الإنجليزية يحفظها في Hive ويحدث الحالة', () async {
      await cubit.setLocale('en');
      expect(cubit.state.languageCode, equals('en'));
      expect(settingsBox.get(LocaleCubit.keyLocale), equals('en'));
    });

    test('تغيير اللغة باستخدام كائن Locale', () async {
      await cubit.setLocale(const Locale('en'));
      expect(cubit.state.languageCode, equals('en'));
      expect(settingsBox.get(LocaleCubit.keyLocale), equals('en'));
    });

    test('toggleLocale يبدل بين العربية والإنجليزية بالتناوب', () async {
      expect(cubit.state.languageCode, equals('ar'));
      await cubit.toggleLocale();
      expect(cubit.state.languageCode, equals('en'));

      await cubit.toggleLocale();
      expect(cubit.state.languageCode, equals('ar'));
    });
  });
}
