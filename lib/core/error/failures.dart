/// الأصناف الموحدة لتمثيل الأخطاء والإخفاقات في طبقة الـ Domain والـ Core
abstract class Failure {
  final String message;
  const Failure(this.message);

  @override
  String toString() => message;
}

class DatabaseFailure extends Failure {
  const DatabaseFailure([super.message = 'حدث خطأ في قاعدة البيانات المحلية']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'فشلت عملية المصادقة']);
}

class NotificationFailure extends Failure {
  const NotificationFailure([super.message = 'فشل في جدولة أو إلغاء التنبيه']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'البيانات المدخلة غير صحيحة']);
}
