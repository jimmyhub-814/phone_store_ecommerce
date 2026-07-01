import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/main/pages/order/fail_to_order.dart';
import 'package:phone_store/main/pages/order/shipping_info.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:phone_store/models/notifications.dart';
import 'package:phone_store/main/pages/order/sucess.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart';
import 'dart:async';

class CheckoutOrder extends StatefulWidget {
  static const routeName = '/checkout-order';

  final double totalPrice;

  final List<OrderProduct> orderProduct;

  const CheckoutOrder(
      {super.key, required this.totalPrice, required this.orderProduct});

  @override
  State<CheckoutOrder> createState() => _CheckoutOrderState();
}

class _CheckoutOrderState extends State<CheckoutOrder> {
  ValueNotifier<String> selected =
      ValueNotifier<String>('Thanh toán khi nhận hàng');

  late List<OrderProduct> orderProduct = [];
  late double totalPrice = 0;
  String responseCode = '';
  String orderNote = '';
  Timer? timer;

  void startTimer() {
    timer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        refresh();
      },
    );
  }

  Future<void> refresh() async {
    final List<OrderProduct> newProducts = [];
    double total = 0;

    for (var item in widget.orderProduct) {
      final prod = await context.read<ProductProvider>().getProduct(item.id);

      if (prod != null) {
        for (var v in prod.listVariants) {
          if (v.id == item.variantsId) {
            newProducts.add(
              OrderProduct(
                id: prod.id,
                variantsId: v.id,
                variantsName: v.phoneType,
                phoneName: prod.title,
                phonePrice: v.phonePrice,
                phoneDiscount: v.phoneDiscount,
                quantity: item.quantity,
                phoneImage: v.image ?? prod.mainImage,
              ),
            );

            final price = v.phonePrice - (v.phonePrice * v.phoneDiscount / 100);

            total += item.quantity * price;
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        orderProduct = newProducts;
        totalPrice = total;
      });
    }
  }

  void stopTimer() {
    timer?.cancel();
  }

  @override
  void initState() {
    super.initState;

    refresh();
    startTimer();
  }

  @override
  void dispose() {
    timer?.cancel();
    selected.dispose();
    super.dispose();
  }

  Future<void> showOrderNoteDialog() async {
    final controller = TextEditingController(text: orderNote);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: const Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color: AppColors.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Lời nhắn cho Shop',
                style: AppTextstyles.headingH7Bold,
              ),
            ],
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 6,
                    maxLength: 100,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Để lại lời nhắn',
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                setState(() {
                  orderNote = controller.text.trim();
                });
                Navigator.pop(context);
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
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
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          final user = provider.user;

          if (provider.isLoading || user == null) {
            return Center(
              child: LoadingAnimationWidget.waveDots(
                color: AppColors.primary,
                size: 60,
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: Container(
                  color: AppColors.surfaceLight,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () async {
                          Navigator.pushNamed(
                            context,
                            ShippingInfoScreen.routeName,
                          );
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
                                child: user.shippingInfo.isNotEmpty
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                user.shippingInfo[0].fullName,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                user.shippingInfo[0].phone,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: AppColors.iconDisabled,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Text(
                                            user.shippingInfo[0].address,
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      )
                                    : GestureDetector(
                                        onTap: () => Navigator.pushNamed(
                                          context,
                                          ShippingInfoScreen.routeName,
                                        ),
                                        child: const Text(
                                          'Vui lòng thêm thông tin nhận hàng!',
                                          style: TextStyle(
                                            color: AppColors.iconSecondary,
                                          ),
                                        ),
                                      ),
                              ),
                              const Icon(Icons.arrow_forward_ios),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: size.width - 30,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orderProduct.isEmpty
                                  ? widget.orderProduct.length
                                  : orderProduct.length,
                              separatorBuilder: (context, index) {
                                return const SizedBox(height: 10);
                              },
                              itemBuilder: (context, i) {
                                final item = orderProduct.isEmpty
                                    ? widget.orderProduct[i]
                                    : orderProduct[i];

                                return SizedBox(
                                  height: 55,
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(10),
                                        child: SafeImage(
                                          url: item.phoneImage,
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
                                              item.phoneName,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              item.variantsName,
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
                                                    item.phonePrice -
                                                        (item.phonePrice *
                                                                item.phoneDiscount) /
                                                            100,
                                                  )}đ',
                                                  style: const TextStyle(
                                                      color: AppColors.accent,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${NumberFormat("#,###", "en_US").format(item.phonePrice)}đ',
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
                                                  'x${item.quantity}',
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
                                );
                              },
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            const Divider(
                              height: 1,
                              color: AppColors.lightBorder,
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5),
                              child: GestureDetector(
                                onTap: showOrderNoteDialog,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Lời nhắn cho Shop'),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    SizedBox(
                                      width: 150,
                                      child: orderNote.isEmpty
                                          ? const Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  'Để lại lời nhắn',
                                                  style: TextStyle(
                                                      color: AppColors
                                                          .iconSecondary),
                                                ),
                                                Icon(
                                                  Icons.chevron_right,
                                                  size: 16,
                                                )
                                              ],
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Text(
                                                  orderNote,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.iconDisabled,
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons.chevron_right,
                                                  size: 16,
                                                )
                                              ],
                                            ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
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
                          '${NumberFormat("#,###", "en_US").format(totalPrice != 0 ? totalPrice : widget.totalPrice)}đ',
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
                        backgroundColor: orderProduct.isNotEmpty
                            ? AppColors.accent
                            : AppColors.iconDisabled,
                        shadowColor: Colors.transparent,
                      ).copyWith(
                        overlayColor:
                            MaterialStateProperty.all(Colors.transparent),
                      ),
                      onPressed: orderProduct.isNotEmpty
                          ? () async {
                              if (user.shippingInfo.isNull ||
                                  user.shippingInfo.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vui lòng thêm địa chỉ đặt hàng.',
                                    ),
                                    duration: Duration(
                                      seconds: 2,
                                    ),
                                  ),
                                );
                                return;
                              }

                              Timestamp now = Timestamp.now();
                              final userInfo = OrderUserInfo(
                                  userId: AuthHelper.userId!,
                                  userName: user.shippingInfo[0].fullName,
                                  userAddress: user.shippingInfo[0].address,
                                  userAvatar: user.userAvatar,
                                  userPhone: user.shippingInfo[0].phone);

                              final orderInfo = OrderInfo(
                                  orderNote: orderNote,
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
                                  orderProduct: orderProduct,
                                  userInfo: userInfo,
                                  orderInfo: orderInfo,
                                  statusHistory: [orderHistory]);

                              final notiList = NotificationList(
                                  id: const Uuid()
                                      .v4()
                                      .replaceAll('-', '')
                                      .substring(0, 12),
                                  body:
                                      'Đơn hàng #$orderId đã được đặt thành công',
                                  title: 'Đặt thành công đơn hàng',
                                  timestamp: now);

                              try {
                                if (selected.value ==
                                    'Thanh toán khi nhận hàng') {
                                  bool processDone = false;
                                  if (orderProduct.isNotEmpty) {
                                    processDone = await context
                                        .read<OrderProvider>()
                                        .uploadOrderToFirebase(order);
                                  }

                                  if (processDone) {
                                    await Collections.notifications(
                                            AuthHelper.userId!)
                                        .doc(order.id)
                                        .set({
                                      NotificationModel.notificationListField:
                                          FieldValue.arrayUnion(
                                              [notiList.toMap()]),
                                      NotificationModel.idField: order.id,
                                      NotificationModel.readField: false,
                                    }, SetOptions(merge: true));

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đặt hàng thành công!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );

                                    Navigator.pushReplacementNamed(
                                        context, SuccessOrder.routeName);
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
                                            SuccessOrder.routeName,
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
                              }
                            }
                          : null,
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
