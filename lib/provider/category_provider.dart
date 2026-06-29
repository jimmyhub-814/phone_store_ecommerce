import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/category.dart';

class CategoryProvider extends ChangeNotifier {
  final List<Category> _categories = [];
  List<Category> get categories => [..._categories];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> fetchCategoriesList() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await Collections.categories.get();

      _categories.clear();

      for (var doc in querySnapshot.docs) {
        try {
          final category = Category.fromMap(doc.data());

          if (category.categoryImage.isEmpty ||
              category.categoryName.isEmpty ||
              category.id.isEmpty) {
            continue;
          }
          _categories.add(Category.fromMap(doc.data()));
        } catch (_) {
          continue;
        }
      }
      
      _categories.shuffle();
    } catch (e) {
      print('❌ Lỗi fetch categories: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<List<Category>> getCategories() async {
    final querySnapshot = await Collections.categories.get();

    _categories.clear();
    for (var doc in querySnapshot.docs) {
      try {
        final category = Category.fromMap(doc.data());
        _categories.add(category);
      } catch (e) {
        print('❌ Bỏ qua dữ liệu không hợp lệ: ${doc.id} - Lỗi: $e');
        continue;
      }
    }

    return _categories;
  }

  Category getCategoryWithId(String categoryId) {
    return _categories.firstWhere((category) => category.id == categoryId);
  }
}
