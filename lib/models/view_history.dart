import 'package:cloud_firestore/cloud_firestore.dart';

class ViewHistory {
  static const idField = 'id';
  static const productIdField = 'productId';
  static const categoryIdField = 'categoryId';
  static const phoneNameField = 'phoneName';
  static const viewCountField = 'viewCount';
  static const createAtField = 'createAt';

  String id;
  String productId;
  String categoryId;
  String phoneName;
  int viewCount;
  Timestamp createAt;

  ViewHistory({
    required this.id,
    required this.productId,
    required this.categoryId,
    required this.phoneName,
    required this.viewCount,
    required this.createAt,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      productIdField: productId,
      categoryIdField: categoryId,
      phoneNameField: phoneName,
      viewCountField: viewCount,
      createAtField: createAt,
    };
  }

  factory ViewHistory.fromMap(Map<String, dynamic> map) {
    return ViewHistory(
      id: map[idField] ?? '',
      productId: map[productIdField] ?? '',
      categoryId: map[categoryIdField] ?? '',
      phoneName: map[phoneNameField] ?? '',
      viewCount: map[viewCountField] ?? '',
      createAt: map[createAtField] ?? '',
    );
  }
}
