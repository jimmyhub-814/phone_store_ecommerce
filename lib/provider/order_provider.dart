import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/order.dart';

class OrderProvider extends ChangeNotifier {
  List<UserOrder> _orders = [];
  List<UserOrder> get orders => [..._orders];

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  void loadOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await Collections.orders
          .where("${UserOrder.userInfoField}.${OrderUserInfo.userIdField}",
              isEqualTo: AuthHelper.userId)
          .orderBy(
              '${UserOrder.orderInfoField}.${OrderInfo.lastStatusTimeField}',
              descending: true)
          .get();

      final List<UserOrder> temp = [];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          temp.add(UserOrder.fromMap(data));
        } catch (e) {
          print("❌ DOC LỖI: ${doc.id}");
          print("DATA: ${doc.data()}");
          print("ERROR: $e");
        }
      }

      _orders = temp;
    } catch (e) {
      print("❌ loadOrders error: $e");
    }

    _isLoading = false;
    notifyListeners();
  }

  Stream<List<UserOrder>> listenOrders() {
    return Collections.orders
        .where("${UserOrder.userInfoField}.${OrderUserInfo.userIdField}",
            isEqualTo: AuthHelper.userId)
        .orderBy('${UserOrder.orderInfoField}.${OrderInfo.lastStatusTimeField}',
            descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserOrder.fromMap(doc.data());
      }).toList();
    });
  }

  Future<UserOrder?> getUserOrder(String orderId) async {
    try {
      final doc = await Collections.orders.doc(orderId).get();

      if (!doc.exists || doc.data() == null) return null;

      return UserOrder.fromMap(doc.data()!);
    } catch (e) {
      print("❌ getUserOrder error: $e");
      return null;
    }
  }

  Future<bool> uploadOrderToFirebase(UserOrder order) async {
    try {
      await Collections.orders.doc(order.id).set(order.toMap());

      return true;
    } catch (e) {
      print('❌ upload order error: $e');
      return false;
    }
  }

  Future<void> updateOrder(String orderId, String status) async {
    final statusHistory = StatusHistory(
        status: status, updateBy: UpdateBy.user.name, time: Timestamp.now());
    try {
      await Collections.orders.doc(orderId).update({
        "${UserOrder.orderInfoField}.${OrderInfo.orderStatusField}": status,
        UserOrder.statusHistoryField:
            FieldValue.arrayUnion([statusHistory.toMap()]),
      });
    } catch (e) {
      print("❌ updateOrder error: $e");
    }
  }
}
