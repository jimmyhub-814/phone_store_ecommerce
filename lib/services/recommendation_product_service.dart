import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/cart.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/models/search_history.dart';
import 'package:phone_store/models/view_history.dart';

class RecommendationService {
  static const double _viewWeight = 3.0;
  static const double _cartWeight = 2.0;
  static const double _searchWeight = 2.0;
  static const double _orderWeight = 1.0;

  Future<List<String>> _getTopCategoryIds(String uid) async {
    final scores = <String, double>{};

    await Future.wait([
      _scoreFromOrders(uid, scores),
      _scoreFromCart(uid, {}, scores),
      _scoreFromSearch(uid, [], scores),
      _scoreFromViewHistory(uid, scores),
    ]);
    print(scores);
    final catScores = scores.entries
        .where((e) => e.key.startsWith('cat_'))
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return catScores
        .take(3)
        .map((e) => e.key.replaceFirst('cat_', ''))
        .toList();
  }

  Future<List<Product>> getRecommendedProducts(
      List<Product> cachedProducts) async {
    final uid = AuthHelper.userId;
    if (uid == null || uid.isEmpty) return cachedProducts;

    final topCategoryIds = await _getTopCategoryIds(uid);
    print('topCategoryIds: $topCategoryIds');
    if (topCategoryIds.isEmpty) return cachedProducts;

    final snapshot = await Collections.products
        .where(Product.categoryIdField, whereIn: topCategoryIds)
        .limit(10)
        .get();

    final recommended = snapshot.docs
        .map((doc) {
          try {
            return Product.fromMap(doc.data());
          } catch (_) {
            return null;
          }
        })
        .whereType<Product>()
        .toList();
    print('recommended count: ${recommended.length}');

    final high = recommended
        .where((p) => topCategoryIds.first == p.categoryId)
        .toList()
      ..shuffle();

    final others = recommended
        .where((p) => topCategoryIds.first != p.categoryId)
        .toList()
      ..shuffle();

    if (recommended.length < 50) {
      final snapshotProduct = await Collections.products
          .limit(recommended.length.isOdd ? 15 : 16)
          .get();

      final recommendedIds = recommended.map((e) => e.id).toSet();

      final products = snapshotProduct.docs
          .map((e) => Product.fromMap(e.data()))
          .where((p) => !recommendedIds.contains(p.id))
          .toList()
        ..shuffle();
      return [...high, ...others, ...products];
    }
    return [...high, ...others];
  }

  Future<void> _scoreFromViewHistory(
    String uid,
    Map<String, double> scores,
  ) async {
    try {
      final snapshot = await Collections.viewHistory(uid).get();
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final productId = data[ViewHistory.productIdField] as String? ?? '';
        final categoryId = data[ViewHistory.categoryIdField] as String? ?? '';
        final viewCount =
            (data[ViewHistory.viewCountField] as num?)?.toDouble() ?? 1;

        final weight = _viewWeight * viewCount.clamp(1, 5);

        if (productId.isNotEmpty) {
          scores['pid_$productId'] = (scores['pid_$productId'] ?? 0) + weight;
        }
        if (categoryId.isNotEmpty) {
          scores['cat_$categoryId'] = (scores['cat_$categoryId'] ?? 0) + weight;
        }
      }
    } catch (e) {
      print('❌ _scoreFromViewHistory: $e');
    }
  }

  Future<void> trackView(
      String uid, Product? product, String? categoryId) async {
    await Collections.viewHistory(uid).doc(product?.id ?? categoryId).set({
      ViewHistory.productIdField: product?.id ?? categoryId,
      ViewHistory.phoneNameField: product?.title ?? '',
      ViewHistory.categoryIdField: categoryId,
      ViewHistory.viewCountField: FieldValue.increment(1),
      ViewHistory.createAtField: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> _scoreFromOrders(
    String uid,
    Map<String, double> scores,
  ) async {
    try {
      final snapshot = await Collections.orders
          .where(
            '${UserOrder.userInfoField}.${OrderUserInfo.userIdField}',
            isEqualTo: uid,
          )
          .get();
      for (final doc in snapshot.docs) {
        final order = UserOrder.fromMap(doc.data());
        for (final item in order.orderProduct) {
          scores['pid_${item.id}'] =
              (scores['pid_${item.id}'] ?? 0) + _orderWeight;
        }
      }
    } catch (e) {
      print('❌ _scoreFromOrders: $e');
    }
  }

  Future<void> _scoreFromCart(
    String uid,
    Map<String, Product> productMap,
    Map<String, double> scores,
  ) async {
    try {
      final snapshot = await Collections.cart(uid).get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final phoneId = data[Cart.productIdField] as String? ?? '';
        if (phoneId.isEmpty) continue;

        scores['pid_$phoneId'] = (scores['pid_$phoneId'] ?? 0) + _cartWeight;

        final categoryId = productMap[phoneId]?.categoryId ?? '';
        if (categoryId.isNotEmpty) {
          scores['cat_$categoryId'] =
              (scores['cat_$categoryId'] ?? 0) + _cartWeight;
        }
      }
    } catch (e) {
      print('❌ _scoreFromCart: $e');
    }
  }

  Future<void> _scoreFromSearch(
    String uid,
    List<Product> allProducts,
    Map<String, double> scores,
  ) async {
    try {
      final snapshot = await Collections.searchHistory(uid).get();

      print('🔍 searchHistory docs: ${snapshot.docs.length}');

      final keywords = snapshot.docs
          .map((d) => (d.data()[SearchHistory.contentField] as String? ?? '')
              .toLowerCase()
              .trim())
          .where((q) => q.isNotEmpty)
          .toSet();

      print('🔍 keywords: $keywords');

      for (final product in allProducts) {
        final titleNorm = product.title.toLowerCase();
        for (final kw in keywords) {
          final matched = titleNorm.contains(kw);
          if (matched) {
            print('✅ match: "$kw" → ${product.title}');
            scores['cat_${product.categoryId}'] =
                (scores['cat_${product.categoryId}'] ?? 0) + _searchWeight;
            scores['pid_${product.id}'] =
                (scores['pid_${product.id}'] ?? 0) + _searchWeight;
          }
        }
      }
    } catch (e) {
      print('❌ _scoreFromSearch: $e');
    }
  }
}
