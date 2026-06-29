import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/cubit/messages_cubit.dart';
import 'package:phone_store/main/pages/order/checkout_order.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/message_model.dart';
import 'package:phone_store/models/order.dart';
import 'package:phone_store/models/products.dart';
import 'package:phone_store/main/pages/mainPage/phone_profile.dart';
import 'package:phone_store/models/variants.dart';
import 'package:phone_store/provider/cart_provider.dart';
import 'package:phone_store/provider/product_provider.dart';
import 'package:phone_store/main/pages/shared_widgets/safe_image.dart';
import 'package:phone_store/app_constants/app_utils.dart';

class MessagePage extends StatefulWidget {
  final Product? product;
  final ProductMessage? productMessage;

  static const routeName = '/messagePage';
  const MessagePage({super.key, this.product, this.productMessage});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final chatController = TextEditingController();
  final userId = AuthHelper.userId;
  final ScrollController _scrollController = ScrollController();
  bool _productInitialized = false;
  StreamSubscription<Message>? _messageSub;
  final ValueNotifier<int> selectedVariantIndexB = ValueNotifier<int>(0);
  final ValueNotifier<int> counter = ValueNotifier<int>(1);
  bool _showScrollToBottom = false;

  @override
  void initState() {
    super.initState();
    _messageSub?.cancel();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });

    _scrollController.addListener(_onScroll);
    _scrollController.addListener(_onLoadMore);
  }

  Future<void> _initialize() async {
    final messageCubit = context.read<MessageCubit>();

    await messageCubit.init();

    await messageCubit.initMessages();

    final after = messageCubit.state.messages.isNotEmpty
        ? messageCubit.state.messages.last.time
        : 0;

    _messageSub = messageCubit.streamMessage(after).listen(
          (msg) => messageCubit.onFirebaseMessage(msg),
        );
  }

  void _onLoadMore() async {
    if (!mounted || !_scrollController.hasClients) return;

    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50 &&
        !context.read<MessageCubit>().state.isLoadingMore) {
      await context.read<MessageCubit>().loadMore();
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void addToCart(String productId, int quantity, Variants variants) {
    final cartProvider = context.read<CartProvider>();
    final productProvider = context.read<ProductProvider>();
    final product =
        productProvider.products.firstWhereOrNull((p) => p.id == productId);
    if (product == null) {
      _showSnack('Sản phẩm không tồn tại');
      return;
    }
    final cartItem = cartProvider.cart.firstWhereOrNull((item) =>
        item.productId == productId && item.variantsId == variants.id);
    if ((cartItem?.quantity ?? 0) + quantity > variants.phoneQuantity) {
      _showSnack('Số lượng không đủ');
      return;
    }
    cartProvider.addCart(productId, quantity, variants.id);
    _showSnack('Đã thêm vào giỏ hàng');
  }

  void _onScroll() {
    final show = _scrollController.offset > 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  void _showVariantSheet({
    required BuildContext context,
    required Product product,
    required String mode,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return ValueListenableBuilder(
          valueListenable: selectedVariantIndexB,
          builder: (ctx, bIndex, _) {
            final v = product.listVariants[bIndex];
            final vPrice =
                v.phonePrice - (v.phonePrice * v.phoneDiscount / 100);

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SafeImage(
                              url: v.image,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${NumberFormat("#,###", "en_US").format(vPrice)}đ',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.danger,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kho: ${v.phoneQuantity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: const Color(0xFFF0F0F0),
                      ),
                      const SizedBox(height: 16),
                      if (product.listVariants.length > 1) ...[
                        const Text(
                          'Phân loại',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(
                            product.listVariants.length,
                            (i) {
                              final isSelected = bIndex == i;
                              return GestureDetector(
                                onTap: () => selectedVariantIndexB.value = i,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                            .withValues(alpha: 0.08)
                                        : Colors.white,
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFFE5E7EB),
                                      width: isSelected ? 1.5 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    product.listVariants[i].phoneType,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(height: 1, color: const Color(0xFFF0F0F0)),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Số lượng',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          ValueListenableBuilder<int>(
                            valueListenable: counter,
                            builder: (_, count, __) {
                              return Row(
                                children: [
                                  _qtyBtn(
                                    icon: Icons.remove_rounded,
                                    onTap: () {
                                      if (counter.value > 1) counter.value--;
                                    },
                                  ),
                                  SizedBox(
                                    width: 40,
                                    child: Text(
                                      '$count',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  _qtyBtn(
                                    icon: Icons.add_rounded,
                                    onTap: () {
                                      if (counter.value < v.phoneQuantity) {
                                        counter.value++;
                                      } else {
                                        _showSnack('Số lượng đã đạt tối đa');
                                      }
                                    },
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            if (mode == 'cart') {
                              addToCart(product.id, counter.value, v);
                              Navigator.pop(ctx);
                            } else {
                              final selectedVariant =
                                  product.listVariants[bIndex];
                              Navigator.pushNamed(
                                context,
                                CheckoutOrder.routeName,
                                arguments: CheckoutOrder(
                                  orderProduct: [
                                    OrderProduct(
                                      id: product.id,
                                      variantsId: selectedVariant.id,
                                      variantsName: selectedVariant.phoneType,
                                      phoneName: product.title,
                                      phonePrice: selectedVariant.phonePrice,
                                      phoneDiscount:
                                          selectedVariant.phoneDiscount,
                                      quantity: counter.value,
                                      phoneImage: selectedVariant.image ??
                                          product.mainImage,
                                    )
                                  ],
                                  totalPrice: vPrice * counter.value,
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: mode == 'cart'
                                ? Colors.white
                                : AppColors.primary,
                            foregroundColor: mode == 'cart'
                                ? AppColors.primary
                                : Colors.white,
                            side: mode == 'cart'
                                ? const BorderSide(color: AppColors.primary)
                                : null,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            mode == 'cart' ? 'Thêm vào giỏ' : 'Mua ngay',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.removeListener(_onLoadMore);
    _messageSub?.cancel();
    chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_productInitialized) return;
    if (widget.product != null) {
      context.read<MessageCubit>().setProduct(widget.productMessage);
    }

    _productInitialized = true;
  }

  Widget buildStatus(StatusMessage status, Message? msg) {
    switch (status) {
      case StatusMessage.sending:
        return SizedBox(
          height: 10,
          width: 10,
          child: Center(
            child: LoadingAnimationWidget.waveDots(
              color: AppColors.primary,
              size: 10,
            ),
          ),
        );

      case StatusMessage.sent:
        return const Icon(Icons.check, size: 14);
      case StatusMessage.failed:
        return const Icon(Icons.error, size: 14, color: Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<MessageCubit>();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A2E),
        leadingWidth: 56,
        leading: AppbarIcon(color: AppColors.surfaceSecondary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DM Store',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Nhân viên tư vấn sẽ trả lời sau ít phút',
              style: AppTextstyles.headingH7.copyWith(color: AppColors.surface),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.phone_rounded,
              color: AppColors.surfaceSecondary,
              size: 20,
            ),
            onPressed: () {
              AppUtils.openLink('tel:0852711187');
            },
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F18)],
          ),
        ),
        child: BlocBuilder<MessageCubit, MessageState>(
          builder: (context, state) {
            return state.messages.isNotEmpty
                ? Stack(
                    children: [
                      ListView.builder(
                        reverse: true,
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(bottom: 10, top: 30),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final dt =
                              DateTime.fromMillisecondsSinceEpoch(msg.time);
                          final dateText = DateFormat('dd/MM').format(dt);

                          bool showDate = false;

                          if (index == state.messages.length - 1) {
                            showDate = true;
                          } else {
                            final nextMsg = state.messages[index + 1];
                            final nextDt = DateTime.fromMillisecondsSinceEpoch(
                                nextMsg.time);

                            final nextDateText =
                                DateFormat('dd/MM').format(nextDt);

                            if (dateText != nextDateText) {
                              showDate = true;
                            }
                          }

                          return Column(
                            children: [
                              if (showDate)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  child: Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.07),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.08,
                                          ),
                                        ),
                                      ),
                                      child: Text(
                                        dateText,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              _chatWidget(context, msg),
                            ],
                          );
                        },
                      ),
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        bottom: _showScrollToBottom ? 12 : -60,
                        right: 16,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 200),
                          opacity: _showScrollToBottom ? 1.0 : 0.0,
                          child: GestureDetector(
                            onTap: _scrollToBottom,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A2E),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Color(0xFF6C63FF),
                                size: 26,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const Center(
                    child: Text('Chưa có tin nhắn'),
                  );
          },
        ),
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF888899), size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F0F18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.07),
                      ),
                    ),
                    child: TextField(
                      controller: chatController,
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        hintStyle: TextStyle(color: Color(0xFF444455)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 11),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: chatController,
                  builder: (context, value, _) {
                    final isEmpty = value.text.trim().isEmpty;
                    final chatText = chatController.text;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: isEmpty
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFF6C63FF), Color(0xFF8B5CF6)],
                              ),
                        color: isEmpty ? const Color(0xFF2A2A3E) : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: isEmpty
                            ? []
                            : [
                                BoxShadow(
                                  color: const Color(0xFF6C63FF)
                                      .withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.send_rounded,
                          color:
                              isEmpty ? const Color(0xFF444455) : Colors.white,
                          size: 20,
                        ),
                        onPressed: isEmpty
                            ? null
                            : () async {
                                chatController.clear();
                                await cubit.sendProcess(chatText, context);
                              },
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chatWidget(BuildContext context, Message msg) {
    final isMe = msg.senderId == userId;
    final dt = DateTime.fromMillisecondsSinceEpoch(msg.time);
    final timeText =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: EdgeInsets.only(
        top: 2,
        bottom: 2,
        left: isMe ? 64 : 12,
        right: isMe ? 12 : 64,
      ),
      child: Align(
        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            msg.product != null
                ? GestureDetector(
                    onTap: () => Navigator.pushNamed(
                      context,
                      PhoneProfilePage.routeName,
                      arguments: PhoneProfilePage(id: msg.product!.productId),
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      width: 220,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF6C63FF).withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: SafeImage(
                                    url: msg.product?.productImage,
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        msg.product!.productName.length > 18
                                            ? '${msg.product!.productName.substring(0, 18)}...'
                                            : msg.product!.productName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${NumberFormat("#,##0", "en_US").format(msg.product?.productPrice)}đ',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFFFF6B6B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFF6C63FF),
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
 
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
 
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            child: IntrinsicHeight(
                              child: Row(
                                children: [ 
                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _showVariantSheet(
                                        context: context,
                                        product: widget.product!,
                                        mode: 'cart',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        color: Colors.white
                                            .withValues(alpha: 0.04),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_shopping_cart_outlined,
                                              size: 15,
                                              color: Color(0xFF9CA3AF),
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              'Thêm giỏ',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  Container(
                                    width: 1,
                                    color: Colors.white.withValues(alpha: 0.06),
                                  ),

                                  Expanded(
                                    child: InkWell(
                                      onTap: () => _showVariantSheet(
                                        context: context,
                                        product: widget.product!,
                                        mode: 'buy',
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 10),
                                        decoration: const BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Color(0xFF6C63FF),
                                              Color(0xFF8B5CF6)
                                            ],
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.bolt_rounded,
                                              size: 15,
                                              color: Colors.white,
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              'Mua ngay',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF6C63FF) : const Color(0xFFF0F0F5),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 5),
                  bottomRight: Radius.circular(isMe ? 5 : 20),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      msg.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : const Color(0xFF1A1A2E),
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeText,
                        style: TextStyle(
                          fontSize: 10,
                          color: isMe
                              ? Colors.white.withValues(alpha: 0.65)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 3),
                        buildStatus(msg.statusMessage, msg),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            msg.statusMessage == StatusMessage.failed
                ? GestureDetector(
                    onTap: () =>
                        context.read<MessageCubit>().retry(msg, context),
                    child: Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(
                          10,
                        ),
                        border: Border.all(
                          color: Colors.red.withValues(
                            alpha: 0.25,
                          ),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: Colors.red,
                            size: 13,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Gửi lại',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }

  Widget _qtyBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: const Color(0xFF4B5563)),
      ),
    );
  }
}
