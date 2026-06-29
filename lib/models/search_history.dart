import 'package:cloud_firestore/cloud_firestore.dart';

class SearchHistory {
  static const idField = 'id';
  static const contentField = 'content';
  static const createAtField = 'createAt';

  String id;
  String content;
  Timestamp createAt;

  SearchHistory({
    required this.id,
    required this.content,
    required this.createAt,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      contentField: content,
      createAtField: createAt,
    };
  }

  factory SearchHistory.fromMap(Map<String, dynamic> map) {
    return SearchHistory(
      id: map[idField] ?? '',
      content: map[contentField] ?? '',
      createAt: map[createAtField] ?? '',
    );
  }
}
