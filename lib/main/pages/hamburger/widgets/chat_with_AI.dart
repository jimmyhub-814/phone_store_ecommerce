import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:phone_store/app_constants/app_colors.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/cubit/gemini_ai_cubit.dart';
import 'package:phone_store/main/pages/shared_widgets/appbar_icon.dart';
import 'package:phone_store/models/AI.dart';

class ChatAI extends StatefulWidget {
  static const routeName = '/gemini-AI';
  
  const ChatAI({super.key});

  @override
  State<ChatAI> createState() => _ChatAIState();
}

class _ChatAIState extends State<ChatAI> {
  final userId = AuthHelper.userId;
  final chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToBottom = false;
  late AIModelCubit _cubit;

  void scrollToBottom() {
    if (!mounted) return;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _onScroll() {
    if (!mounted) return;
    final show = _scrollController.offset > 200;
    if (show != _showScrollToBottom) {
      setState(() => _showScrollToBottom = show);
    }
  }

  @override
  void initState() {
    super.initState();
    _cubit = context.read<AIModelCubit>();
    _cubit.onShouldScrollToBottom = scrollToBottom;
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_cubit.state.messageList.isEmpty) {
        _cubit.emit(
          _cubit.state.copyWith(
            messageList: [
              AIModel(
                id: "init",
                message:
                    "Chào mừng bạn đến với DM Store!👋\nBạn đang quan tâm đến sản phẩm nào của shop ạ?",
                isUser: false,
                time: DateTime.now().millisecondsSinceEpoch,
              ),
            ],
          ),
        );
      }
      scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    chatController.dispose();
    _cubit.onShouldScrollToBottom = null;
    _cubit.clearMessages();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AIModelCubit, GeminiAIState>(
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.surfaceLight,
          appBar: AppBar(
            elevation: 0,
            backgroundColor: const Color(0xFF1A1A2E),
            leadingWidth: 56,
            leading: AppbarIcon(color: AppColors.surfaceSecondary),
            centerTitle: true,
            title: const Text(
              'DM Store AI',
              style: TextStyle(
                color: AppColors.surface,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1A1A2E), Color(0xFF0F0F18)],
              ),
            ),
            child: Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 10, top: 30),
                  itemCount: state.messageList.length,
                  itemBuilder: (context, index) {
                    final msg = state.messageList[index];
                    return _chatWidget(context, msg);
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
                      onTap: scrollToBottom,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.surface.withValues(alpha: 0.12),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dark.withValues(alpha: 0.3),
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
                    top: BorderSide(
                      color: AppColors.surface.withValues(alpha: 0.06),
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.dark.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
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
                          style: const TextStyle(
                              color: Colors.white, fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Nhập tin nhắn...',
                            hintStyle: TextStyle(
                              color: Color(0xFF444455),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 11),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ValueListenableBuilder(
                      valueListenable: chatController,
                      builder: (_, value, child) {
                        final chatText = chatController.text;
                        final isEmpty = value.text.trim().isEmpty;

                        return state.isTyping
                            ? AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: IconButton(
                                  onPressed: () => _cubit.stopResponse(),
                                  icon: const Icon(
                                    Icons.stop,
                                    color: AppColors.surface,
                                    size: 20,
                                  ),
                                ),
                              )
                            : AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: isEmpty
                                      ? null
                                      : const LinearGradient(
                                          colors: [
                                            Color(0xFF6C63FF),
                                            Color(0xFF8B5CF6),
                                          ],
                                        ),
                                  color:
                                      isEmpty ? const Color(0xFF2A2A3E) : null,
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
                                  icon: Icon(
                                    Icons.send_rounded,
                                    color: isEmpty
                                        ? const Color(0xFF444455)
                                        : Colors.white,
                                    size: 20,
                                  ),
                                  onPressed: (isEmpty || state.isTyping)
                                      ? null
                                      : () async {
                                          FocusScope.of(context).unfocus();
                                          chatController.clear();
                                          await _cubit.sendMessage(
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
      },
    );
  }

  Widget _chatWidget(BuildContext context, AIModel msg) {
    final isMe = msg.isUser == true;

    return Align(
      alignment: isMe ? Alignment.topRight : Alignment.topLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        child: Container(
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
          child: msg.isLoading
              ? LoadingAnimationWidget.waveDots(
                  color: AppColors.surface,
                  size: 15,
                )
              : Text(
                  msg.message,
                  style: TextStyle(
                    fontSize: 15,
                    color: isMe ? AppColors.textSecondary : AppColors.surface,
                  ),
                ),
        ),
      ),
    );
  }
}
