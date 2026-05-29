import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/main/pages/home/mainPage/phone_profile.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';
import 'package:flutter/services.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:provider/provider.dart';

class DetailOrder extends StatefulWidget {
  final String orderId;
  const DetailOrder({super.key, required this.orderId});
  static const routeName = '/orderDetail';
  @override
  State<DetailOrder> createState() => _DetailOrderState();
}

class _DetailOrderState extends State<DetailOrder> {
  @override
  Widget build(BuildContext context) {
    final ValueNotifier<bool> isExpanded = ValueNotifier(false);
    String formatDateTime(Timestamp timestamp) {
      final date = timestamp.toDate();
      return DateFormat('dd-MM-yyyy HH:mm').format(date);
    }

    String secondFormatDateTime(DateTime date) {
      final day = DateFormat('dd').format(date);
      final month = DateFormat('MM').format(date);

      return '$day TH$month';
    }

    return Scaffold(
      backgroundColor: AppColors.lightBorder,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: AppbarIcon(),
        title: const Text(
          'Thông tin đơn hàng',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<UserOrder?>(
          future: context.read<OrderProvider>().getUserOrder(widget.orderId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: LoadingAnimationWidget.waveDots(
                  color: AppColors.primary,
                  size: 60,
                ),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.iconDisabled,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lỗi tải đơn hàng. Hãy thử lại!',
                      style: AppTextstyles.headingH6.copyWith(
                        color: AppColors.iconDisabled,
                      ),
                    ),
                  ],
                ),
              );
            }
            final order = snapshot.data!;

            final deliveredHistory = order.statusHistory
                .where((e) => e.status == OrderStatus.delivered.name)
                .toList();

            final cancelHistory = order.statusHistory
                .where((e) => e.status == OrderStatus.cancelledByAdmin.name)
                .toList();

            final cancelItem =
                cancelHistory.isNotEmpty ? cancelHistory.first : null;

