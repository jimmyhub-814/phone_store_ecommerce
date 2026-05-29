import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/main/pages/home/hamburger/failToOrder.dart';
import 'package:phone_store/main/pages/home/hamburger/widgets/changeInfoOrder.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/notifications.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/models/variants.dart';
import 'package:phone_store/main/pages/home/hamburger/sucess.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/provider/notification_provider.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:uuid/uuid.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart';

class BuyItem extends StatefulWidget {
  final double totalPrice;
  final List<OrderProduct> orderProduct;
  static const routeName = '/buyItem';
  const BuyItem(
      {super.key, required this.totalPrice, required this.orderProduct});

  @override
  State<BuyItem> createState() => _BuyItemState();
}

class _BuyItemState extends State<BuyItem> {
  final user = AuthHelper.currentUser;
  ValueNotifier<String> selected =
      ValueNotifier<String>('Thanh toán khi nhận hàng');

  bool isLoading = false;
  int quantity = 1;
  String? userAddress = '';
  String? userPhone;
  String? userName;
  String responseCode = '';
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<ProductProvider>().fetchProductsList();
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    final List<Product> listProduct = [];
    final List<Variants> listVariants = [];
    List<int> quantities = [];

    return Scaffold(
      appBar: AppBar(
        leading: AppbarIcon(
          color: AppColors.surface,
        ),
        title: const Text(
          'Thanh toán',
          style: TextStyle(color: AppColors.surface),
        ),
        centerTitle: true,
        backgroundColor: AppColors.accent,
      ),
      body: FutureBuilder<UserApp?>(
        future: context.read<UserProvider>().getUserInfo(),
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
            return Center(
              child: Text("Lỗi tải thông tin user: ${snapshot.error}"),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text("Chưa có thông tin user"),
            );
          }

          final user = snapshot.data!;

          userName ??= user.userName;
          userPhone ??= user.userPhone;
          return Column(
            children: [
              Expanded(
                child: Container(
                  color: AppColors.surfaceLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      // Thông tin địa chỉ user
                      GestureDetector(
                        onTap: () async {
                          final data = await Navigator.pushNamed(
                            context,
                            ChangeOrderInfo.routeName,
                            arguments: ChangeOrderInfo(
                                userName: userName!,
                                userPhone: userPhone!,
                                userAddress: userAddress!),
                          );
                          if (data != null) {
                            final result = data as Map<String, dynamic>;
                            setState(() {
                              userAddress =
                                  result['userAddress'] ?? userAddress;
                              userPhone = result['userPhone'] ?? userPhone;
                              userName = result['userName'] ?? userName;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: AppColors.accent,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(userName!),
                                        const SizedBox(width: 5),
                                        Text(
                                          userPhone!,
                                          maxLines: 1,
                                          style: const TextStyle(
                                            color: AppColors.iconDisabled,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      (userAddress == null ||
                                              userAddress!.isEmpty)
                                          ? 'Vui lòng thêm địa chỉ nhận hàng!'
                                          : userAddress!,
                                      style:
                                          const TextStyle(color: Colors.grey),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Consumer<ProductProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.orderProduct.length,
                              itemBuilder: (context, index) =>
                                  Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  height: 70,
                                  margin: const EdgeInsets.only(bottom: 10),
                                ),
                              ),
                            );
                          } else if (provider.products.isEmpty) {
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: widget.orderProduct.length,
                              itemBuilder: (context, index) =>
                                  Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  height: 70,
                                  margin: const EdgeInsets.only(bottom: 10),
                                ),
                              ),
                            );
                          } else if (snapshot.hasData) {
                            final products = provider.products;
                            for (var product in products) {
                              for (var i = 0;
                                  i < widget.orderProduct.length;
                                  i++) {
                                if (product.id == widget.orderProduct[i].id) {
                                  listProduct.add(product);
                                  final variant = product.listVariants
                                      .firstWhere((e) =>
                                          e.id ==
                                          widget.orderProduct[i].variantsId);
                                  listVariants.add(variant);
                                  quantities
                                      .add(widget.orderProduct[i].quantity);
                                }
                              }
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: listProduct.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Container(
                                  width: size.width - 30,
                                  height: 70,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SafeImage(
                                          url:
                                              widget.orderProduct[i].phoneImage,
                                          width: size.width / 8,
                                          height: size.width / 8,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              listProduct[i].title,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              widget
                                                  .orderProduct[i].variantsName,
                                              style: AppTextstyles.smallText
                                                  .copyWith(
                                                color: AppColors.border,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Row(
                                              children: [
                                                Text(
                                                  '${NumberFormat("#,###", "en_US").format(
                                                    (listVariants[i]
                                                            .phonePrice -
                                                        (listVariants[i]
                                                                    .phonePrice *
                                                                listVariants[i]
                                                                    .phoneDiscount) /
                                                            100),
                                                  )}đ',
                                                  style: const TextStyle(
                                                      color: AppColors.accent,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${NumberFormat("#,###", "en_US").format(listVariants[i].phonePrice)}đ',
                                                  style: AppTextstyles
                                                      .extraSmallText
                                                      .copyWith(
                                                    color: AppColors.border,
                                                    fontWeight: FontWeight.bold,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Text(
                                                  'x${quantities[i]}',
                                                  style: AppTextstyles.smallText
                                                      .copyWith(
                                                    color: AppColors.border,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return const Center(
                              child: Text(
                                'Không có sản phẩm',
                              ),
                            );
                          }
                        },
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Phương thức thanh toán',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ValueListenableBuilder<String>(
                              valueListenable: selected,
                              builder: (context, value, child) {
                                final options = [
                                  'Thanh toán khi nhận hàng',
                                  'Thanh toán bằng thẻ ngân hàng'
                                ];
                                return Column(
                                  children: List.generate(
                                    options.length * 2 - 1,
                                    (index) {
                                      if (index.isOdd) {
                                        return const Divider(height: 1);
                                      }
                                      final option = options[index ~/ 2];

                                      return RadioListTile<String>(
                                        title: Text(
                                          option,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                          ),
                                        ),
                                        value: option,
                                        groupValue: value,
                                        onChanged: (newValue) =>
                                            selected.value = newValue!,
                                        activeColor: Colors.blue,
                                        controlAffinity:
                                            ListTileControlAffinity.trailing,
                                        visualDensity: VisualDensity.compact,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                height: 70,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Text('Tổng cộng', style: AppTextstyles.headingH7),
                        const SizedBox(width: 5),
                        Text(
                          '${NumberFormat("#,###", "en_US").format(widget.totalPrice)}đ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: AppColors.accent,
                        shadowColor: Colors.transparent,
                      ).copyWith(
                        overlayColor:
                            MaterialStateProperty.all(Colors.transparent),
                      ),
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (userAddress.isNull || userAddress == '') {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng cập nhật địa chỉ đặt hàng.',
                                    ),
                                    duration: Duration(
                                      seconds: 2,
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() => isLoading = true);

                              Timestamp now = Timestamp.now();
                              final userInfo = OrderUserInfo(
                                  userId: user.id,
                                  userName: userName ?? '',
                                  userAddress: userAddress ?? '',
                                  userAvatar: user.userAvatar,
                                  userPhone: userPhone ?? '');

                              final orderInfo = OrderInfo(
                                  lastStatusTime: now,
                                  orderStatus: OrderStatus.pending.name,
                                  orderDate: now,
                                  methodPayment: selected.value,
                                  totalPrice: widget.totalPrice);

                              final orderHistory = StatusHistory(
                                  status: OrderStatus.pending.name,
                                  updateBy: UpdateBy.system.name,
                                  time: now);
                              final orderId = const Uuid()
                                  .v4()
                                  .replaceAll('-', '')
                                  .substring(0, 12);
                                  
                              final order = UserOrder(
                                  id: orderId,
                                  orderProduct: widget.orderProduct,
                                  userInfo: userInfo,
                                  orderInfo: orderInfo,
                                  statusHistory: [orderHistory]);
                              final notiList = NotificationList(
                                  id: orderId,
                                  body:
                                      'Đơn hàng $orderId đã được đặt thành công',
                                  title: 'Đặt thành công đơn hàng',
                                  timestamp: now);

                              final noti = NotificationModel(
                                  id: const Uuid()
                                      .v4()
                                      .replaceAll('-', '')
                                      .substring(0, 12),
                                  notificationList: [notiList],
                                  read: false);

                              try {
                                if (selected.value ==
                                    'Thanh toán khi nhận hàng') {
                                  bool processDone = await context
                                      .read<OrderProvider>()
                                      .uploadOrderToFirebase(order);
                                      
                                  await context
                                      .read<NotificationProvider>()
                                      .uploadNotification(noti);
                                  if (processDone) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đặt hàng thành công!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    Navigator.pushReplacementNamed(
                                        context, CompleteOrder.routeName);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text('Đặt hàng thất bại!'),
                                          backgroundColor: Colors.deepOrange),
                                    );

                                    Navigator.pushReplacementNamed(
                                        context, FailOrder.routeName);
                                  }
                                } else if (selected.value ==
                                    'Thanh toán bằng thẻ ngân hàng') {
                                  final paymentUrl =
                                      VNPAYFlutter.instance.generatePaymentUrl(
                                    url:
                                        'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
                                    version: '2.0.1',
                                    tmnCode: 'SYTH2L9D',
                                    txnRef: DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                    orderInfo: 'Thanh toan don hang',
                                    amount: widget.totalPrice,
                                    returnUrl:
                                        "http://192.168.139.1/api/v1/orders/vnpay-return",
                                    ipAdress: '192.168.1.1',
                                    vnpayHashKey:
                                        'AW1U28RSYCMY58SAKGHA6ZHF1QQ6D19E',
                                    vnPayHashType: VNPayHashType.HMACSHA512,
                                    vnpayExpireDate: DateTime.now().add(
                                      const Duration(hours: 1),
                                    ),
                                  );

                                  await VNPAYFlutter.instance.show(
                                    context: context,
                                    paymentUrl: paymentUrl,
                                    onPaymentSuccess: (params) async {
                                      String vnpResponseCode =
                                          params['vnp_ResponseCode'];

                                      if (vnpResponseCode == '00') {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (_) => Center(
                                            child:
                                                LoadingAnimationWidget.waveDots(
                                              color: AppColors.primary,
                                              size: 60,
                                            ),
                                          ),
                                        );

                                        try {
                                          await context
                                              .read<OrderProvider>()
                                              .uploadOrderToFirebase(order);

                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          }

                                          Navigator.pushReplacementNamed(
                                            context,
                                            CompleteOrder.routeName,
                                          );
                                        } catch (e) {
                                          if (Navigator.canPop(context)) {
                                            Navigator.pop(context);
                                          }

                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Có lỗi xảy ra, vui lòng thử lại',
                                              ),
                                            ),
                                          );
                                        }
                                      } else {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Thanh toán không thành công: $vnpResponseCode",
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                    onPaymentError: (params) {
                                      print("Lỗi hệ thống: $params");
                                    },
                                  );
                                }
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Đặt hàng thất bại: $e',
                                    ),
                                  ),
                                );
                              } finally {
                                if (mounted) setState(() => isLoading = false);
                              }
                            },
                      child: const Text(
                        'Đặt hàng',
                        style: TextStyle(
                          color: AppColors.surface,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
