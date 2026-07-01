import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:phone_store/app_constants/api_helper.dart';
import 'package:phone_store/models/AI.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

class GeminiAIState extends Equatable {
  final bool isTyping;
  final bool isStopped;
  final List<AIModel> messageList;

  const GeminiAIState({
    this.isTyping = false,
    this.isStopped = false,
    this.messageList = const [],
  });

  GeminiAIState copyWith({
    bool? isTyping,
    bool? isStopped,
    List<AIModel>? messageList,
  }) {
    return GeminiAIState(
      isTyping: isTyping ?? this.isTyping,
      isStopped: isStopped ?? this.isStopped,
      messageList: messageList ?? this.messageList,
    );
  }

  @override
  List<Object?> get props => [isTyping, isStopped, messageList];
}

class AIModelCubit extends Cubit<GeminiAIState> {
  AIModelCubit() : super(const GeminiAIState());

  VoidCallback? onShouldScrollToBottom;
  StreamSubscription? _sub;

  Stream<String> fakeStreamFromText(String text) async* {
    for (int i = 0; i < text.length; i++) {
      await Future.delayed(const Duration(milliseconds: 5));
      yield text[i];
    }
  }

  void clearMessages() {
    _sub?.cancel();
    emit(const GeminiAIState());
  }

  void stopResponse() {
    _sub?.cancel();
    if (state.messageList.isNotEmpty) {
      final lastMsg = state.messageList.last;
      lastMsg.isLoading = false;
      lastMsg.isStreaming = false;
    }

    final updatedList = List<AIModel>.from(state.messageList);
    emit(state.copyWith(
        isTyping: false, isStopped: true, messageList: updatedList));
  }

  Future<void> sendMessage({required String message}) async {
    if (state.isTyping) return;
    emit(state.copyWith(isTyping: true, isStopped: false));

    try {
      final userMsg = AIModel(
        id: const Uuid().v4(),
        message: message,
        time: DateTime.now().millisecondsSinceEpoch,
        isUser: true,
      );

      final AIModel aiMsg = AIModel(
        id: const Uuid().v4(),
        message: "",
        isUser: false,
        time: DateTime.now().millisecondsSinceEpoch,
        isLoading: true,
      );

      final listWithLoading = List<AIModel>.from(state.messageList)
        ..add(userMsg)
        ..add(aiMsg);

      emit(state.copyWith(messageList: listWithLoading));

      final aiText = await ApiHelper().sendMsgApi(msg: message);
      if (state.isStopped) return;

      aiMsg.isLoading = false;
      aiMsg.isStreaming = true;

      final listReady = List<AIModel>.from(state.messageList);
      emit(state.copyWith(messageList: listReady));

      _sub = fakeStreamFromText(aiText).listen(
        (chunk) {
          if (state.isStopped) return;
          aiMsg.message += chunk;
          onShouldScrollToBottom?.call();
          final updatedList = List<AIModel>.from(state.messageList);
          emit(state.copyWith(messageList: updatedList));
        },
        onDone: () {
          _sub = null;
          aiMsg.isStreaming = false;
          final updatedList = List<AIModel>.from(state.messageList);
          emit(state.copyWith(isTyping: false, messageList: updatedList));
        },
        onError: (_) {
          emit(state.copyWith(isTyping: false));
        },
      );
    } catch (e) {
      emit(state.copyWith(isTyping: false));
      debugPrint(e.toString());
    }
  }
}
