/// الثوابت العامة للمشروع ومفاتيح قواعد البيانات المحلية
class AppConstants {
  AppConstants._();

  // أسماء صناديق Hive
  static const String tasksBoxName = 'tasks_box';
  static const String categoriesBoxName = 'categories_box';
  static const String settingsBoxName = 'settings_box';
  static const String authBoxName = 'auth_box';

  // مفاتيح الإعدادات والجلسة
  static const String keyThemeMode = 'theme_mode';
  static const String keyLocale = 'locale';
  static const String keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyCurrentUser = 'current_user';
  static const String keyBiometricsEnabled = 'biometrics_enabled';

  // الفئات الافتراضية
  static const String defaultCategoryAll = 'all';
  static const String defaultCategoryWork = 'work';
  static const String defaultCategoryPersonal = 'personal';
  static const String defaultCategoryStudy = 'study';
  static const String defaultCategoryHealth = 'health';
  static const String defaultCategoryOther = 'other';
}
