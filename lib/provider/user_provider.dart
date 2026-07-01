import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main.dart';
import 'package:phone_store/models/user.dart';

class UserProvider extends ChangeNotifier {
  UserApp? _user;
  UserApp? get user => _user;
  String? get userId => AuthHelper.userId;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<User?>? _authSubscription;

  UserProvider() {
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((firebaseUser) {
      if (firebaseUser != null) {
        getUserInfo();
      } else {
        _user = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void updateLocalUser(UserApp user) {
    _user = user;
    notifyListeners();
  }

  Future<UserApp?> getUserInfo() async {
    debugPrint("===== getUserInfo =====");
    if (userId == null) {
      _isLoading = false;
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await Collections.user.doc(userId!).get();

      if (!doc.exists || doc.data() == null) {
        _isLoading = false;
        notifyListeners();
        return null;
      }

      _user = UserApp.fromMap(doc.data()!);

      _isLoading = false;
      notifyListeners();

      return _user;
    } catch (e) {
      _isLoading = false;
      notifyListeners();

      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> setDefaultShippingInfo(String id) async {
    if (_user == null) return;

    final currentList = List<ShippingInfo>.from(_user!.shippingInfo);

    currentList.sort((a, b) {
      if (a.id == id) return -1;
      if (b.id == id) return 1;
      return 0;
    });

    _user = _user!.copyWith(shippingInfo: currentList);
    notifyListeners();

    try {
      await Collections.user.doc(_user!.id).update({
        'shippingInfo': currentList.map((e) => e.toMap()).toList(),
      });
    } catch (e) {
      print('❌ setDefaultShippingInfo error: $e');
    }
  }

  Future<void> saveShippingInfo(
      BuildContext context, ShippingInfo shippingInfo) async {
    if (shippingInfo.fullName.isEmpty ||
        shippingInfo.phone.isEmpty ||
        shippingInfo.address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đầy đủ thông tin'),
        ),
      );
      return;
    }

    try {
      final docRef = Collections.user.doc(AuthHelper.userId);

      final doc = await docRef.get();

      List<dynamic> shippingList =
          List.from(doc.data()?[UserApp.shippingInfoField] ?? []);

      if (shippingInfo.id.isEmpty) {
        shippingList.add(shippingInfo.toMap());
      } else {
        final index = shippingList.indexWhere(
          (item) => item['id'] == shippingInfo.id,
        );

        final updatedShipping = ShippingInfo(
          id: shippingInfo.id,
          fullName: shippingInfo.fullName,
          phone: shippingInfo.phone,
          address: shippingInfo.address,
        );

        if (index != -1) {
          shippingList[index] = updatedShipping.toMap();
        } else {
          shippingList.add(updatedShipping.toMap());
        }
      }

      await docRef.update({
        UserApp.shippingInfoField: shippingList,
      });
      await getUserInfo();
      notifyListeners();
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            shippingInfo.id.isEmpty
                ? 'Thêm địa chỉ thành công'
                : 'Cập nhật địa chỉ thành công',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: $e'),
        ),
      );
    }
  }

  Future<void> deleteShippingInfo(String id) async {
    final docRef = Collections.user.doc(AuthHelper.userId);

    final doc = await docRef.get();

    List<dynamic> shippingList =
        List.from(doc.data()?[UserApp.shippingInfoField] ?? []);

    shippingList.removeWhere(
      (e) => e['id'] == id,
    );

    await docRef.update({
      UserApp.shippingInfoField: shippingList,
    });

    await getUserInfo();

    notifyListeners();
  }

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
    _user = null;

    notifyListeners();
    MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }
}
