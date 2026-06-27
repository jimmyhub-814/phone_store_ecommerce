import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/api_helper.dart';
import 'package:phone_store/models/AI.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

class GeminiAIState extends Equatable {
  final ScrollController scrollController;
  final bool isTyping;
  final bool isStopped;
  final StreamSubscription? sub;
  final List<AIModel> messageList;

  const GeminiAIState({
    required this.scrollController,
    this.isTyping = false,
    this.isStopped = false,
    this.sub,
    this.messageList = const [],
  });

  GeminiAIState copyWith({
    ScrollController? scrollController,
    bool? isTyping,
    bool? isStopped,
    StreamSubscription? sub,
    List<AIModel>? messageList,
  }) {
    return GeminiAIState(
      scrollController: scrollController ?? this.scrollController,
      isTyping: isTyping ?? this.isTyping,
      isStopped: isStopped ?? this.isStopped,
      sub: sub ?? this.sub,
      messageList: messageList ?? this.messageList,
    );
  }

  @override
  List<Object?> get props => [
        scrollController,
        isTyping,
        isStopped,
        sub,
        messageList,
      ];
}

class AIModelCubit extends Cubit<GeminiAIState> {
  AIModelCubit()
      : super(GeminiAIState(scrollController: ScrollController())) ;
     Stream<String> fakeStreamFromText(String text) async* {
      for (int i = 0; i < text.length; i++) {
        await Future.delayed(const Duration(milliseconds: 20));
        yield text[i];
      }
    }
    void stopResponse() {
      emit(state.copyWith(isStopped: true)); 
      state.sub?.cancel();
      emit(state.copyWith(isTyping: false));

      if (state.messageList.isNotEmpty) {
        final lastMsg = state.messageList.last;
 
        lastMsg.isLoading = false;
        lastMsg.isStreaming = false;
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

    Future<void> sendMessage({required String message}) async {
      if (state.isTyping) return;
      emit(state.copyWith(isTyping: true));

      try {
        state.messageList.add(
          AIModel(
            id: const Uuid().v4(),
            message: message,
            time: DateTime.now().millisecondsSinceEpoch,
            isUser: true,
          ),
        );

        AIModel aiMsg = AIModel(
          id: const Uuid().v4(),
          message: "",
          isUser: false,
          time: DateTime.now().millisecondsSinceEpoch,
          isLoading: true,
        );

        state.messageList.add(aiMsg);

        final aiText = await ApiHelper().sendMsgApi(msg: message);
        if (state.isStopped) return;
        aiMsg.isLoading = false;
        aiMsg.isStreaming = true;

        Stream<String> stream = fakeStreamFromText(aiText);

        final subscription = stream.listen((chunk) {
          if (state.isStopped) return;
          aiMsg.message += chunk;

          scrollToBottom.call(state.scrollController);
        }, onDone: () {
          aiMsg.isStreaming = false;
          emit(state.copyWith(isTyping: false));
        }, onError: (e) {
          emit(state.copyWith(isTyping: false));
        });
        emit(state.copyWith(sub: subscription));
      } catch (e) {
        emit(state.copyWith(isTyping: false));

        print(e);
      }
    }
  }
