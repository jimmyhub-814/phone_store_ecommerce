import 'package:cloud_firestore/cloud_firestore.dart';

class Collections {
  const Collections._();
  static final products = FirebaseFirestore.instance.collection('products');

  static final categories = FirebaseFirestore.instance.collection('categories');

  static final user = FirebaseFirestore.instance.collection('users');

  static final orders = FirebaseFirestore.instance.collection('orders');

  static final registeredPhones =
      FirebaseFirestore.instance.collection('registered_phone');

  static final conversations =
      FirebaseFirestore.instance.collection('conversations');

  static CollectionReference<Map<String, dynamic>> messages(String messageId) =>
      Collections.conversations.doc(messageId).collection('messages');

  static CollectionReference<Map<String, dynamic>> cart(String userId) =>
      Collections.user.doc(userId).collection('cart');

  static CollectionReference<Map<String, dynamic>> searchHistory(
          String userId) =>
      Collections.user.doc(userId).collection('searchHistory');

  static CollectionReference<Map<String, dynamic>> viewHistory(String userId) =>
      Collections.user.doc(userId).collection('viewHistory');

  static CollectionReference<Map<String, dynamic>> favorite(String userId) =>
      Collections.user.doc(userId).collection('favorite');

  static CollectionReference<Map<String, dynamic>> feedBacks(
          String productId) =>
      Collections.products.doc(productId).collection('feedBacks');

  static CollectionReference<Map<String, dynamic>> notifications(
          String userId) =>
      Collections.user.doc(userId).collection('notifications');
}
