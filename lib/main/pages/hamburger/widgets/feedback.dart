import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/feedback.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/provider/order_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:provider/provider.dart';

class FeedbackScreen extends StatefulWidget {
  final String orderId;
  const FeedbackScreen({super.key, required this.orderId});
  static const routeName = "/feedbackScreen";
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  Map<String, TextEditingController> feedbackControllers = {};
  Map<String, int> votes = {};

  @override
  void dispose() {
    for (var controller in feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBorder,
      appBar: AppBar(
        leading: AppbarIcon(),
        backgroundColor: AppColors.lightBorder,
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
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

            if (snapshot.hasError) {
              print('Lỗi tải');
              return const Center(
                child: Text(
                  'Chưa có bất kì đánh giá nào!',
                ),
              );
            }

            final order = snapshot.data!;

            for (var item in order.orderProduct) {
              feedbackControllers[item.variantsId] = TextEditingController();
              votes[item.variantsId] = 5;
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  ...order.orderProduct.map(
                    (item) {
                      final List<ValueNotifier<bool>> isTrue =
                          List.generate(5, (_) => ValueNotifier<bool>(true));

                      return Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SafeImage(
                                    url: item.phoneImage,
                                    width: 55,
                                    height: 55,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.phoneName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Đánh giá sản phẩm",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                ...List.generate(
                                  5,
                                  (index) => ValueListenableBuilder(
                                    valueListenable: isTrue[index],
                                    builder: (context, value, child) {
                                      return GestureDetector(
                                        onTap: () {
                                          for (int i = 0;
                                              i < isTrue.length;
                                              i++) {
                                            isTrue[i].value = i <= index;
                                          }
                                          votes[item.variantsId] = index + 1;
                                        },
                                        child: AnimatedScale(
                                          scale: value ? 1.15 : 1.0,
                                          duration:
                                              const Duration(milliseconds: 150),
                                          child: Icon(
                                            Icons.star_rounded,
                                            color: value
                                                ? AppColors.star
                                                : Colors.grey.shade400,
                                            size: 32,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1),
                              ),
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: TextField(
                                controller:
                                    feedbackControllers[item.variantsId],
                                maxLength: 100,
                                maxLines: 4,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Chia sẻ cảm nhận của bạn…",
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                    ),
                    onPressed: () {
                      votes.forEach((productId, rating) {
                        final feedbackText =
                            feedbackControllers[productId]?.text ?? '';

                        final orderProduct = order.orderProduct.firstWhere(
                          (p) => p.variantsId == productId,
                        );
                        String id = '${order.id}_${orderProduct.variantsId}';
                        final feedB = FeedBack(
                            id: id,
                            userId: order.userInfo.userId,
                            userName: order.userInfo.userName,
                            userAvatar: order.userInfo.userAvatar,
                            variantName: orderProduct.variantsName,
                            vote: rating,
                            variantImage: orderProduct.phoneImage,
                            feedBackText: feedbackText.trim(),
                            time: Timestamp.now());
                        context
                            .read<ProductProvider>()
                            .uploadFeedBackOrder(orderProduct.id, feedB, id);
                      });
                      context
                          .read<OrderProvider>()
                          .updateOrder(order.id, OrderStatus.reviewed.name);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Phản hồi đã được gửi!"),
                        ),
                      );

                      Future.delayed(const Duration(seconds: 2000));
                      Navigator.pop(context);
                    },
                    child: const Text(
                      "Gửi",
                      style: TextStyle(
                        color: AppColors.surface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
