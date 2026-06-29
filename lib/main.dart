// ===============================
// DART CORE
// ===============================
import 'dart:async';
import 'dart:convert';

// ===============================
// FLUTTER SDK
// ===============================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ===============================
// FIREBASE
// ===============================
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

// ===============================
// THIRD-PARTY PACKAGES
// ===============================
import 'package:app_links/app_links.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:provider/provider.dart';

// ===============================
// APP CONSTANTS / CONFIG
// ===============================
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_fonts.dart';
import 'package:phone_store/app_constants/app_local_messages.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/app_constants/firebase_options.dart';

// ===============================
// MODELS
// ===============================
import 'package:phone_store/models/user.dart';

// ===============================
// PROVIDERS (STATE MANAGEMENT)
// ===============================
import 'package:phone_store/provider/auth_provider.dart';
import 'package:phone_store/provider/category_provider.dart';
import 'package:phone_store/provider/favorite_provider.dart';
import 'package:phone_store/provider/notification_provider.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/provider/user_provider.dart';

// ===============================
// SERVICES
// ===============================
import 'package:phone_store/services/notification_service.dart';

// ===============================
// CUBITS (BLoC STATE MANAGEMENT)
// ===============================
import 'package:phone_store/cubit/conversation_cubit.dart';
import 'package:phone_store/cubit/gemini_ai_cubit.dart';
import 'package:phone_store/cubit/messages_cubit.dart';

// ===============================
// AUTH PAGES
// ===============================
import 'package:phone_store/main/auth/auth_gate.dart';
import 'package:phone_store/main/auth/login.dart';
import 'package:phone_store/main/auth/complete_profile_page.dart';

// ===============================
// MAIN PAGES (HOME / NAVIGATION)
// ===============================
import 'package:phone_store/main/pages/mainPage/home_page.dart';
import 'package:phone_store/main/pages/mainPage/category.dart';
import 'package:phone_store/main/pages/mainPage/search_page.dart';
import 'package:phone_store/main/pages/mainPage/cart_page.dart';
import 'package:phone_store/main/pages/mainPage/phone_profile.dart';

// ===============================
// ORDER FLOW PAGES
// ===============================
import 'package:phone_store/main/pages/order/checkout_order.dart';
import 'package:phone_store/main/pages/order/order_detail.dart';
import 'package:phone_store/main/pages/order/sucess.dart';
import 'package:phone_store/main/pages/order/fail_to_order.dart';
import 'package:phone_store/main/pages/order/cancel_order.dart';
import 'package:phone_store/main/pages/order/change_order_info.dart';
import 'package:phone_store/main/pages/order/shipping_info_page.dart';

// ===============================
// HAMBURGER MENU / USER FEATURES
// ===============================
import 'package:phone_store/main/pages/hamburger/widgets/account.dart';
import 'package:phone_store/main/pages/hamburger/widgets/support.dart';
import 'package:phone_store/main/pages/hamburger/widgets/chat_with_AI.dart';
import 'package:phone_store/main/pages/mainPage/chat_with_seller.dart';
import 'package:phone_store/main/pages/hamburger/widgets/feedback.dart';
import 'package:phone_store/main/pages/hamburger/widgets/order_status.dart';
import 'package:phone_store/main/pages/hamburger/widgets/user_info.dart';

// ===============================
// NOTIFICATIONS
// ===============================
import 'package:phone_store/main/pages/notification/notification.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  final plugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await plugin.initialize(const InitializationSettings(android: androidInit));

  final title = message.data['title'] ?? 'Thông báo mới';
  final body = message.data['body'] ?? '';
  final payload = jsonEncode(message.data);

  await plugin.show(
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
    payload: payload,
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  await dotenv.load(fileName: ".env");
  await Hive.initFlutter();
  await Hive.openBox(AppLocalMessages.localMessages);
  FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // EmailOTP.config(
  //   appName: 'DL Store',
  //   expiry: 60000,
  //   otpType: OTPType.numeric,
  //   emailTheme: EmailTheme.v6,
  //   otpLength: 4,
  //   appEmail: 'dmcompany.com',
  // );

  FlutterNativeSplash.remove();
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<MessageCubit>(
        create: (_) => MessageCubit(),
      ),
      BlocProvider<AIModelCubit>(
        create: (_) => AIModelCubit(),
      ),
      BlocProvider<ConversationCubit>(
        create: (_) => ConversationCubit(),
      ),
    ],
    child: MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => AuthUserProvider()),
      ],
      child: const MyApp(),
    ),
  ));
}

