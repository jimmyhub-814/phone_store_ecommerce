import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/user.dart';

class UserProvider extends ChangeNotifier {
  UserApp? _user;
  UserApp? get user => _user;

  /// Lấy userId từ Supabase mỗi lần cần
  String? get userId => AuthHelper.userId;

  Future<void> setupTokenAndFcm() async {
    final user = AuthHelper.currentUser;
    if (user == null) return;

    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();
    if (token == null) return;

    final userRef = Collections.user.doc(user.uid);

    // Lấy dữ liệu user hiện tại
    final snapshot = await userRef.get();

    List<String> userDeviceTokens = [];

    if (snapshot.exists &&
        snapshot.data()![UserApp.userDeviceTokensField] != null) {
      userDeviceTokens =
          List<String>.from(snapshot.data()![UserApp.userDeviceTokensField]);
    }

    // Thêm token mới nếu chưa có
    if (!userDeviceTokens.contains(token)) {
      userDeviceTokens.add(token);
      await userRef.update({UserApp.userDeviceTokensField: userDeviceTokens});
    }

    // Lắng nghe token refresh
    fcm.onTokenRefresh.listen((newToken) async {
      final snap = await userRef.get();

      List<String> refreshedTokens = [];
      if (snap.exists && snap.data()![UserApp.userDeviceTokensField] != null) {
        refreshedTokens =
            List<String>.from(snap.data()![UserApp.userDeviceTokensField]);
      }

      if (!refreshedTokens.contains(newToken)) {
        refreshedTokens.add(newToken);
        await userRef.update({UserApp.userDeviceTokensField: refreshedTokens});
      }
    });
  }

  // ---------------------------------------------
  // Lấy thông tin user từ bảng 'users'
  // ---------------------------------------------
  Future<UserApp?> getUserInfo() async {
    try {
      if (userId == null) return null;

      final doc = await Collections.user.doc(userId!).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      _user = UserApp.fromMap(doc.data()!);

      notifyListeners();

      return _user;
    } catch (e) {
      debugPrint("User parse error: $e");
      return null;
    }
  }

  // ---------------------------------------------
  // Đăng xuất Firebase
  // ---------------------------------------------
  Future<void> signOut() async {
    final user = AuthHelper.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    final userRef = Collections.user.doc(user.uid);

    final snap = await userRef.get();

    if (snap.exists && token != null) {
      List<String> userDeviceTokens =
          List<String>.from(snap.data()![UserApp.userDeviceTokensField] ?? []);

      userDeviceTokens.remove(token);

      await userRef.update({
        UserApp.userDeviceTokensField: userDeviceTokens,
      });
    }

    await FirebaseAuth.instance.signOut();
  }
}