            final deliveredItem =
                deliveredHistory.isNotEmpty ? deliveredHistory.first : null;
            return Container(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        color: AppColors.textSecondary,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (order.orderInfo.orderStatus ==
                                    OrderStatus.pending.name ||
                                order.orderInfo.orderStatus ==
                                    OrderStatus.confirmed.name ||
                                order.orderInfo.orderStatus ==
                                    OrderStatus.shipping.name)
                              Text(
                                'Thời gian đảm bảo nhận hàng ${secondFormatDateTime(
                                  order.orderInfo.orderDate.toDate().add(
                                        const Duration(days: 2),
                                      ),
                                )} - ${secondFormatDateTime(
                                  order.orderInfo.orderDate.toDate().add(
                                        const Duration(days: 3),
                                      ),
                                )}',
                                style:
                                    const TextStyle(color: AppColors.surface),
                              )
                            else if (order.orderInfo.orderStatus ==
                                    OrderStatus.delivered.name ||
                                order.orderInfo.orderStatus ==
                                    OrderStatus.reviewed.name)
                              Text(
                                'Đã hoàn thành đơn hàng ${secondFormatDateTime(
                                  deliveredItem!.time.toDate(),
                                )}',
                                style: const TextStyle(
                                  color: AppColors.surface,
                                ),
                              )
                            else if (order.orderInfo.orderStatus ==
                                OrderStatus.cancelled.name)
                              const Text(
                                'Đã hủy đơn hàng',
                                style: TextStyle(
                                  color: AppColors.surface,
                                ),
                              )
                            else if (order.orderInfo.orderStatus ==
                                OrderStatus.cancelledByAdmin.name)
                              cancelItem?.time == null
                                  ? const SizedBox.shrink()
                                  : Text(
                                      'Đã hủy vào ${secondFormatDateTime(
                                        cancelItem!.time.toDate(),
                                      )}',
                                      style: const TextStyle(
                                        color: AppColors.surface,
                                      ),
                                    ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Thông tin vận chuyển',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppColors.border,
                                      size: 17,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Đơn vị vận chuyển GHTK',
                                      style: TextStyle(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                // if (order.orderInfo.orderStatus ==
                                //         OrderStatus.pending.name ||
                                //     order.orderInfo.orderStatus ==
                                //         OrderStatus.confirmed.name ||
                                //     order.orderInfo.orderStatus ==
                                //         OrderStatus.shipping.name ||
                                //     order.orderInfo.orderStatus ==
                                //         OrderStatus.delivered.name)
                                //   ValueListenableBuilder<bool>(
                                //       valueListenable: isExpanded,
                                //       builder: (context, expanded, child) {
                                //         return const Column(
                                //           children: [
                                //             Row(
                                //               children: [
                                //                 Icon(Icons.local_shipping),
                                //                 Column(children: [])
                                //               ],
                                //             ),
                                //           ],
                                //         );
                                //       })
                              ],
                            ),
                            const Divider(
                              color: AppColors.surfaceLight,
                              thickness: 1,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Địa chỉ nhận hàng',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.person,
                                                color: AppColors.border,
                                                size: 17,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                order.userInfo.userName,
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(
                                            width: 30,
                                          ),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.phone,
                                                color: AppColors.border,
                                                size: 17,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                order.userInfo.userPhone,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.location_on,
                                            size: 17,
                                            color: AppColors.border,
                                          ),
                                          const SizedBox(width: 5),
                                          Expanded(
                                            child: ValueListenableBuilder<bool>(
                                              valueListenable: isExpanded,
                                              builder: (context, value, _) {
                                                final address =
                                                    order.userInfo.userAddress;
                                                final bool isLong =
                                                    address.length > 40;
                                                final String displayText = value ||
                                                        !isLong
                                                    ? address
                                                    : '${address.substring(0, 39)}...';

                                                return GestureDetector(
                                                  onTap: isLong
                                                      ? () => isExpanded.value =
                                                          !isExpanded.value
                                                      : null,
                                                  child: Text(
                                                    displayText,
                                                    softWrap: true,
                                                    style: const TextStyle(
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: order.orderProduct.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  PhoneProfilePage.routeName,
                                  arguments: PhoneProfilePage(
                                      id: order.orderProduct[index].id),
                                );
                              },
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(7),
                                          child: SafeImage(
                                            url: order
                                                .orderProduct[index].phoneImage,
                                            width: 70,
                                            height: 70,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: SizedBox(
                                            height: 65,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      order.orderProduct[index]
                                                          .phoneName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                        height: 1.0,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                      height: 3,
                                                    ),
                                                    Text(
                                                      order.orderProduct[index]
                                                          .variantsName,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      style: AppTextstyles
                                                          .smallText
                                                          .copyWith(
                                                        color: AppColors.border,
                                                      ),
                                                    ),
                                                    Container(
                                                      alignment:
                                                          Alignment.topRight,
                                                      child: Text(
                                                        'x${order.orderProduct[index].quantity}',
                                                        style: const TextStyle(
                                                          fontSize: 11,
                                                          height: 1.0,
                                                          color:
                                                              AppColors.border,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    Text(
                                                      '${NumberFormat("#,###", "en_US").format(order.orderProduct[index].phonePrice)}đ',
                                                      style: const TextStyle(
                                                        fontSize: 11,
                                                        color: AppColors.border,
                                                        decoration:
                                                            TextDecoration
                                                                .lineThrough,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      '${NumberFormat("#,###", "en_US").format(
                                                        order
                                                                .orderProduct[
                                                                    index]
                                                                .phonePrice -
                                                            ((order
                                                                        .orderProduct[
                                                                            index]
                                                                        .phonePrice *
                                                                    order
                                                                        .orderProduct[
                                                                            index]
                                                                        .phoneDiscount) /
                                                                100),
                                                      )}đ',
                                                      style: const TextStyle(
                                                        color: AppColors.accent,
                                                        letterSpacing: 0.38,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  const Divider(
                                    color: AppColors.surfaceLight,
                                    thickness: 1,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      const Text(
                                        'Thành tiền: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        '${NumberFormat("#,###", "en_US").format(order.orderInfo.totalPrice)}đ',
                                        style: const TextStyle(
                                          letterSpacing: 0.38,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bạn cần hỗ trợ?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(
                                    Icons.message,
                                    color: AppColors.border,
                                    size: 17,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Liên hệ Shop',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    color: AppColors.border,
                                    size: 17,
                                  ),
                                  SizedBox(width: 5),
                                  Text(
                                    'Trung tâm hỗ trợ',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  SizedBox(
                                    width: double.infinity,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Mã đơn hàng',
                                          style: AppTextstyles.headingH7Bold
                                              .copyWith(
                                            color: AppColors.iconDisabled,
                                          ),
                                        ),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              order.id,
                                              style: AppTextstyles.headingH7
                                                  .copyWith(
                                                color: AppColors.iconSecondary,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 5,
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                Clipboard.setData(
                                                  ClipboardData(text: order.id),
                                                );

                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: const Text(
                                                      "Đã copy mã đơn hàng",
                                                    ),
                                                    behavior: SnackBarBehavior
                                                        .floating,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                    ),
                                                    margin:
                                                        const EdgeInsets.all(
                                                            16),
                                                    duration: const Duration(
                                                      seconds: 2,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                    Icons.copy,
                                                    size: 12,
                                                    color: AppColors.primary,
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    "Copy",
                                                    style: AppTextstyles
                                                        .headingH7Bold
                                                        .copyWith(
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Phương thức thanh toán',
                                        style: AppTextstyles.headingH7,
                                      ),
                                      Text(
                                        order.orderInfo.methodPayment,
                                        style: AppTextstyles.headingH7.copyWith(
                                          color: AppColors.iconDisabled,
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                              const Divider(
                                color: AppColors.surfaceLight,
                                thickness: 1,
                              ),
                              Column(
                                children: [
                                  ...order.statusHistory.map(
                                    (e) {
                                      if (e.status ==
                                          OrderStatus.pending.name) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Thời gian đặt hàng',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              formatDateTime(e.time),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        );
                                      } else if (e.status ==
                                          OrderStatus.shipping.name) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Thời gian đơn vị vận chuyển lấy hàng',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              formatDateTime(e.time),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        );
                                      } else if (e.status ==
                                              OrderStatus.delivered.name ||
                                          e.status ==
                                              OrderStatus.reviewed.name) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Thời gian hoàn thành đơn',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              formatDateTime(e.time),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        );
                                      } else if (e.status ==
                                          OrderStatus.cancelled.name) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Đã được hủy đơn bởi bạn',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              formatDateTime(e.time),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        );
                                      } else if (e.status ==
                                          OrderStatus.cancelledByAdmin.name) {
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Đã bị hủy bởi DL Store',
                                              style: TextStyle(fontSize: 11),
                                            ),
                                            const SizedBox(
                                              width: 10,
                                            ),
                                            Text(
                                              formatDateTime(e.time),
                                              style:
                                                  const TextStyle(fontSize: 11),
                                            ),
                                          ],
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
    );
  }
}
