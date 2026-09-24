import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/category_entity.dart';

/// نموذج الفئات مع قائمة الفئات الافتراضية للتطبيق
class CategoryModel extends CategoryEntity {
  const CategoryModel({
    required super.id,
    required super.nameAr,
    required super.nameEn,
    required super.icon,
    required super.color,
    super.isCustom,
    super.userId,
  });

  /// الفئات الافتراضية الجاهزة في التطبيق
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      id: 'work',
      nameAr: 'عمل',
      nameEn: 'Work',
      icon: Icons.work_outline_rounded,
      color: AppColors.categoryWork,
    ),
    CategoryModel(
      id: 'personal',
      nameAr: 'شخصي',
      nameEn: 'Personal',
      icon: Icons.person_outline_rounded,
      color: AppColors.categoryPersonal,
    ),
    CategoryModel(
      id: 'study',
      nameAr: 'دراسة',
      nameEn: 'Study',
      icon: Icons.menu_book_rounded,
      color: AppColors.categoryStudy,
    ),
    CategoryModel(
      id: 'health',
      nameAr: 'صحة',
      nameEn: 'Health',
      icon: Icons.fitness_center_rounded,
      color: AppColors.categoryHealth,
    ),
    CategoryModel(
      id: 'other',
      nameAr: 'أخرى',
      nameEn: 'Other',
      icon: Icons.category_outlined,
      color: AppColors.categoryOther,
    ),
  ];

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      nameAr: entity.nameAr,
      nameEn: entity.nameEn,
      icon: entity.icon,
      color: entity.color,
      isCustom: entity.isCustom,
      userId: entity.userId,
    );
  }

  factory CategoryModel.fromMap(Map<dynamic, dynamic> map) {
    final codePoint = map['iconCodePoint'] as int? ?? Icons.category_outlined.codePoint;
    final colorVal = map['colorValue'] as int? ?? AppColors.categoryOther.toARGB32();

    return CategoryModel(
      id: map['id'] as String? ?? '',
      nameAr: map['nameAr'] as String? ?? '',
      nameEn: map['nameEn'] as String? ?? '',
      // ignore: non_const_argument_for_const_parameter
      icon: IconData(codePoint, fontFamily: 'MaterialIcons'),
      color: Color(colorVal),
      isCustom: map['isCustom'] as bool? ?? true,
      userId: map['userId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nameAr': nameAr,
      'nameEn': nameEn,
      'iconCodePoint': icon.codePoint,
      'colorValue': color.toARGB32(),
      'isCustom': isCustom,
      'userId': userId,
    };
  }

  /// إيجاد الفئة عبر معرفها
  static CategoryModel findById(String id, {List<CategoryModel>? customCategories}) {
    final all = [...defaultCategories, ...(customCategories ?? [])];
    return all.firstWhere(
      (cat) => cat.id == id,
      orElse: () => defaultCategories.last,
    );
  }
}
