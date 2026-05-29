import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/cancelOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/detailOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/feedBack.dart';
import 'package:phone_store/main/pages/home/mainPage/cartPage.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/feedBack.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/main/pages/home/mainPage/buyItem.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:provider/provider.dart';

class OrderStatusPage extends StatefulWidget {
  final int index;
  const OrderStatusPage({super.key, required this.index});
  static const routeName = '/order_status';
  @override
  State<OrderStatusPage> createState() => _OrderStatusPageState();
}

class _OrderStatusPageState extends State<OrderStatusPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final int _initialTabIndex = 0;
  final user = AuthHelper.userId;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => loadData());
    _tabController =
        TabController(length: 6, vsync: this, initialIndex: _initialTabIndex);

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        final tabIndex = widget.index;
        if (tabIndex >= 0 && tabIndex < 5) {
          setState(() {
            _tabController.index = tabIndex;
          });
        }
      },
    );
  }

  Future<void> loadData() async {
    context.read<OrderProvider>().loadOrders();
  }

  bool addToCart(String productId, String variant) {
    print("productId truyền vào: $productId");

    final cartProvider = context.read<CartProvider>();
    final productProvider = context.read<ProductProvider>().products;
    final cartItem = cartProvider.cart.firstWhereOrNull(
      (item) => item.id == productId && item.variantsId == variant,
    );
    for (var p in productProvider) {
      print("productProvider id: ${p.id}");
    }
    final currentQuantityInCart = cartItem?.quantity ?? 0;
    final totalQuantity = currentQuantityInCart + 1;
    // Lấy sản phẩm
    final product = productProvider.firstWhereOrNull(
      (p) => p.id == productId,
    );

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sản phẩm không tồn tại')),
      );
      return false;
    }

    final variantData = product.listVariants.firstWhereOrNull(
      (v) => v.id == variant,
    );

    if (variantData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không tìm thấy phiên bản',
          ),
        ),
      );
      return false;
    }

    final stock = variantData.phoneQuantity;

    if (totalQuantity > stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sản phẩm đã hết hàng!',
          ),
        ),
      );
      return false;
    }
    cartProvider.addCart(productId, 1, variant);
    return true;
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(date);

    if (difference.inMinutes < 1) return "Vừa xong";
    if (difference.inMinutes < 60) return "${difference.inMinutes} phút trước";
    if (difference.inHours < 24) return "${difference.inHours} giờ trước";
    if (difference.inDays < 7) return "${difference.inDays} ngày trước";

    return "${date.day}/${date.month}/${date.year}";
  }

  Future<Map<String, FeedBack?>> getAllFeedBack(
      Map<String, Map<String, String>> itemMap) async {
    final futures = itemMap.entries.map((entry) async {
      final key = entry.key;
      final productId = entry.value['productId']!;
      final feedbackId = entry.value['feedbackId']!;

      try {
        final doc =
            await Collections.feedBacks(productId).doc(feedbackId).get();

        return MapEntry(
          key,
          doc.exists ? FeedBack.fromMap(doc.data()!) : null,
        );
      } catch (e) {
        return MapEntry(key, null);
      }
    });

    return Map.fromEntries(await Future.wait(futures));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: AppbarIcon(),
          title: const Text(
            'Đơn hàng đã mua',
            style: TextStyle(
              color: AppColors.textSecondary,
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(50),
            child: TabBar(
              indicatorColor: AppColors.primary,
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.iconPrimary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle:
                  const TextStyle(fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: "Chờ xác nhận"),
                Tab(text: "Chờ giao hàng"),
                Tab(text: "Đang giao"),
                Tab(text: "Đã giao"),
                Tab(text: "Đánh giá"),
                Tab(text: "Đã hủy"),
              ],
            ),
          ),
        ),
        body: Consumer<OrderProvider>(
          builder: (context, orderProvider, _) {
            if (orderProvider.isLoading) {
              return Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary,
                  size: 60,
                ),
              );
            }
            final data = orderProvider.orders;
            if (data.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long, size: 60, color: Colors.grey),
                    SizedBox(height: 12),
                    Text(
                      'Bạn chưa có đơn hàng nào',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }

            final waitingAccept = data
                .where((order) =>
                    order.orderInfo.orderStatus == OrderStatus.pending.name)
                .toList();
            final waitingPrepare = data
                .where((order) =>
                    order.orderInfo.orderStatus == OrderStatus.confirmed.name)
                .toList();
            final waitingDelivery = data
                .where((order) =>
                    order.orderInfo.orderStatus == OrderStatus.shipping.name)
                .toList();
            final completeOrder = data
                .where((order) =>
                    order.orderInfo.orderStatus == OrderStatus.delivered.name ||
                    order.orderInfo.orderStatus == OrderStatus.reviewed.name)
                .toList();
            final feedback = data
                .where((order) =>
                    order.orderInfo.orderStatus == OrderStatus.reviewed.name)
                .toList();
            final cancel = data
                .where((order) =>
                    order.orderInfo.orderStatus == OrderStatus.cancelled.name ||
                    order.orderInfo.orderStatus ==
                        OrderStatus.cancelledByAdmin.name)
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 4,
                  onRefresh: loadData,
                  child: waitingWidget(context, waitingAccept),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 4,
                  onRefresh: loadData,
                  child: waitingWidget(context, waitingPrepare),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 4,
                  onRefresh: loadData,
                  child: waitingWidget(context, waitingDelivery),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 4,
                  onRefresh: loadData,
                  child: waitingWidget(context, completeOrder),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 4,
                  onRefresh: loadData,
                  child: feedbackWidget(context, feedback),
                ),
                RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  strokeWidth: 4,
                  onRefresh: loadData,
                  child: waitingWidget(context, cancel),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, OrderProduct order) {
    final discountedPrice =
        order.phonePrice - ((order.phonePrice * order.phoneDiscount) / 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SafeImage(
              url: order.phoneImage,
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.phoneName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.variantsName,
                      style: AppTextstyles.headingH7.copyWith(
                        color: AppColors.border,
                      ),
                    ),
                    Text(
                      'x${order.quantity}',
                      style: AppTextstyles.headingH7
                          .copyWith(color: AppColors.border, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${NumberFormat("#,###", "en_US").format(discountedPrice)}đ',
                      style: const TextStyle(
                          color: AppColors.danger,
                          fontWeight: FontWeight.w600,
                          fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget waitingWidget(
    BuildContext context,
    List<UserOrder> orders,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.iconSecondary,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có đơn hàng nào cả',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: AppColors.surface,
      child: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, orderIndex) {
          final order = orders[orderIndex];
          final ValueNotifier<bool> isExpanded = ValueNotifier(false);

          return GestureDetector(
            onTap: () {
              Navigator.pushNamed(
                context,
                DetailOrder.routeName,
                arguments: DetailOrder(orderId: order.id),
              );
            },
            child: Container(
              margin: orderIndex == orders.length - 1
                  ? const EdgeInsets.all(10)
                  : const EdgeInsets.only(top: 10, left: 10, right: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12.withValues(alpha: 0.08),
                    blurRadius: 3,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: ValueListenableBuilder<bool>(
                  valueListenable: isExpanded,
                  builder: (context, expanded, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedCrossFade(
                          firstChild: Column(
                            children: [
                              _buildProductItem(context, order.orderProduct[0]),
                            ],
                          ),
                          secondChild: Column(
                            children: order.orderProduct.map((item) {
                              return _buildProductItem(context, item);
                            }).toList(),
                          ),
                          crossFadeState: expanded
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                          duration: const Duration(milliseconds: 300),
                        ),
                        if (order.orderProduct.length > 1)
                          Center(
                            child: SizedBox(
                              height: 30,
                              child: TextButton.icon(
                                onPressed: () => isExpanded.value = !expanded,
                                icon: Icon(
                                  expanded
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  color: Colors.grey,
                                ),
                                label: Text(
                                  expanded ? "Ẩn bớt" : "Xem thêm",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Divider(
                          height: 15,
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                        order.orderInfo.orderStatus ==
                                OrderStatus.cancelledByAdmin.name
                            ? const Padding(
                                padding: EdgeInsets.only(bottom: 10),
                                child: Text(
                                  'Đơn hàng của bạn đã bị hủy. Liên hệ để được tư vấn!',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.accent,
                                  ),
                                ),
                              )
                            : const SizedBox.shrink(),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            "Tổng tiền: ${NumberFormat("#,###", "en_US").format(order.orderInfo.totalPrice)} đ",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        if (order.orderInfo.orderStatus ==
                                OrderStatus.pending.name ||
                            order.orderInfo.orderStatus ==
                                OrderStatus.confirmed.name)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _actionButton(
                                text: "Liên hệ shop",
                                color: AppColors.dangerLight,
                                textColor: AppColors.danger,
                                onPressed: () async {
                                  await FlutterPhoneDirectCaller.callNumber(
                                      "0852711187");
                                },
                              ),
                              const SizedBox(width: 10),
                              _actionButton(
                                text: "Hủy đơn",
                                color: AppColors.surfaceLight,
                                textColor: Colors.black87,
                                onPressed: () async {
                                  context
                                      .read<OrderProvider>()
                                      .updateOrder(order.id, 'Đã hủy');

                                  Navigator.pushNamed(
                                      context, CancelOrderPage.routeName);
                                },
                              ),
                            ],
                          )
                        else if (order.orderInfo.orderStatus ==
                            OrderStatus.shipping.name)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _actionButton(
                                text: "Liên hệ shop",
                                color: AppColors.dangerLight,
                                textColor: AppColors.danger,
                                onPressed: () async {
                                  await FlutterPhoneDirectCaller.callNumber(
                                      "0852711187");
                                },
                              ),
                            ],
                          )
                        else if (order.orderInfo.orderStatus ==
                                OrderStatus.delivered.name ||
                            order.orderInfo.orderStatus ==
                                OrderStatus.reviewed.name)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _actionButton(
                                text: "Liên hệ shop",
                                color: AppColors.dangerLight,
                                textColor: AppColors.danger,
                                onPressed: () async {
                                  await FlutterPhoneDirectCaller.callNumber(
                                      "0852711187");
                                },
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              order.orderInfo.orderStatus ==
                                      OrderStatus.reviewed.name
                                  ? _actionButton(
                                      text: "Mua lại",
                                      color: AppColors.accent,
                                      textColor: AppColors.dangerLight,
                                      onPressed: () async {
                                        bool status = false;
                                        for (var i in order.orderProduct) {
                                          status = addToCart(
                                            i.id,
                                            i.variantsId,
                                          );
                                        }

                                        if (status) {
                                          Navigator.pushNamed(
                                              context, CartPage.routeName);
                                        }
                                      },
                                    )
                                  : _actionButton(
                                      text: "Đánh giá",
                                      color: AppColors.accent,
                                      textColor: AppColors.dangerLight,
                                      onPressed: () async {
                                        Navigator.pushNamed(
                                          context,
                                          FeedBackPage.routeName,
                                          arguments:
                                              FeedBackPage(orderId: order.id),
                                        );
                                      },
                                    ),
                              const SizedBox(height: 10),
                            ],
                          )
                        else if (order.orderInfo.orderStatus ==
                                OrderStatus.cancelled.name ||
                            order.orderInfo.orderStatus ==
                                OrderStatus.cancelledByAdmin.name)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _actionButton(
                                text: "Mua lại",
                                color: AppColors.accent,
                                textColor: AppColors.dangerLight,
                                onPressed: () async {
                                  bool status = false;
                                  for (var i in order.orderProduct) {
                                    status = addToCart(
                                      i.id,
                                      i.variantsId,
                                    );
                                  }

                                  if (status) {
                                    Navigator.pushNamed(
                                        context, CartPage.routeName);
                                  }
                                },
                              ),
                            ],
                          )
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget feedbackWidget(
    BuildContext context,
    List<UserOrder> orders,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.iconSecondary,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có đơn hàng nào cả',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    final allItems = <Map<String, dynamic>>[];

    for (var order in orders) {
      for (var item in order.orderProduct) {
        final feedbackId = "${order.id}_${item.variantsId}";

        allItems.add({
          "item": item,
          "feedbackId": feedbackId,
          "productId": item.id,
          "orderId": order.id,
        });
      }
    }

    Map<String, Map<String, String>> itemMap = {};

    for (var item in allItems) {
      itemMap[item['feedbackId']] = {
        "productId": item['productId'],
        "feedbackId": item['feedbackId'],
      };
    }

    //
    return FutureBuilder<Map<String, FeedBack?>>(
      future: getAllFeedBack(itemMap),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primary,
              size: 60,
            ),
          );
        }

        if (snapshot.hasError) {
          print('Lỗi tải');
          return const Center(
            child: Text(
              'Chưa có bất kì đánh giá nào!',
            ),
          );
        }

        final feedbackMap = snapshot.data ?? {};

        return ListView.builder(
          itemCount: allItems.length,
          itemBuilder: (context, index) {
            final item = allItems[index];
            final orderProduct = allItems[index]['item'];
            final feedbackId = item['feedbackId'];
            final fb = feedbackMap[feedbackId];
            if (fb == null) return const SizedBox.shrink();

            return GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  DetailOrder.routeName,
                  arguments: DetailOrder(orderId: allItems[index]['orderId']),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.08),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: NetworkImage(fb.userAvatar),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fb.userName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Row(
                                children: List.generate(
                                  5,
                                  (index) => Icon(
                                    Icons.star_rounded,
                                    size: 12,
                                    color: index < fb.vote
                                        ? AppColors.star
                                        : Colors.grey.shade300,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    /// 📝 FEEDBACK TEXT

                    Text(
                      'Phân loại: ${fb.variantName}',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        color: AppColors.iconDisabled,
                      ),
                    ),

                    const SizedBox(height: 5),

                    /// 📝 FEEDBACK TEXT
                    if (fb.feedBackText.isNotEmpty)
                      Text(
                        fb.feedBackText,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: Colors.grey.shade800,
                        ),
                      ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: SafeImage(
                            url: orderProduct.phoneImage,
                            width: 30,
                            height: 30,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                orderProduct.phoneName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                orderProduct.variantsName,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppColors.iconDisabled,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _formatTime(fb.time),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),

                    if (fb.adminReply?.isNotEmpty ?? false)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.store,
                              color: Colors.blue,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                fb.adminReply!,
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  height: 1.4,
                                ),
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
        );
      },
    );
  }

  Widget cancelWidget(
    BuildContext context,
    List<UserOrder> orders,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_shopping_cart_rounded,
              color: AppColors.iconSecondary,
              size: 80,
            ),
            SizedBox(height: 16),
            Text(
              'Bạn chưa có đơn hàng nào cả',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isExpanded = ValueNotifier(false);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withValues(alpha: 0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ValueListenableBuilder(
            valueListenable: isExpanded,
            builder: (context, expanded, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedCrossFade(
                    firstChild:
                        _buildProductItem(context, order.orderProduct[0]),
                    secondChild: Column(
                      children: order.orderProduct
                          .map((item) => _buildProductItem(context, item))
                          .toList(),
                    ),
                    crossFadeState: expanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                  ),
                  if (order.orderProduct.length > 1)
                    Center(
                      child: SizedBox(
                        height: 30,
                        child: TextButton(
                          onPressed: () => isExpanded.value = !expanded,
                          child: Text(
                            expanded ? "Ẩn bớt ▲" : "Xem thêm ▼",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                  Divider(
                    height: 15,
                    color: Colors.grey.withValues(alpha: 0.2),
                  ),
                  order.orderInfo.orderStatus ==
                          OrderStatus.cancelledByAdmin.name
                      ? const Text(
                          'Đơn hàng của bạn đã bị hủy. Liên hệ để được tư vấn!',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.accent),
                        )
                      : const SizedBox.shrink(),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      "Tổng tiền: ${NumberFormat("#,###", "en_US").format(order.orderInfo.totalPrice)} đ",
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          final selectedProducts = order.orderProduct.map((e) {
                            return OrderProduct(
                              id: e.id,
                              variantsId: e.variantsId,
                              variantsName: e.variantsId,
                              phonePrice: e.phonePrice,
                              quantity: e.quantity,
                              phoneImage: e.phoneImage,
                              phoneName: e.phoneName,
                              phoneDiscount: e.phoneDiscount,
                            );
                          }).toList();

                          Navigator.pushNamed(
                            context,
                            BuyItem.routeName,
                            arguments: BuyItem(
                              orderProduct: selectedProducts,
                              totalPrice: order.orderInfo.totalPrice,
                            ),
                          );
                        },
                        child: const Text("Mua lại"),
                      ),
                    ],
                  )
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
