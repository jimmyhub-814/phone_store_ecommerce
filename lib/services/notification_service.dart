import 'dart:convert';
import 'dart:io';
import 'package:app_settings/app_settings.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:phone_store/main.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/detailOrder.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  print('🔔 Notification tapped (background): ${notificationResponse.payload}');
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

  /// Xin quyền thông báo
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
          'Please enable notifications in settings.',
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

  /// Khởi tạo local notification
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
        print("👉 Notification tapped with payload: ${response.payload}");
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

  /// LISTENER FCM
  void configureFCMListeners() {
    // Foreground
    FirebaseMessaging.onMessage.listen((message) {
      final title = message.notification?.title ?? message.data['title'];
      final body = message.notification?.body ?? message.data['body'];

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

    // Background tap
     FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final orderId = message.data['orderId'];
      if (orderId != null) {
        Future.delayed(const Duration(milliseconds: 500), () {
          MyApp.navigatorKey.currentState?.pushNamed(
            DetailOrder.routeName,
            arguments: DetailOrder(orderId: orderId.toString()),
          );
        });
      }
    });
  }

// ✅ Tách riêng hàm này
Future<void> checkInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    if (message != null) {
      await Future.delayed(const Duration(milliseconds: 800));

      // ✅ Lấy đúng field
      final orderId = message.data['orderId'] ?? message.data['id'];
      if (orderId != null) {
        MyApp.navigatorKey.currentState?.pushNamed(
          DetailOrder.routeName,
          arguments: DetailOrder(orderId: orderId.toString()),
        );
      }
    }
  }

  /// SHOW LOCAL NOTIFICATION

  /// XỬ LÝ PAYLOAD + ĐIỀU HƯỚNG
  void _handleMessage(String? payload) {
    if (payload == null || payload.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(payload);

      print("📌 Payload decode thành công: $data");

      final orderId = data['orderId'];

      if (orderId != null) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          Get.to(
            () => DetailOrder(
              orderId: orderId,
            ),
          );
        });
      }
    } catch (e) {
      print("❌ Error decoding payload: $e");
    }
  }

  void handleMessageFromOutside(Map<String, dynamic> data) {
    final orderId = data['orderId'];
    if (orderId != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        MyApp.navigatorKey.currentState?.pushNamed(
          DetailOrder.routeName,
          arguments: DetailOrder(orderId: orderId),
        );
      });
    }
  }

  /// Lấy FCM token
  Future<String> getDeviceToken() async {
    try {
      print("🔍 Đang gọi _messaging.getToken()");
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
