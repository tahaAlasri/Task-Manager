import 'package:flutter/material.dart';

/// كائن تصنيف المهام في طبقة الـ Domain
class CategoryEntity {
  final String id;
  final String nameAr;
  final String nameEn;
  final IconData icon;
  final Color color;
  final bool isCustom;
  final String? userId;

  const CategoryEntity({
    required this.id,
    required this.nameAr,
    required this.nameEn,
    required this.icon,
    required this.color,
    this.isCustom = false,
    this.userId,
  });

  String localizedName(bool isArabic) => isArabic ? nameAr : nameEn;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
