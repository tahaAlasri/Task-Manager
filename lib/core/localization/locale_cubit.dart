import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/app_constants.dart';

/// إدارة لغة التطبيق الحالية وحفظها في التخزين المحلي
class LocaleCubit extends Cubit<Locale> {
  final Box _settingsBox;
  static const String keyLocale = 'app_selected_locale';

  LocaleCubit({Box? settingsBox})
      : _settingsBox = settingsBox ?? Hive.box(AppConstants.settingsBoxName),
        super(const Locale('ar')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final savedCode = _settingsBox.get(keyLocale, defaultValue: 'ar') as String;
    emit(Locale(savedCode));
  }

  Future<void> setLocale(dynamic localeOrCode) async {
    final code = localeOrCode is Locale ? localeOrCode.languageCode : localeOrCode.toString();
    if (code == state.languageCode) return;
    await _settingsBox.put(keyLocale, code);
    emit(Locale(code));
  }

  Future<void> toggleLocale() async {
    final nextCode = state.languageCode == 'ar' ? 'en' : 'ar';
    await setLocale(nextCode);
  }
}
