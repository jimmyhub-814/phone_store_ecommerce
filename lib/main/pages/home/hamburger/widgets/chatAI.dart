import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/main/pages/home/shared_widgets/appBarIcon.dart';
import 'package:phone_store/models/messageAI.dart';
import 'package:phone_store/provider/messageAI_provider.dart';
import 'package:provider/provider.dart';

class ChatAI extends StatefulWidget {
  static const routeName = '/chatAI';
  const ChatAI({super.key});

  @override
  State<ChatAI> createState() => _ChatAIState();
}

class _ChatAIState extends State<ChatAI> {
  final userId = AuthHelper.userId;
  final chatController = TextEditingController();
  List<MessageAI> messageList = [];

  void scrollToBottom(ScrollController scrollController) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    messageList.clear();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<MessageAIProvider>();

      if (provider.messageList.isEmpty) {
        provider.messageList.add(
          MessageAI(
            id: "init",
            message:
                "Chào mừng bạn đến với DM Store!👋\nBạn đang quan tâm đến sản phẩm nào của shop ạ?",
            isUser: false,
            time: DateTime.now().millisecondsSinceEpoch,
          ),
        );
        provider.notifyListeners();
      }
    });
    scrollToBottom(context.read<MessageAIProvider>().scrollController);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MessageAIProvider>();
    final ScrollController scrollController =
        context.read<MessageAIProvider>().scrollController;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.surfaceLight,
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: AppColors.surface,
        surfaceTintColor: AppColors.surface,
        leadingWidth: 56,
        leading: AppbarIcon(),
        title: const Text(
          'DM Store AI',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: Consumer<MessageAIProvider>(
        builder: (_, provider, child) {
          messageList = provider.messageList;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            scrollToBottom(scrollController);
          });

          return ListView.builder(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 10, top: 30),
            itemCount: messageList.length,
            itemBuilder: (context, index) {
              final msg = messageList[index];

              return _chatWidget(context, msg,
                  onDone: !msg.isUser ? () {} : null);
            },
          );
        },
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
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: TextField(
                      controller: chatController,
                      enabled: !provider.isTyping,
                      maxLines: 1,
                      decoration: const InputDecoration(
                        hintText: 'Nhập tin nhắn...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ValueListenableBuilder(
                  valueListenable: chatController,
                  builder: (_, value, child) {
                    String chatText = chatController.text;
                    final isEmpty = value.text.trim().isEmpty;
                    return provider.isTyping
                        ? CircleAvatar(
                            radius: 22,
                            backgroundColor: Colors.red,
                            child: IconButton(
                              onPressed: () {
                                context
                                    .read<MessageAIProvider>()
                                    .stopResponse();
                              },
                              icon: const Icon(
                                Icons.stop,
                                color: AppColors.surface,
                                size: 20,
                              ),
                            ),
                          )
                        : CircleAvatar(
                            radius: 22,
                            backgroundColor: isEmpty
                                ? Colors.grey.shade300
                                : AppColors.primary,
                            child: IconButton(
                              icon: const Icon(
                                Icons.send,
                                color: AppColors.surface,
                                size: 20,
                              ),
                              onPressed: (isEmpty || provider.isTyping)
                                  ? null
                                  : () async {
                                      FocusScope.of(context).unfocus();
                                      chatController.clear();
                                      await provider.sendMessage(
                                          message: chatText);
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

  Widget _chatWidget(BuildContext context, MessageAI msg,
      {VoidCallback? onDone}) {
    final isMe = msg.isUser == true;

    return Align(
      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(
                top: 3,
                bottom: 3,
                left: isMe ? 50 : 8,
                right: isMe ? 8 : 50,
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: isMe ? AppColors.surface : AppColors.primaryDark,
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
                  if (msg.isLoading)
                    LoadingAnimationWidget.waveDots(
                      color: AppColors.surface,
                      size: 15,
                    )
                  else if (msg.isStreaming)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            msg.message,
                            style: const TextStyle(
                              fontSize: 15,
                              color: AppColors.surface,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      msg.message,
                      style: TextStyle(
                        fontSize: 15,
                        color:
                            isMe ? AppColors.textSecondary : AppColors.surface,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
