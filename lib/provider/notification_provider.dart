import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/notifications.dart';

class NotificationProvider extends ChangeNotifier {
  final userId = AuthHelper.userId;
// USER Notification

//ADD TO Notification

  void readNotification(String id) async {
    Collections.notifications(userId!).doc(id).set(
      {NotificationModel.readField: true},
      SetOptions(merge: true),
    );

    notifyListeners();
  }

  Future<void> uploadNotification(NotificationModel noti) async {
    await Collections.notifications(userId!).doc(noti.id).set(noti.toMap());

    notifyListeners();
  }

//SAVE DATA
  void handleRemove(String id) async {
    // // Tìm thông báo cần xóa
    // for (int i = 0; i < notification.length; i++) {
    //   _notification.removeWhere(
    //     (item) => notification.contains(item.id),
    //   );
    // }

    // Xóa khỏi Firestore
    await Collections.notifications(userId!).doc(id).delete();

    notifyListeners();
  }

  Stream<List<NotificationModel>> getNotificationList() {
    try {
      return Collections.notifications(userId!).snapshots().map(
        (snapshot) {
          if (snapshot.docs.isEmpty) {
            print("⚠️ Không có tài liệu thông báo nào cho user: $userId");
            return [];
          }

          return snapshot.docs.map((doc) {
            try {
              return NotificationModel.fromMap(
                Map<String, dynamic>.from(
                  doc.data(),
                ),
              );
            } catch (e) {
              print('❌ Lỗi parse doc ${doc.id}: $e');
              rethrow;
            }
          }).toList();
        },
      );
    } catch (e) {
      print('Lỗi khi lấy danh sách thông báo: $e');
      return const Stream.empty();
    }
  }

  void readAllNotification() async {
    try {
      final snapshot = await Collections.notifications(userId!).get();

      if (snapshot.docs.isEmpty) {
        print("Không có tài liệu thông báo nào cho user: $userId");
        return;
      }

      print('Tổng số nhóm thông báo lấy được: ${snapshot.docs.length}');

      for (var doc in snapshot.docs) {
        await doc.reference.set({'read': true}, SetOptions(merge: true));
      }

      print('Tất cả thông báo đã được đánh dấu là đã đọc');
    } catch (e) {
      print('Lỗi khi lấy danh sách thông báo: $e');
    }
  }
}
