import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:phone_store/app_constants/app_local_messages.dart';
import 'package:phone_store/app_constants/auth_helper.dart';
import 'package:phone_store/app_constants/firestore_collections.dart';
import 'package:phone_store/models/conversation.dart';
import 'package:phone_store/models/message_model.dart';
import 'package:phone_store/provider/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:equatable/equatable.dart';

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

class MessageCubit extends Cubit<MessageState> {
  MessageCubit() : super(const MessageState());

  late Box localBox;

  Future<void> init() async {
    final boxName = AppLocalMessages.localMessages;

    if (!Hive.isBoxOpen(boxName)) {
      await Hive.openBox(boxName);
    }

    localBox = Hive.box(boxName);
  }

  String? get userId => AuthHelper.userId;
  // =========================
  // PRODUCT
  // =========================

  void setProduct(ProductMessage? product) {
    emit(state.copyWith(productMessage: product));
  }

  // =========================
  // STREAM MESSAGE
  // =========================

  Stream<Message> streamMessage(int after) {
    return Collections.messages(userId!)
        .where(Message.timeField, isGreaterThan: after)
        .snapshots(includeMetadataChanges: true)
        .expand((snapshot) => snapshot.docs)
        .where((doc) {
          return !doc.metadata.hasPendingWrites;
        })
        .map((doc) {
          try {
            return Message.fromMap(doc.data());
          } catch (e) {
            debugPrint('❌ Skip invalid message ${doc.id}: $e');
            return null;
          }
        })
        .where((m) => m != null)
        .cast<Message>();
  }

  // =========================
  // GET MESSAGE
  // =========================

  Future<List<Message>> getMessage() async {
    final querySnapshot = await Collections.messages(userId!)
        .orderBy(Message.timeField, descending: false)
        .limit(20)
        .get();

    List<Message> result = [];

    for (var doc in querySnapshot.docs) {
      try {
        result.add(Message.fromMap(doc.data()));
      } catch (_) {}
    }

    return result;
  }
  // =========================
  // GET MESSAGE BEFORE
  // =========================

  Future<List<Message>> getMessageBefore(
    int before,
  ) async {
    final querySnapshot = await Collections.messages(userId!)
        .where(Message.timeField, isLessThan: before)
        .orderBy(Message.timeField, descending: false)
        .limit(10)
        .get();

    List<Message> result = [];

    for (var doc in querySnapshot.docs) {
      try {
        result.add(
          Message.fromMap(doc.data()).copyWith(
            statusMessage: StatusMessage.sent,
          ),
        );
      } catch (_) {}
    }

    return result;
  }

  // =========================
  // LOAD MORE
  // =========================

  Future<void> loadMore() async {
    if (state.isLoadingMore) return;

    final firebaseMessages = state.messages
        .where((e) => e.statusMessage == StatusMessage.sent)
        .toList();

    if (firebaseMessages.isEmpty) return;

    emit(
      state.copyWith(
        isLoadingMore: true,
      ),
    );

    try {
      firebaseMessages.sort(
        (a, b) => a.time.compareTo(b.time),
      );

      final oldest = firebaseMessages.first;

      final olderMessages = await getMessageBefore(
        oldest.time,
      );

      final updated = [...state.messages];

      for (final msg in olderMessages) {
        final exists = updated.any((e) => e.id == msg.id);

        if (!exists) {
          updated.add(msg);
        }
      }

      updated.sort(
        (a, b) => b.time.compareTo(a.time),
      );

      emit(
        state.copyWith(
          messages: updated,
          isLoadingMore: false,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingMore: false,
        ),
      );
    }
  }
  // =========================
  // LOCAL
  // =========================

  List<Message> loadLocalMessages() {
    return localBox.values
        .map((e) {
          try {
            if (e is Map) {
              return Message.fromMap(
                Map<String, dynamic>.from(e),
              );
            }
          } catch (_) {}

          return null;
        })
        .whereType<Message>()
        .toList();
  }

  // =========================
  // INIT
  // =========================

