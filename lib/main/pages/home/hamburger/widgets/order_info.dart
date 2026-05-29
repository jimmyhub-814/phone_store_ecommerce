import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/order_status.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:provider/provider.dart';

class OrderInfoPage extends StatefulWidget {
  const OrderInfoPage({super.key});
  static const routeName = '/order_info';
  @override
  State<OrderInfoPage> createState() => _OrderInfoPageState();
}

class _OrderInfoPageState extends State<OrderInfoPage> {
  @override
  void initState() {
    super.initState();
    // Fetch sau khi frame đầu render xong
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrderProvider>().loadOrders(); // gọi hàm load data
    });
  }
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
        centerTitle: true,
        title: const Text(
          'Đơn đã mua',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, provider, child) {
          final orders = provider.orders;

          int waitingPrepair = orders
              .where(
                  (e) => e.orderInfo.orderStatus == OrderStatus.confirmed.name)
              .length;
          int waitingAccept = orders
              .where((e) => e.orderInfo.orderStatus == OrderStatus.pending.name)
              .length;
          int waitingDelivery = orders
              .where(
                  (e) => e.orderInfo.orderStatus == OrderStatus.shipping.name)
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                              arguments: const OrderStatusPage(index: 3),
                            );
                          },
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
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

                  // --- LIST STATUS ---
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
    );
  }

  // --- WIDGET ITEM ---
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
