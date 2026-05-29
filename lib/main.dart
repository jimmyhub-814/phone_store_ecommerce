import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_fonts.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/cubit/messages_cubic.dart';
import 'package:phone_store/main/auth/auth_gate.dart';
import 'package:phone_store/firebase_options.dart';
import 'package:phone_store/main/auth/link_phone.dart';
import 'package:phone_store/main/auth/otpChangeEmail.dart';
import 'package:phone_store/main/auth/otp_reset_password.dart';
import 'package:phone_store/main/pages/home/hamburger/account.dart';
import 'package:phone_store/main/pages/home/hamburger/failToOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/cancelOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/changeInfoOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/chatAI.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/chatBox.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/detailOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/enterNewEmail.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/feedBack.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/order_info.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/order_status.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/user_info.dart';
import 'package:phone_store/main/pages/home/mainPage/category.dart';
import 'package:phone_store/main/auth/login_page.dart';
import 'package:phone_store/main/pages/home/hamburger/permission/permission_page.dart';
import 'package:phone_store/main/pages/home/hamburger/support.dart';
import 'package:phone_store/main/pages/home/mainPage/home_page.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/changePassPage.dart';
import 'package:phone_store/main/pages/home/mainPage/buyItem.dart';
import 'package:phone_store/main/pages/home/mainPage/home_body.dart';
import 'package:phone_store/main/pages/home/mainPage/phone_profile.dart';
import 'package:phone_store/main/pages/home/hamburger/sucess.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/chat.dart';
import 'package:phone_store/main/pages/home/mainPage/search_page.dart';
import 'package:phone_store/main/pages/home/mainPage/cartPage.dart';
import 'package:phone_store/models/notifications.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/provider/category_provider.dart';
import 'package:phone_store/provider/favorite_provider.dart';
import 'package:phone_store/provider/messageAI_provider.dart';
import 'package:phone_store/provider/notification_provider.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:phone_store/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage notification) async {
  await Firebase.initializeApp();

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

  const initSettings = InitializationSettings(android: androidInit);

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  final title = notification.data[NotificationList.titleField];
  final body = notification.data[NotificationList.bodyField];

  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    const NotificationDetails(
      android: AndroidNotificationDetails(
        'default_channel',
        'High Importance Notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
    ),
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
  await Hive.openBox('local_messages');
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
      BlocProvider(
        create: (_) => MessageCubit(),
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
        ChangeNotifierProvider(create: (_) => MessageAIProvider()),
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
      notificationService.checkInitialMessage();
      Future.microtask(() {
        initServices();
      });
    });

    _appLinks = AppLinks();
    _appLinks.getInitialLink().then((uri) {
      if (uri != null &&
          uri.scheme == 'phonestore' &&
          uri.host == 'payment-result') {
        _goCompleteOrder();
      }
    });

    _sub = _appLinks.uriLinkStream.listen((Uri uri) {
      debugPrint('🔗 Deep link received: $uri');

      if (uri.scheme == 'phonestore' && uri.host == 'payment-result') {
        _goCompleteOrder();
      }
    });
  }

  Future<void> initServices() async {
    await Future.wait([
      setupTokenAndFcm(),
      notificationService.initialize(context),
    ]);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _goCompleteOrder() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
        CompleteOrder.routeName,
        (route) => false,
      );
    });
  }

  Future<void> setupTokenAndFcm() async {
    final notificationService = NotificationService();

    // Lấy user hiện tại từ Firebase Auth
    final user = AuthHelper.currentUser;
    if (user == null) return;

    // Lấy FCM token
    final token = await notificationService.getDeviceToken();
    print("Token:$token");
    if (token.isEmpty) return;

    final uid = user.uid;
    final userRef = Collections.user.doc(uid);

    // Lấy token hiện tại trong Firestore
    final snapshot = await userRef.get();

    List<String> tokens = [];

    if (snapshot.exists &&
        snapshot.data()![UserApp.userDeviceTokensField] != null) {
      tokens =
          List<String>.from(snapshot.data()![UserApp.userDeviceTokensField]);
    }

    // Nếu token mới chưa có thì thêm vào array
    if (!tokens.contains(token)) {
      tokens.add(token);

      await userRef.update({
        UserApp.userDeviceTokensField: tokens,
      });
    }

    // Lắng nghe token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final snap = await userRef.get();

      List<String> refreshedTokens = [];

      if (snap.exists && snap.data()![UserApp.userDeviceTokensField] != null) {
        refreshedTokens =
            List<String>.from(snap.data()![UserApp.userDeviceTokensField]);
      }

      if (!refreshedTokens.contains(newToken)) {
        refreshedTokens.add(newToken);

        await userRef.update({
          UserApp.userDeviceTokensField: refreshedTokens,
        });
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
          fontFamily: AppFonts.publicSans),
      builder: (context, child) {
        return OfflineBuilder(
          connectivityBuilder: (context, connectivity, widgetChild) {
            final bool isOnline =
                !connectivity.contains(ConnectivityResult.none);

            //   return widgetChild;
            return isOnline ? widgetChild : offlineUI();
          },
          child: child!,
        );
      },
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login_page': (context) => const LoginPage(),
        '/homePage': (context) => const HomePage(),
        '/homeBody': (context) => const HomeBody(),
        '/policy': (context) => const PolicyHomePage(),
        '/supportCenter': (context) => const SupportCenterPage(),
        '/account': (context) => const AccountPage(),
        '/userInfo': (context) => const UserInfoPage(),
        '/order_info': (context) => const OrderInfoPage(),
        '/cartPage': (context) => const CartPage(),
        '/search_page': (context) => const SearchPage(),
        '/completeOrder': (context) => const CompleteOrder(),
        '/failOrder': (context) => const FailOrder(),
        '/cancelOrder': (context) => const CancelOrderPage(),
        '/messagePage': (context) => const MessagePage(),
        '/chatBoxPage': (context) => const ChatBoxPage(),
        '/chatAI': (context) => const ChatAI(),
        '/linkPhone': (context) => const LinkPhonePage(),
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
          case DetailOrder.routeName:
            final args = settings.arguments as DetailOrder;

            return MaterialPageRoute(
              builder: (context) => DetailOrder(
                orderId: args.orderId,
              ),
            );
          case OtpChangeEmailPage.routeName:
            final args = settings.arguments as OtpChangeEmailPage;

            return MaterialPageRoute(
              builder: (context) => OtpChangeEmailPage(
                newEmail: args.newEmail,
                password: args.password,
              ),
            );
          case OtpResetPassPage.routeName:
            final args = settings.arguments as OtpResetPassPage;

            return MaterialPageRoute(
              builder: (context) => OtpResetPassPage(
                email: args.email,
              ),
            );
          case BuyItem.routeName:
            final args = settings.arguments as BuyItem;

            return MaterialPageRoute(
              builder: (context) => BuyItem(
                orderProduct: args.orderProduct,
                totalPrice: args.totalPrice,
              ),
            );
          case ChangeOrderInfo.routeName:
            final args = settings.arguments as ChangeOrderInfo;

            return MaterialPageRoute(
              builder: (context) => ChangeOrderInfo(
                userPhone: args.userPhone,
                userName: args.userName,
                userAddress: args.userAddress,
              ),
            );
          case PhoneProfilePage.routeName:
            final args = settings.arguments as PhoneProfilePage;

            return MaterialPageRoute(
              builder: (context) => PhoneProfilePage(
                id: args.id,
              ),
            );
          case ChangepassPage.routeName:
            final args = settings.arguments as ChangepassPage;

            return MaterialPageRoute(
              builder: (context) => ChangepassPage(
                email: args.email,
              ),
            );
          case EnterNewEmail.routeName:
            final args = settings.arguments as EnterNewEmail;

            return MaterialPageRoute(
              builder: (context) => EnterNewEmail(
                email: args.email,
                pass: args.pass,
              ),
            );
          case FeedBackPage.routeName:
            final args = settings.arguments as FeedBackPage;

            return MaterialPageRoute(
              builder: (context) => FeedBackPage(
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
