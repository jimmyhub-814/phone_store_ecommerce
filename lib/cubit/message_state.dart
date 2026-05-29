import 'package:equatable/equatable.dart';
import 'package:phone_store/models/message_model.dart';

class MessageState extends Equatable {
  final bool isLoading;
  final bool isLoadingMore;
  final List<Message> messages;
  final ProductMessage? productMessage;

  const MessageState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.messages = const [],
    this.productMessage,
  });

  MessageState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<Message>? messages,
    ProductMessage? productMessage,
  }) {
    return MessageState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      messages: messages ?? this.messages,
      productMessage: productMessage ?? this.productMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isLoadingMore,
        messages,
        productMessage,
      ];
}
