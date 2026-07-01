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
  static const routeName = "/feedback";

  final String orderId;

  const FeedbackScreen({super.key, required this.orderId});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final Map<String, TextEditingController> _feedbackControllers = {};
  final Map<String, int> _votes = {};
  final Map<String, List<ValueNotifier<bool>>> _starStates = {};

  UserOrder? _order;
  bool _isLoading = true;
  bool _hasError = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    try {
      final order =
          await context.read<OrderProvider>().getUserOrder(widget.orderId);
      if (!mounted) return;

      for (var item in order!.orderProduct) {
        _feedbackControllers[item.variantsId] = TextEditingController();
        _votes[item.variantsId] = 5;
        _starStates[item.variantsId] =
            List.generate(5, (_) => ValueNotifier<bool>(true));
      }

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    for (var c in _feedbackControllers.values) {
      c.dispose();
    }
    for (var list in _starStates.values) {
      for (var n in list) {
        n.dispose();
      }
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_order == null || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      for (final entry in _votes.entries) {
        final productId = entry.key;
        final rating = entry.value;
        final feedbackText = _feedbackControllers[productId]?.text.trim() ?? '';

        final orderProduct = _order!.orderProduct.firstWhere(
          (p) => p.variantsId == productId,
          orElse: () =>
              throw StateError('Không tìm thấy sản phẩm $productId trong đơn'),
        );

        final id = '${_order!.id}_${orderProduct.variantsId}';

        final feedback = FeedBack(
          id: id,
          userId: _order!.userInfo.userId,
          userName: _order!.userInfo.userName,
          userAvatar: _order!.userInfo.userAvatar,
          variantName: orderProduct.variantsName,
          vote: rating,
          variantImage: orderProduct.phoneImage,
          feedBackText: feedbackText,
          time: Timestamp.now(),
        );

        // ignore: use_build_context_synchronously
        await context
            .read<ProductProvider>()
            .uploadFeedBackOrder(orderProduct.id, feedback, id);
      }

      if (!mounted) return;
      await context
          .read<OrderProvider>()
          .updateOrder(_order!.id, OrderStatus.reviewed.name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phản hồi đã được gửi!")),
      );

      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Gửi đánh giá thất bại. Vui lòng thử lại!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBorder,
      appBar: AppBar(
        leading: AppbarIcon(),
        backgroundColor: AppColors.lightBorder,
        elevation: 0,
        title: const Text(
          'Đánh giá sản phẩm',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: LoadingAnimationWidget.waveDots(
          color: AppColors.primary,
          size: 60,
        ),
      );
    }

    if (_hasError || _order == null) {
      return const Center(
        child: Text('Chưa có bất kì đánh giá nào!'),
      );
    }

    final order = _order!;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(top: 4, bottom: 16),
            child: Column(
              children: order.orderProduct
                  .map((item) => _buildFeedbackCard(item))
                  .toList(),
            ),
          ),
        ),
        _buildSubmitBar(),
      ],
    );
  }

  Widget _buildFeedbackCard(dynamic item) {
    final stars = _starStates[item.variantsId]!;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SafeImage(
                  url: item.phoneImage,
                  width: 58,
                  height: 58,
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
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            "Đánh giá sản phẩm",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return ValueListenableBuilder<bool>(
                valueListenable: stars[index],
                builder: (context, filled, child) {
                  return GestureDetector(
                    onTap: () {
                      for (int i = 0; i < stars.length; i++) {
                        stars[i].value = i <= index;
                      }
                      _votes[item.variantsId] = index + 1;
                    },
                    child: AnimatedScale(
                      scale: filled ? 1.15 : 1.0,
                      duration: const Duration(milliseconds: 150),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 2),
                        child: Icon(
                          Icons.star_rounded,
                          color: filled ? AppColors.star : Colors.grey.shade300,
                          size: 32,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ),
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: AppColors.lightBorder.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _feedbackControllers[item.variantsId],
              maxLength: 100,
              maxLines: 4,
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Chia sẻ cảm nhận của bạn…",
                hintStyle: TextStyle(color: Colors.black38),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.zero,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ).copyWith(
            elevation: WidgetStateProperty.all(0),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: Ink(
            decoration: BoxDecoration(
              gradient: _isSubmitting
                  ? null
                  : const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                    ),
              color: _isSubmitting ? Colors.grey.shade300 : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: _isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      "Gửi đánh giá",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
