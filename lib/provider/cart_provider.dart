import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/cart.dart';
import 'dart:async';

import 'package:phone_store/provider/product_provider.dart';
import 'package:provider/provider.dart';

class CartProvider extends ChangeNotifier {
  StreamSubscription? _cartSub;
  StreamSubscription<User?>? _authSub;
  List<Cart> _cart = [];
  List<Cart> get cart => [..._cart];

  final Map<String, bool> _selectedItems = {};
  Map<String, bool> get selectedItems => {..._selectedItems};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  void listenCart() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint("🔍 listenCart userId = $userId");

    if (userId == null) {
      debugPrint("❌ listenCart ABORT: userId null");
      return;
    }

    _cartSub?.cancel();
    _isLoading = true;
    notifyListeners();

    _cartSub = Collections.cart(userId).snapshots().listen(
      (snapshot) {
        debugPrint("📦 CART UPDATE: ${snapshot.docs.length}");

        final List<Cart> temp = [];
        for (final doc in snapshot.docs) {
          final data = doc.data();
          if (data[Cart.productIdField] == null ||
              data[Cart.variantsIdField] == null) {
            debugPrint("❌ SKIP INVALID CART: ${doc.id}");
            continue;
          }
          temp.add(Cart.fromMap(data));
        }

        _cart = temp;
        _isLoading = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint("❌ CART STREAM ERROR: $error");
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> fetchCartList() async {
    _isLoading = true;
    notifyListeners();

    final snapshot = await Collections.cart(AuthHelper.userId!).get();

    _cart = snapshot.docs.map((doc) {
      return Cart.fromMap(doc.data());
    }).toList();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCart(
      String productId, int quantity, String variantsId) async {
    final docId = "$productId-$variantsId";

    final docRef = Collections.cart(AuthHelper.userId!).doc(docId);

    final doc = await docRef.get();

    if (doc.exists) {
      await docRef.update({
        Cart.quantityField: FieldValue.increment(quantity),
      });
    } else {
      await docRef.set({
        Cart.idField: docId,
        Cart.productIdField: productId,
        Cart.variantsIdField: variantsId,
        Cart.quantityField: quantity,
      });
    }
  }

  Future<void> increase(String id) async {
    await Collections.cart(AuthHelper.userId!).doc(id).update({
      Cart.quantityField: FieldValue.increment(1),
    });
  }

  Future<void> removeFromCart(String id) async {
    await Collections.cart(AuthHelper.userId!).doc(id).delete();
  }

  Future<void> decrease(String id) async {
    final docRef = Collections.cart(AuthHelper.userId!).doc(id);

    final doc = await docRef.get();

    if (doc.exists && doc[Cart.quantityField] > 1) {
      await docRef.update({
        Cart.quantityField: FieldValue.increment(-1),
      });
    }
  }

  Future<void> deleteProductById() async {
    final selectedKeys =
        _selectedItems.entries.where((e) => e.value).map((e) => e.key).toList();

    if (selectedKeys.isEmpty) return;

    final batch = firestore.batch();
    for (var key in selectedKeys) {
      batch.delete(Collections.cart(AuthHelper.userId!).doc(key));
    }
    await batch.commit();
  }

  Future<void> deleteProductWhenBuy(List<String> buyItems) async {
    if (buyItems.isEmpty) return;

    final batch = firestore.batch();
    for (final id in buyItems) {
      batch.delete(Collections.cart(AuthHelper.userId!).doc(id));
    }
    await batch.commit();
  }

  void toggleSelection(String id) {
    _selectedItems[id] = !(_selectedItems[id] ?? false);
    notifyListeners();
  }

  String getTotalSelection() {
    return _selectedItems.values.where((v) => v == true).length.toString();
  }

  Future<double> getTotalItemCount(BuildContext context) async {
    double total = 0;
    final productProvider = context.read<ProductProvider>();

    for (var cartItem in _cart) {
      if (_selectedItems[cartItem.id] != true) continue;

      final product = await productProvider.getProduct(cartItem.productId);

      if (product == null) continue;

      final variant = product.listVariants.firstWhere(
        (v) => v.id == cartItem.variantsId,
        orElse: () => product.listVariants.first,
      );

      final price = variant.phonePrice -
          (variant.phonePrice * variant.phoneDiscount / 100);

      total += cartItem.quantity * price;
    }

    return total.roundToDouble();
  }

  void clearSelection() {
    _selectedItems.clear();
  }
}
