import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:task_manager/features/tasks/data/models/category_model.dart';
import 'package:task_manager/features/tasks/presentation/cubit/category_cubit.dart';

void main() {
  group('CategoryModel Tests', () {
    test('يجب تحويل CategoryModel إلى Map واستعادتها بنجاح', () {
      const category = CategoryModel(
        id: 'cat_custom_1',
        nameAr: 'ألعاب وترفيه',
        nameEn: 'Gaming',
        icon: Icons.gamepad_rounded,
        color: Color(0xFF8B5CF6),
        isCustom: true,
        userId: 'user_123',
      );

      final map = category.toMap();
      expect(map['id'], equals('cat_custom_1'));
      expect(map['nameAr'], equals('ألعاب وترفيه'));
      expect(map['nameEn'], equals('Gaming'));
      expect(map['iconCodePoint'], equals(Icons.gamepad_rounded.codePoint));
      expect(map['colorValue'], equals(const Color(0xFF8B5CF6).toARGB32()));
      expect(map['isCustom'], isTrue);
      expect(map['userId'], equals('user_123'));

      final restored = CategoryModel.fromMap(map);
      expect(restored.id, equals(category.id));
      expect(restored.nameAr, equals(category.nameAr));
      expect(restored.nameEn, equals(category.nameEn));
      expect(restored.icon.codePoint, equals(category.icon.codePoint));
      expect(restored.color.toARGB32(), equals(category.color.toARGB32()));
      expect(restored.isCustom, isTrue);
      expect(restored.userId, equals('user_123'));
    });

    test('CategoryModel.findById يعثر على الفئة الافتراضية بنجاح', () {
      final workCat = CategoryModel.findById('work');
      expect(workCat.id, equals('work'));
      expect(workCat.nameAr, equals('عمل'));
    });

    test('CategoryModel.findById يعثر على الفئة المخصصة إذا تم تمريرها في القائمة', () {
      const custom = CategoryModel(
        id: 'cat_travel',
        nameAr: 'سياحة وسفر',
        nameEn: 'Travel',
        icon: Icons.flight_takeoff_rounded,
        color: Colors.teal,
        isCustom: true,
      );

      final found = CategoryModel.findById('cat_travel', customCategories: [custom]);
      expect(found.id, equals('cat_travel'));
      expect(found.nameAr, equals('سياحة وسفر'));
    });

    test('CategoryModel.findById يعيد فئة "أخرى" عند تمرير معرف غير معروف', () {
      final unknown = CategoryModel.findById('unknown_xyz');
      expect(unknown.id, equals('other'));
    });
  });

  group('CategoryCubit Tests', () {
    test('الحالة المبدئية تحتوي على الفئات الافتراضية كاملة', () {
      final cubit = CategoryCubit();
      expect(cubit.state.categories.length, equals(CategoryModel.defaultCategories.length));
      expect(cubit.state.categories.first.id, equals('work'));
    });

    test('لا يمكن حذف الفئات الافتراضية ويعود بـ false', () async {
      final cubit = CategoryCubit();
      final result = await cubit.deleteCategory('work');
      expect(result, isFalse);
    });
  });
}
