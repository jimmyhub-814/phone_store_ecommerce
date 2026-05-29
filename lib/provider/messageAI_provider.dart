import 'dart:async';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/api_helper.dart';
import 'package:phone_store/models/messageAI.dart';
import 'package:uuid/uuid.dart';

class MessageAIProvider extends ChangeNotifier {
  List<MessageAI> messageList = [];
  StreamSubscription? _sub;
  final ScrollController scrollController = ScrollController();
  bool isTyping = false;
  bool isStopped = false;

  // fake stream
  Stream<String> fakeStreamFromText(String text) async* {
    for (int i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 20));
      yield text[i];
    }
  }

 void stopResponse() {isStopped=true;
    // dừng stream nếu có
    _sub?.cancel();

    isTyping = false;

    if (messageList.isNotEmpty) {
      final lastMsg = messageList.last;

      // xử lý cả loading + streaming
      lastMsg.isLoading = false;
      lastMsg.isStreaming = false;
    }

    notifyListeners();
  }

  Future<void> sendMessage({required String message}) async {
    if (isTyping) return;

    isTyping = true;
    notifyListeners();

    try {
      messageList.add(
        MessageAI(
          id: const Uuid().v4(),
          message: message,
          time: DateTime.now().millisecondsSinceEpoch,
          isUser: true,
        ),
      );

      MessageAI aiMsg = MessageAI(
        id: const Uuid().v4(),
        message: "",
        isUser: false,
        time: DateTime.now().millisecondsSinceEpoch,
        isLoading: true,
      );

      messageList.add(aiMsg);
      notifyListeners();

      final aiText = await ApiHelper().sendMsgApi(msg: message);
      if(isStopped) return;
      aiMsg.isLoading = false;
      aiMsg.isStreaming = true;

      notifyListeners();

      Stream<String> stream = fakeStreamFromText(aiText);

      _sub = stream.listen((chunk) {
        if (isStopped) return;
        aiMsg.message += chunk;
        notifyListeners();
        scrollToBottom.call(scrollController);
      }, onDone: () {
        aiMsg.isStreaming = false;
        isTyping = false;
        notifyListeners();
      }, onError: (e) {
        isTyping = false;
        notifyListeners();
      });
    } catch (e) {
      isTyping = false;
      notifyListeners();
      print(e);
    }
  }

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
}
