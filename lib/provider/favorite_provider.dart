import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/provider/product_provider.dart';

class FavoriteProvider extends ChangeNotifier {
  final String user = AuthHelper.userId!;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  List<String> _favorite = [];
  List<String> get favorite => [..._favorite];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  StreamSubscription? _favSub;

  FavoriteProvider() {
    listenFav();
  }

  void listenFav() {
    _favSub?.cancel();

    _favSub = Collections.favorite(user).snapshots().listen((snapshot) {
      final List<String> temp = [];

      for (final doc in snapshot.docs) {
        temp.add(doc.id);
      }

      _favorite = temp;

      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("❌ STREAM ERROR: $e");
    });
  }

  Future<void> toggleFavorite(String productId) async {
    final docRef = Collections.favorite(user).doc(productId);

    final exists = _favorite.contains(productId);

    if (exists) {
      _favorite.remove(productId);
    } else {
      _favorite.add(productId);
    }
    notifyListeners();

    try {
      if (exists) {
        await docRef.delete();
      } else {
        await docRef.set({
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("❌ toggleFavorite error: $e");
    }
  }

  bool checkItem(String id) {
    return _favorite.contains(id);
  }

  Future<void> handleRemove(String productId) async {
    await Collections.favorite(user).doc(productId).delete();
  }

  Future<List<Product>> loadFavoriteProducts(
    List<String> favoriteIds,
    ProductProvider productProvider,
  ) async {
    final products = <Product>[];

    for (String id in favoriteIds) {
      try {
        final product = await productProvider.getProduct(id);
        if (product != null) {
          products.add(product);
        }
      } catch (e) {
        debugPrint("❌ loadFavoriteProducts error: $e");
      }
    }

    return products;
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }
}
