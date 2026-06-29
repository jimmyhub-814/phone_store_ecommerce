import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:phone_store/main.dart';
import 'package:phone_store/main/pages/order/order_detail.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('🔔 Background tap payload: ${notificationResponse.payload}');
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize(BuildContext context) async {
    await initLocalNotifications();
    await getDeviceToken();
    configureFCMListeners();
    requestPermission();
  }

  Future<void> requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        Get.snackbar(
          'Notification Permission',
          'Vui lòng bật thông báo trong cài đặt.',
          snackPosition: SnackPosition.BOTTOM,
        );
        Future.delayed(const Duration(seconds: 3)).then((_) {
          AppSettings.openAppSettings(type: AppSettingsType.notification);
        });
      } else {
        print("✅ Notification permission granted");
      }
    } catch (e) {
      print("❌ Error requesting permission: $e");
    }
  }

  Future<void> initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {  
        _handleMessage(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    const channel = AndroidNotificationChannel(
      'default_channel',
      'Thông báo chung',
      description: 'Kênh mặc định cho tất cả thông báo',
      importance: Importance.high,
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  void configureFCMListeners() {
    FirebaseMessaging.onMessage.listen((message) {
      print("🔥 FOREGROUND");
      final title = message.data['title'];
      final body = message.data['body'];

      if (message.data.isEmpty && message.notification == null) {
        print("🚫 Empty message ignored");
        return;
      }

      _localNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'default_channel',
            'Thông báo chung',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print("🔥 OPENED APP");
      _handleMessage(jsonEncode(message.data));
    });
  }

  void _handleMessage(String? payload) async {
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload);
      final orderId = data['orderId']?.toString();
      if (orderId == null || orderId.isEmpty) return;
 
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print("⏳ Chờ auth state...");
        user = await FirebaseAuth.instance
            .authStateChanges()
            .where((u) => u != null)
            .first
            .timeout(const Duration(seconds: 5), onTimeout: () => null);
      }

      if (user == null) {
        print("❌ Không có user, bỏ qua navigate");
        return;
      }

      await user.getIdToken(true);
      await Future.delayed(const Duration(milliseconds: 500));
      print("✅ Token refreshed, navigate...");

      MyApp.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => DetailOrder(orderId: orderId),
        ),
      );
    } catch (e) {
      print("❌ Error handling message: $e");
    }
  }

  Future<void> handleKilledStateMessage() async {
    final message = await FirebaseMessaging.instance.getInitialMessage();
    if (message == null) return;

    print("💀 Killed state message: ${message.data}");

    int attempts = 0;
    while (MyApp.navigatorKey.currentState == null && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 250));
      attempts++;
      print("⏳ Waiting for navigator... attempt $attempts");
    }

    if (MyApp.navigatorKey.currentState == null) {
      print("❌ Navigator vẫn null sau ${attempts * 250}ms, bỏ qua");
      return;
    }

    print("✅ Navigator ready sau ${attempts * 250}ms");
    _handleMessage(jsonEncode(message.data));
  }

  Future<String> getDeviceToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        print("📱 FCM Token: $token");
      } else {
        print("⚠️ getToken() trả về null");
      }

      _messaging.onTokenRefresh.listen((newToken) {
        print("🔄 New FCM Token: $newToken");
      });

      return token ?? '';
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return '';
    }
  }
}
