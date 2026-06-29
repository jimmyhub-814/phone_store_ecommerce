import 'package:cloud_firestore/cloud_firestore.dart';

class AIModel {
  static const idField = 'id';
  static const timeField = 'time';
  static const messageField = 'message';
  static const isUserField = 'isUser';
  static const isStreamingField = 'isStreaming';
  static const isLoadingField = 'isLoading';

  final String id;
  String message;
  final int time;
  bool isUser;
  bool isStreaming;
  bool isLoading;
  
  AIModel({
    required this.id,
    required this.message,
    required this.time,
    required this.isUser,
    this.isStreaming = false,
    this.isLoading = false,
  });

  Map<String, dynamic> toMap() => {
        idField: id,
        messageField: message,
        timeField: time,
        isUserField: isUser,
        isStreamingField: isStreaming,
        isLoadingField: isLoading,
      };

  factory AIModel.fromMap(Map<String, dynamic> map) {
    final rawTime = map[timeField];
    final int time = rawTime is Timestamp
        ? rawTime.millisecondsSinceEpoch
        : rawTime is int
            ? rawTime
            : 0;

    return AIModel(
      id: map[idField] ?? '',
      message: map[messageField] ?? '',
      time: time,
      isUser: map[isUserField] ?? '',
      isStreaming: map[isStreamingField] ?? '',
      isLoading: map[isLoadingField] ?? '',
    );
  }
}
