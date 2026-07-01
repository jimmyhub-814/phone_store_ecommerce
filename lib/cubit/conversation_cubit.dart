import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/conversation.dart';
import 'package:equatable/equatable.dart';

class ConversationState extends Equatable {
  final int unreadCount;

  const ConversationState({
    this.unreadCount = 0,
  });

  ConversationState copyWith({
    int? unreadCount,
  }) {
    return ConversationState(
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [unreadCount];
}

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit() : super(const ConversationState());

  StreamSubscription? _sub;

  void init() {
    _sub?.cancel();
    final userId = AuthHelper.userId;
    if (userId == null) return;

    _sub = Collections.conversations.doc(userId).snapshots().listen((doc) {
      if (!doc.exists || doc.data() == null) return;
      try {
        final conversation = Conversation.fromMap(doc.data()!);
        final count = conversation.unreadCount[UnreadCountBy.user.name] ?? 0;
        emit(state.copyWith(unreadCount: count));
      } catch (e) {
        print("❌ ConversationCubit error: $e");
      }
    });
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