class MyApp extends StatefulWidget {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final NotificationService notificationService = NotificationService();
  StreamSubscription? _sub;
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await FirebaseMessaging.instance.requestPermission();

      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          setupTokenAndFcm();
          context.read<CartProvider>().listenCart();
          context.read<MessageCubit>().emit(const MessageState());
        }
      });
    });
    notificationService.initialize(context);

    notificationService.handleKilledStateMessage();
    _appLinks = AppLinks();
    _appLinks.getInitialLink().then((uri) {
      if (uri != null &&
          uri.scheme == 'phonestore' &&
          uri.host == 'payment-result') {
        _goSuccessOrder();
      }
    });

    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      debugPrint('🔗 Deep link received: $uri');

      if (uri.scheme == 'phonestore' && uri.host == 'payment-result') {
        _goSuccessOrder();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _goSuccessOrder() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        SuccessOrder.routeName,
        (route) => false,
      );
    });
  }

  Future<void> setupTokenAndFcm() async {
    final notificationService = NotificationService();

    final user = AuthHelper.currentUser;
    if (user == null) return;

    final token = await notificationService.getDeviceToken();
    if (token.isEmpty) return;

    final userRef = Collections.user.doc(user.uid);

    try {
      final snapshot = await userRef.get();
      List<String> tokens = [];

      if (snapshot.exists) {
        final data = snapshot.data();

        if (data != null && data[UserApp.userDeviceTokensField] != null) {
          tokens = List<String>.from(
            data[UserApp.userDeviceTokensField],
          );
        }
      }

      if (!tokens.contains(token)) {
        tokens.add(token);
      }

      await userRef.set({
        UserApp.userDeviceTokensField: tokens,
      }, SetOptions(merge: true));
    } catch (e) {
      print("❌ FIRESTORE ERROR: $e");
    }

    FirebaseMessaging.instance.onTokenRefresh
        .distinct()
        .listen((newToken) async {
      try {
        final snap = await userRef.get();
        List<String> tokens = [];

        final data = snap.data();

        if (data != null && data[UserApp.userDeviceTokensField] != null) {
          tokens = List<String>.from(
            data[UserApp.userDeviceTokensField],
          );
        }

        if (!tokens.contains(newToken)) {
          tokens.add(newToken);

          await userRef.set({
            UserApp.userDeviceTokensField: tokens,
          }, SetOptions(merge: true));
        }
      } catch (e) {
        print("❌ TOKEN REFRESH ERROR: $e");
      }
    });
  }

  Widget offlineUI() {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/img/no_internet.png",
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const Text(
              "Oops!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "No Internet Connection\nPlease try again.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(200, 45),
              ),
              child: const Text(
                "Try Again",
                style: TextStyle(
                  color: AppColors.surface,
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Phone Store',
      navigatorKey: MyApp.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.surface,
        fontFamily: AppFonts.publicSans,
      ),
      builder: (context, child) {
        return OfflineBuilder(
          connectivityBuilder: (context, connectivity, widgetChild) {
            final bool isOnline =
                !connectivity.contains(ConnectivityResult.none);

            return isOnline ? widgetChild : offlineUI();
          },
          child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: child!),
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login-page': (context) => const LoginPage(),
        '/home-screen': (context) => const HomePage(),
        '/support-center': (context) => const SupportCenterPage(),
        '/account': (context) => const AccountPage(),
        '/user-info': (context) => const UserInfoPage(),
        '/cart-screen': (context) => const CartPage(),
        '/search_page': (context) => const SearchPage(),
        '/fail-to-order': (context) => const FailOrder(),
        '/cancel-order': (context) => const CancelOrderPage(),
        '/gemini-AI': (context) => const ChatAI(),
        '/success-order': (context) => const SuccessOrder(),
        '/shipping-info-page': (context) => const ShippingInfoPage(),
        '/notification-page': (context) => const NotificationPage(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case CategoryPage.routeName:
            final args = settings.arguments as CategoryPage;

            return MaterialPageRoute(
              builder: (context) => CategoryPage(
                categoryId: args.categoryId,
                categoryName: args.categoryName,
              ),
            );

          case MessagePage.routeName:
            final args = settings.arguments as MessagePage?;

            return MaterialPageRoute(
              builder: (context) => MessagePage(
                product: args?.product,
                productMessage: args?.productMessage,
              ),
            );
          case CompleteProfilePage.routeName:
            final args = settings.arguments as CompleteProfilePage;

            return MaterialPageRoute(
              builder: (context) => CompleteProfilePage(
                userId: args.userId,
                userAccount: args.userAccount,
              ),
            );
          case DetailOrder.routeName:
            final args = settings.arguments as DetailOrder;

            return MaterialPageRoute(
              builder: (context) => DetailOrder(
                orderId: args.orderId,
              ),
            );
          case CheckoutOrder.routeName:
            final args = settings.arguments as CheckoutOrder;

            return MaterialPageRoute(
              builder: (context) => CheckoutOrder(
                orderProduct: args.orderProduct,
                totalPrice: args.totalPrice,
              ),
            );
          case ChangeOrderInfo.routeName:
            final args = settings.arguments as ChangeOrderInfo?;

            return MaterialPageRoute(
              builder: (context) => ChangeOrderInfo(
                id: args?.id,
                userPhone: args?.userPhone,
                userName: args?.userName,
                userAddress: args?.userAddress,
              ),
            );
          case PhoneProfilePage.routeName:
            final args = settings.arguments as PhoneProfilePage;

            return MaterialPageRoute(
              builder: (context) => PhoneProfilePage(
                id: args.id,
              ),
            );

          case FeedbackScreen.routeName:
            final args = settings.arguments as FeedbackScreen;

            return MaterialPageRoute(
              builder: (context) => FeedbackScreen(
                orderId: args.orderId,
              ),
            );
          case OrderStatusPage.routeName:
            final args = settings.arguments as OrderStatusPage;

            return MaterialPageRoute(
              builder: (context) => OrderStatusPage(
                index: args.index,
              ),
            );
          default:
            return null;
        }
      },
    );
  }
}
