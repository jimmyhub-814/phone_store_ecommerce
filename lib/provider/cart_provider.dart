import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/cart.dart';
import 'package:phone_store/models/products.dart';
import 'dart:async';

class CartProvider extends ChangeNotifier {
  final user = AuthHelper.userId;
  StreamSubscription? _cartSub;
  List<Cart> _cart = [];
  List<Cart> get cart => [..._cart];

  List<Product> _productList = [];
  List<Product> get productList => [..._productList];

  final Map<String, bool> _selectedItems = {};
  Map<String, bool> get selectedItems => {..._selectedItems};

  Map<String, int> localQuantity = {};

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  CartProvider() {
    listenCart();
    init();
  }
  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    await getAllProducts();

    _isLoading = false;
    notifyListeners();
  }

  void listenCart() {
    print("🔥 listenCart CALLED");

    _cartSub?.cancel();

    try {
      _cartSub = Collections.cart(user!).snapshots().listen((snapshot) {
        print("📦 CART UPDATE: ${snapshot.docs.length}");

        final List<Cart> temp = [];

        for (final doc in snapshot.docs) {
          final data = doc.data();

          if (data[Cart.productIdField] == null ||
              data[Cart.variantsIdField] == null) {
            print("❌ SKIP INVALID CART: ${doc.id}");
            continue;
          }

          temp.add(Cart.fromMap(data));
        }

        _cart = temp;

        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      print("❌ STREAM ERROR: $e");
    }
  }

  // -----------------------
  // GET ALL PRODUCTS
  // -----------------------
  Future<List<Product>> getAllProducts() async {
    _isLoading = true;

    final querySnapshot = await Collections.products.get();
    _productList.clear();

    for (var doc in querySnapshot.docs) {
      try {
        _productList.add(Product.fromMap(doc.data()));
      } catch (e) {
        print("❌ Lỗi parse product: ${doc.id} - $e");
      }
    }

    _isLoading = false;
    return _productList;
  }

  // -----------------------
  // FETCH CART LIST
  // -----------------------


  Future<void> fetchCartList() async {
    _isLoading = true;
    notifyListeners();

    final snapshot = await Collections.cart(user!).get();

    _cart = snapshot.docs.map((doc) {
      return Cart.fromMap(doc.data());
    }).toList();

    _productList = await getAllProducts();

    _isLoading = false;
    notifyListeners();
  }
  // -----------------------
  // ADD TO CART

  Future<void> addCart(
      String productId, int quantity, String variantsId) async {
    final docId = "$productId-$variantsId";

    final docRef = Collections.cart(user!).doc(docId);

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
    await Collections.cart(user!).doc(id).update({
      Cart.quantityField: FieldValue.increment(1),
    });
  }

  // -----------------------
  // REMOVE ITEM
  // -----------------------
  Future<void> removeFromCart(String id) async {
    await Collections.cart(user!).doc(id).delete();
  }

  // // -----------------------
  // // INCREASE QUANTITY
  // // -----------------------
  void increaseLocal(String productId, String variantsId) {
    int index = _cart.indexWhere(
        (c) => c.productId == productId && c.variantsId == variantsId);
    if (index == -1) return;

    _cart[index].quantity++;
    notifyListeners();
  }

  // -----------------------
  // DECREASE QUANTITY
  // -----------------------
  Future<void> decrease(String id) async {
    final docRef = Collections.cart(user!).doc(id);

    final doc = await docRef.get();

    if (doc.exists && doc[Cart.quantityField] > 1) {
      await docRef.update({
        Cart.quantityField: FieldValue.increment(-1),
      });
    }
  }

  // -----------------------
  // DELETE SELECTED ITEMS
  // -----------------------
  Future<void> deleteProductById() async {
    final selectedKeys =
        _selectedItems.entries.where((e) => e.value).map((e) => e.key).toList();

    for (var key in selectedKeys) {
      await Collections.cart(user!).doc(key).delete();
    }
  }

  // -----------------------
  // DELETE WHEN BUY
  // -----------------------
  Future<void> deleteProductWhenBuy(List<String> buyItems) async {
    if (buyItems.isEmpty) return;

    _cart = _cart.where((item) {
      return !buyItems.contains(item.id);
    }).toList();
  }

  // -----------------------
  // CHECKBOX
  // -----------------------
  void toggleSelection(String id) {
    _selectedItems[id] = !(_selectedItems[id] ?? false);
    notifyListeners();
  }

  String getTotalSelection() {
    return _selectedItems.values.where((v) => v == true).length.toString();
  }

  // -----------------------
  // TOTAL PRICE
  // -----------------------
  double getTotalItemCount() {
    double total = 0;

    for (var cartItem in _cart) {
      if (_selectedItems[cartItem.id] != true) continue;

      final product =
          _productList.firstWhere((p) => p.id == cartItem.productId);
      final variant =
          product.listVariants.firstWhere((v) => v.id == cartItem.variantsId);

      final price = variant.phonePrice -
          (variant.phonePrice * variant.phoneDiscount / 100);

      total += cartItem.quantity * price;
    }

    return total.roundToDouble();
  }
}