  Future<void> initMessages() async {
    emit(const MessageState(isLoading: true));

    try {
      final firebaseMessages = await getMessage();

      final localMessages = loadLocalMessages();

      final Map<String, Message> mergedMap = {};

      for (final msg in firebaseMessages) {
        mergedMap[msg.id] = msg.copyWith(
          statusMessage: StatusMessage.sent,
        );
      }

      for (final local in localMessages) {
        mergedMap[local.id] = local;
      }

      final merged = mergedMap.values.toList();

      merged.sort((a, b) => b.time.compareTo(a.time));

      emit(
        state.copyWith(
          messages: merged,
          isLoading: false,
        ),
      );

      for (final msg in merged) {
        if (msg.statusMessage == StatusMessage.sending) {
          await localBox.put(msg.id, {
            ...msg.toMap(),
            Message.statusMessageField: StatusMessage.failed.name,
          });

          updateMessageStatus(
            msg.id,
            StatusMessage.failed,
          );
        }
      }
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  // =========================
  // FIREBASE MESSAGE
  // =========================
  List<Message> _sortMessages(List<Message> messages) {
    messages.sort(
      (a, b) => b.time.compareTo(a.time),
    );

    return messages;
  }

  Future<void> onFirebaseMessage(Message firebaseMsg) async {
    await localBox.delete(firebaseMsg.id);

    final updated = [...state.messages];

    updated.removeWhere((m) => m.id == firebaseMsg.id);

    updated.add(
      firebaseMsg.copyWith(
        statusMessage: StatusMessage.sent,
      ),
    );

    emit(
      state.copyWith(
        messages: _sortMessages(updated),
      ),
    );
  }

  // =========================
  // UPDATE STATUS
  // =========================

  void updateMessageStatus(
    String id,
    StatusMessage status,
  ) {
    final updated = state.messages.map((m) {
      if (m.id == id) {
        return m.copyWith(
          statusMessage: status,
        );
      }

      return m;
    }).toList();

    emit(
      state.copyWith(
        messages: updated,
      ),
    );
  }

  // =========================
  // SEND PROCESS
  // =========================

  Future<void> sendProcess(
    String text,
    BuildContext context,
  ) async {
    final id = const Uuid().v4();

    Message localMsg = Message(
      id: id,
      senderId: userId!,
      statusMessage: StatusMessage.sending,
      message: text,
      time: Timestamp.now().millisecondsSinceEpoch,
      isRead: false,
      product: state.productMessage,
    );

    emit(
      state.copyWith(
        productMessage: null,
      ),
    );

    await localBox.put(
      id,
      localMsg.toMap(),
    );

    emit(
      state.copyWith(
        messages: [
          localMsg,
          ...state.messages,
        ],
      ),
    );

    Timer(const Duration(seconds: 10), () async {
      final current = state.messages.where((e) => e.id == id).firstOrNull;

      if (current != null && current.statusMessage == StatusMessage.sending) {
        await localBox.put(id, {
          ...current.toMap(),
          Message.statusMessageField: StatusMessage.failed.name,
        });

        updateMessageStatus(
          id,
          StatusMessage.failed,
        );
      }
    });

    try {
      localMsg = Message(
        id: id,
        senderId: userId!,
        statusMessage: StatusMessage.sending,
        message: text,
        time: Timestamp.now().millisecondsSinceEpoch,
        isRead: false,
        product: state.productMessage,
      );

      await sendMessage(localMsg, context);
    } catch (_) {
      await localBox.put(id, {
        ...localMsg.toMap(),
        Message.statusMessageField: StatusMessage.failed.name,
      });

      updateMessageStatus(
        id,
        StatusMessage.failed,
      );
    }
  }

  // =========================
  // RETRY
  // =========================

  Future<void> retry(
    Message msg,
    BuildContext context,
  ) async {
    final retryMsg = msg.copyWith(
      statusMessage: StatusMessage.sending,
      time: Timestamp.now().millisecondsSinceEpoch,
    );

    await localBox.put(
      msg.id,
      retryMsg.toMap(),
    );

    final updated = state.messages.map((e) {
      return e.id == msg.id ? retryMsg : e;
    }).toList();

    emit(state.copyWith(messages: updated));

    Timer(const Duration(seconds: 10), () async {
      final current = state.messages.where((e) => e.id == msg.id).firstOrNull;

      if (current != null && current.statusMessage == StatusMessage.sending) {
        await localBox.put(msg.id, {
          ...current.toMap(),
          Message.statusMessageField: StatusMessage.failed.name,
        });

        updateMessageStatus(
          msg.id,
          StatusMessage.failed,
        );
      }
    });

    try {
      await sendMessage(retryMsg, context);
    } catch (_) {
      await localBox.put(msg.id, {
        ...retryMsg.toMap(),
        Message.statusMessageField: StatusMessage.failed.name,
      });

      updateMessageStatus(
        msg.id,
        StatusMessage.failed,
      );
    }
  }

  // =========================
  // SEND FIREBASE
  // =========================

  Future<void> sendMessage(
    Message message,
    BuildContext context,
  ) async {
    if (message.message.isEmpty) return;

    final ref = Collections.conversations.doc(userId);

    final messageRef = Collections.messages(userId!).doc(message.id);

    final now = Timestamp.now().millisecondsSinceEpoch;

    final batch = FirebaseFirestore.instance.batch();

    batch.set(
      ref,
      {
        Conversation.userIdField: userId,
        Conversation.lastMessageField: message.message,
        Conversation.lastMessageByField: UnreadCountBy.user.name,
        Conversation.lastMessageTimeField: now,
        Conversation.unreadCountField: {
          UnreadCountBy.admin.name: FieldValue.increment(1),
          UnreadCountBy.user.name: 0
        },
      },
      SetOptions(merge: true),
    );

    batch.set(
      messageRef,
      {
        ...message.toMap(),
        Message.timeField: now,
        Message.statusMessageField: StatusMessage.sent.name,
      },
    );

    await batch.commit();

    await FirebaseFirestore.instance.waitForPendingWrites();
  }
}
