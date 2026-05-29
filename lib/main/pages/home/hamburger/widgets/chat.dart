import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/app_textStyles.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/cubit/message_state.dart';
import 'package:phone_store/cubit/messages_cubic.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/message_model.dart';
import 'package:phone_store/models/user.dart';
import 'package:phone_store/main/pages/home/mainPage/phone_profile.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:phone_store/main/pages/home/shared_widgets/safeImage.dart';

class MessagePage extends StatefulWidget {
  final ProductMessage? product;
  static const routeName = '/messagePage';
  const MessagePage({super.key, this.product});

  @override
  State<MessagePage> createState() => _MessagePageState();
}

class _MessagePageState extends State<MessagePage> {
  final chatController = TextEditingController();
  final userId = AuthHelper.userId;
  final ScrollController _scrollController = ScrollController();
  bool _productInitialized = false;
  late Future<UserApp?> user;
  StreamSubscription<Message>? _messageSub;

  @override
  void initState() {
    super.initState();
    context.read<MessageCubit>().localBox = Hive.box('local_messages');
    context.read<MessageCubit>().initMessages().then(
      (_) {
        final after = context.read<MessageCubit>().state.messages.isNotEmpty
            ? context.read<MessageCubit>().state.messages.last.time
            : 0;

        _messageSub = context.read<MessageCubit>().streamMessage(after).listen(
          (msg) {
            context.read<MessageCubit>().onFirebaseMessage(msg);
          },
        );
      },
    );
    _scrollController.addListener(() async {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 50 &&
          !context.read<MessageCubit>().state.isLoadingMore) {
        await context.read<MessageCubit>().loadMore();
      }
    });
    user = context.read<UserProvider>().getUserInfo();
  }

  @override
  void dispose() {
    _messageSub?.cancel();
    chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_productInitialized) return;

    context.read<MessageCubit>().setProduct(widget.product);
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
        elevation: 0.5,
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        leadingWidth: 56,
        leading: AppbarIcon(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DM Store',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Nhân viên tư vấn sẽ trả lời sau ít phút',
              style: AppTextstyles.headingH7.copyWith(color: AppColors.surface),
            ),
          ],
        ),
      ),
      body: BlocBuilder<MessageCubit, MessageState>(builder: (context, state) {
        return state.messages.isNotEmpty
            ? ListView.builder(
                reverse: true,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 10, top: 30),
                itemCount: state.messages.length,
                itemBuilder: (context, index) {
                  final msg = state.messages[index];
                  final dt = DateTime.fromMillisecondsSinceEpoch(msg.time);
                  final dateText = DateFormat('dd/MM').format(dt);

                  bool showDate = false;

                  if (index == state.messages.length - 1) {
                    // Tin nhắn cũ nhất → luôn hiển thị ngày
                    showDate = true;
                  } else {
                    final nextMsg = state.messages[index + 1];
                    final nextDt =
                        DateTime.fromMillisecondsSinceEpoch(nextMsg.time);

                    final nextDateText = DateFormat('dd/MM').format(nextDt);

                    if (dateText != nextDateText) {
                      showDate = true;
                    }
                  }

                  return Column(
                    children: [
                      if (showDate)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            dateText,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      _chatWidget(context, msg),
                    ],
                  );
                })
            : const Center(
                child: Text('Chưa có tin nhắn'),
              );
      }),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: chatController,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: chatController,
                  builder: (context, value, _) {
                    final isEmpty = value.text.trim().isEmpty;
                    final chatText = value.text;

                    return CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          isEmpty ? Colors.grey.shade300 : AppColors.primary,
                      child: IconButton(
                        icon: const Icon(
                          Icons.send,
                          color: AppColors.surface,
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

    return Align(
      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.88,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            msg.product != null
                ? GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, PhoneProfilePage.routeName,
                        arguments:
                            PhoneProfilePage(id: msg.product!.productId)),
                    child: Container(
                      margin: EdgeInsets.only(
                        top: 3,
                        bottom: 3,
                        left: isMe ? 50 : 8,
                        right: isMe ? 8 : 50,
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadiusGeometry.circular(6),
                                child: SafeImage(
                                  url: msg.product?.productImage,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(msg.product!.productName.length > 15
                                      ? '${msg.product!.productName.substring(0, 15)}...'
                                      : msg.product!.productName),
                                  Text(
                                    '${NumberFormat("#,##0.###", "en_US").format(msg.product?.productPrice)}đ',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          Container(
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            clipBehavior: Clip.hardEdge,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                InkWell(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    alignment: Alignment.center,
                                    color: AppColors.surface,
                                    child: const Icon(
                                      Icons.add_shopping_cart_outlined,
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: InkWell(
                                    onTap: () {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        builder: (_) {
                                          return SizedBox(
                                            height: 120,
                                            child: Padding(
                                              padding: const EdgeInsets.all(16),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: OutlinedButton(
                                                      onPressed: () {},
                                                      child: const Text(
                                                        'Thêm giỏ',
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: ElevatedButton(
                                                      onPressed: () {},
                                                      child: const Text(
                                                        'Mua ngay',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                    child: Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      color: AppColors.textSecondary,
                                      child: Text(
                                        'Mua hàng',
                                        style: AppTextstyles.headingH7.copyWith(
                                          color: AppColors.surface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
            Container(
              margin: EdgeInsets.only(
                top: 3,
                bottom: 3,
                left: isMe ? 50 : 8,
                right: isMe ? 8 : 50,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isMe ? 12 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.message,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        timeText,
                        style: AppTextstyles.smallText.copyWith(
                          color: AppColors.border,
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      buildStatus(msg.statusMessage, msg)
                    ],
                  )
                ],
              ),
            ),
            msg.statusMessage == StatusMessage.failed
                ? GestureDetector(
                    onTap: () =>
                        context.read<MessageCubit>().retry(msg, context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Gửi lại',
                          style: AppTextstyles.smallTextBold.copyWith(
                            color: AppColors.accent,
                          ),
                        ),
                        const Icon(
                          Icons.restore,
                          color: Colors.red,
                          size: 12,
                        ),
                        const SizedBox(
                          width: 8,
                        )
                      ],
                    ),
                  )
                : const SizedBox.shrink()
          ],
        ),
      ),
    );
  }
}
