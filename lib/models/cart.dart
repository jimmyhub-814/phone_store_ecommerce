class Cart {
  static const idField = 'id';
  static const productIdField = 'productId';
  static const variantsIdField = 'variantsId';
  static const quantityField = 'quantity';

  String id;
  String productId;
  String variantsId;
  int quantity;

  Cart({
    required this.id,
    required this.productId,
    required this.variantsId,
    required this.quantity,
  });

  Map<String, dynamic> toMap() {
    return {
      idField: id,
      productIdField: productId,
      variantsIdField: variantsId,
      quantityField: quantity,
    };
  }

  factory Cart.fromMap(Map<String, dynamic> map) {
    return Cart(
      id: map[idField] ?? '',
      productId: map[productIdField] ?? '',
      variantsId: map[variantsIdField] ?? '',
      quantity: map[quantityField] ?? 0,
    );
  }
}
