import '../../data/models/category_model.dart';

/// حالة الفئات المتاحة في التطبيق
class CategoryState {
  final List<CategoryModel> categories;
  final bool isLoading;
  final String? errorMessage;

  const CategoryState({
    this.categories = CategoryModel.defaultCategories,
    this.isLoading = false,
    this.errorMessage,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
