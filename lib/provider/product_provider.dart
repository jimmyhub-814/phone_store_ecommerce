import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/feedback.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/services/recommendation_product_service.dart';

class ProductProvider extends ChangeNotifier {
  final List<Product> _products = [];
  List<Product> get products => [..._products];
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  final _recommendationService = RecommendationService();
  List<Product>? _recommendedProducts;
  List<Product> get recommendedProducts => _recommendedProducts ?? _products;
  bool _recommendationsLoaded = false;

  Future<void> loadRecommendations() async {
    print(
        '🚀 loadRecommendations called, products: ${_products.length}, loaded: $_recommendationsLoaded');
    if (_products.isEmpty || _recommendationsLoaded) return;
    if (_products.isEmpty || _recommendationsLoaded) {
      return;
    }
    _recommendationsLoaded = true;
    try {
      _recommendedProducts =
          await _recommendationService.getRecommendedProducts(_products);
    } catch (e, s) {
      print(e);
      print(s);
    }
    print('_recommendedProducts: ${_recommendedProducts?.length}');
    notifyListeners();
  }

  void resetRecommendations() {
    _recommendedProducts = null;
    _recommendationsLoaded = false;
  }

  Future<void> fetchProductsList({bool forceRefresh = false}) async {
    if (_isLoading) return;
    if (_products.isNotEmpty && !forceRefresh) return;
    _isLoading = true;
    notifyListeners();
    _isLoading = true;
    notifyListeners();

    try {
      final querySnapshot = await Collections.products.get();

      _products.clear();

      for (var doc in querySnapshot.docs) {
        try {
          final product = Product.fromMap(doc.data());

          if (product.listVariants.isEmpty ||
              product.mainImage.isEmpty ||
              product.title.isEmpty) {
            continue;
          }

          _products.add(product);
        } catch (_) {
          continue;
        }
      }
    } catch (e) {
      print('❌ Lỗi fetch products: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Product?> getProduct(String id) async {
    _isLoading = true;

    try {
      final productRef = Collections.products.doc(id);
      final docSnapshot = await productRef.get();

      if (!docSnapshot.exists) {
        return null;
      }

      final data = docSnapshot.data();
      if (data == null) return null;

      final product = Product.fromMap(data);
      return product;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm với id $id: $e');
      return null;
    } finally {
      _isLoading = false;
    }
  }

  Future<List<Product>> getProductsInCategory(String categoryId) async {
    try {
      final querySnapshot = await Collections.products
          .where(Product.categoryIdField, isEqualTo: categoryId)
          .get();

      List<Product> list = [];

      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data());
        list.add(product);
      }

      return list;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm theo danh mục: $e');
      return [];
    }
  }

  Future<List<Product>> relatedItem(String id, String categoryId) async {
    try {
      final querySnapshot = await Collections.products
          .where(Product.categoryIdField, isEqualTo: categoryId)
          .get();

      List<Product> relatedProducts = [];

      for (var doc in querySnapshot.docs) {
        final product = Product.fromMap(doc.data());

        if (product.id != id) {
          relatedProducts.add(product);
        }
      }
      print('Related products found: ${relatedProducts.length}');

      relatedProducts.shuffle();
      return relatedProducts;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm liên quan: $e');
      return [];
    }
  }

  Future<void> uploadFeedBackOrder(
      String productId, FeedBack feedBack, String id) async {
    final feedbackRef = Collections.feedBacks(productId).doc(id);

    await feedbackRef.set(feedBack.toMap());
  }

  Future<List<FeedBack>> getFeedBack(String productId) async {
    List<FeedBack> feedbackList = [];

    try {
      final querySnapshot = await Collections.feedBacks(productId).get();

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        try {
          final feedback = FeedBack.fromMap(data);
          feedbackList.add(feedback);
        } catch (e) {
          debugPrint('❌ Lỗi khi parse feedback tại $productId - ${doc.id}: $e');
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy feedback cho sản phẩm $productId: $e');
    }

    return feedbackList;
  }

  List<Product> getResultOfSearch(String query) {
    if (query.trim().isEmpty) return [];

    final keywords = query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((k) => k.isNotEmpty)
        .toList();

    return products.where((product) {
      final name = _normalize(product.title);

      return keywords.every((word) => name.contains(word));
    }).toList()
      ..sort((a, b) {
        final aScore = _scoreMatch(a.title, keywords);
        final bScore = _scoreMatch(b.title, keywords);
        return bScore.compareTo(aScore);
      });
  }

  String _normalize(String text) {
    const vietnamese =
        'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const latin =
        'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    String result = text.toLowerCase();
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i].toLowerCase());
    }
    return result;
  }

  int _scoreMatch(String title, List<String> keywords) {
    final normalized = _normalize(title);
    int score = 0;

    for (final word in keywords) {
      if (normalized.startsWith(word)) {
        score += 2;
      } else if (normalized.contains(word)) score += 1;
    }
    return score;
  }
}
