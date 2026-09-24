import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/constants/app_constants.dart';
import '../../data/models/category_model.dart';

export 'category_state.dart';
import 'category_state.dart';

/// Cubit لإدارة الفئات الافتراضية والمخصصة وحفظها في Hive
class CategoryCubit extends Cubit<CategoryState> {
  final Box? _customBox;
  String? _currentUserId;

  CategoryCubit({Box? box})
      : _customBox = box,
        super(const CategoryState()) {
    loadCategories();
  }

  Box _getBox() {
    if (_customBox != null) return _customBox;
    if (Hive.isBoxOpen(AppConstants.categoriesBoxName)) {
      return Hive.box(AppConstants.categoriesBoxName);
    }
    throw StateError('Categories box is not open');
  }

  void setCurrentUser(String? userId) {
    _currentUserId = userId;
    loadCategories();
  }

  /// تحميل كافة الفئات الافتراضية مع الفئات المخصصة المخزنة محلياً
  void loadCategories() {
    try {
      final box = _getBox();
      final List<CategoryModel> customList = [];

      for (var key in box.keys) {
        final val = box.get(key);
        if (val is Map) {
          final cat = CategoryModel.fromMap(val);
          if (_currentUserId == null || cat.userId == null || cat.userId == _currentUserId) {
            customList.add(cat);
          }
        }
      }

      final combined = [...CategoryModel.defaultCategories, ...customList];
      emit(state.copyWith(categories: combined, isLoading: false));
    } catch (_) {
      // في حالة عدم فتح الصندوق بعد، نعتمد الفئات الافتراضية
      emit(state.copyWith(categories: CategoryModel.defaultCategories, isLoading: false));
    }
  }

  /// إضافة فئة مخصصة جديدة
  Future<CategoryModel> addCategory({
    required String name,
    required IconData icon,
    required Color color,
    String? nameEn,
  }) async {
    final box = _getBox();
    final newCategory = CategoryModel(
      id: 'cat_${const Uuid().v4().substring(0, 8)}',
      nameAr: name.trim(),
      nameEn: (nameEn != null && nameEn.trim().isNotEmpty) ? nameEn.trim() : name.trim(),
      icon: icon,
      color: color,
      isCustom: true,
      userId: _currentUserId,
    );

    await box.put(newCategory.id, newCategory.toMap());
    loadCategories();
    return newCategory;
  }

  /// حذف فئة مخصصة (لا يمكن حذف الفئات الافتراضية)
  Future<bool> deleteCategory(String id) async {
    final isDefault = CategoryModel.defaultCategories.any((cat) => cat.id == id);
    if (isDefault) return false;

    final box = _getBox();
    await box.delete(id);
    loadCategories();
    return true;
  }
}
