import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/main/auth/logout.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';

import 'package:phone_store/models/order.dart';
import 'package:phone_store/main/pages/hamburger/widgets/order_status.dart';
import 'package:phone_store/main/pages/hamburger/widgets/user_info.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:provider/provider.dart';

class AccountPage extends StatefulWidget {
  static const routeName = '/account';
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
  }

  Future<void> loadData() async {
    if (AuthHelper.currentUser != null) {
      context.read<UserProvider>().getUserInfo();
      context.read<OrderProvider>().loadOrders();
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Tài khoản",
          style: TextStyle(color: AppColors.surface, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        leading: AppbarIcon(),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          final user = provider.user;
          if (user == null || provider.isLoading) {
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            );
          }
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 20,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ClipOval(
                            child: SafeImage(
                              url: user.userAvatar,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(
                            width: 10,
                          ),
                          Text(
                            user.userName,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(context, UserInfoPage.routeName);
                        },
                        child: const Icon(
                          Icons.settings,
                          color: AppColors.surface,
                          size: 20,
                        ),
                      )
                    ],
                  ),
                ),
                Consumer<OrderProvider>(
                  builder: (context, provider, child) {
                    final orders = provider.orders;

                    int waitingPrepair = orders
                        .where((e) =>
                            e.orderInfo.orderStatus ==
                            OrderStatus.confirmed.name)
                        .length;
                    int waitingAccept = orders
                        .where((e) =>
                            e.orderInfo.orderStatus == OrderStatus.pending.name)
                        .length;
                    int waitingDelivery = orders
                        .where((e) =>
                            e.orderInfo.orderStatus ==
                            OrderStatus.shipping.name)
                        .length;

                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Container(
                              width: size.width,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Đơn mua',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(
                                        context,
                                        OrderStatusPage.routeName,
                                        arguments:
                                            const OrderStatusPage(index: 3),
                                      );
                                    },
                                    child: const Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Xem lịch sử mua hàng',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.black54,
                                          ),
                                        ),
                                        SizedBox(width: 3),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: AppColors.primary,
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: size.width,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: _statusItem(
                                      label: 'Chờ xác nhận',
                                      icon: Icons.alarm_on_outlined,
                                      number: waitingAccept,
                                      index: 0,
                                    ),
                                  ),
                                  Expanded(
                                    child: _statusItem(
                                      label: 'Chờ giao hàng',
                                      icon: Icons.inventory_2,
                                      number: waitingPrepair,
                                      index: 1,
                                    ),
                                  ),
                                  Expanded(
                                    child: _statusItem(
                                      label: 'Đang giao hàng',
                                      icon: Icons.local_shipping,
                                      number: waitingDelivery,
                                      index: 2,
                                    ),
                                  ),
                                  Expanded(
                                    child: _statusItem(
                                      label: 'Đánh giá',
                                      icon: Icons.stars_rounded,
                                      number: 0,
                                      index: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black.withValues(alpha: 0.6),
                      builder: (_) => const LogOutDialog(),
                    );
                    if (mounted) {
                 
                    }
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout, color: Colors.red),
                      SizedBox(
                        width: 10,
                      ),
                      Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statusItem({
    required String label,
    required IconData icon,
    required int number,
    required int index,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.pushNamed(
          context,
          OrderStatusPage.routeName,
          arguments: OrderStatusPage(index: index),
        );
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, size: 28, color: AppColors.primary),
              ),
              if (number > 0)
                Positioned(
                  right: -3,
                  top: -3,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.red,
                    child: Text(
                      number < 9 ? number.toString() : '9+',
                      style: AppTextstyles.extraSmallText.copyWith(
                        color: AppColors.surface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(label, style: AppTextstyles.smallText),
        ],
      ),
    );
  }
}
