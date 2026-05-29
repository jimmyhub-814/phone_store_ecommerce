import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/firestore_collections.dart'; 
import 'package:phone_store/models/category.dart';

class CategoryProvider extends ChangeNotifier {
  List<Category> _categories = [];
  List<Category> get categories => [..._categories];
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> fetchCategoriesList( ) async {
    _isLoading = true;
    notifyListeners();
    _categories = await getCategories();

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
