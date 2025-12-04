/// Cart item entity representing a product in the user's cart.
class CartItem {
  /// Creates a cart item instance.
  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.variantId,
    required this.quantity,
    required this.addedAt,
    required this.updatedAt,
  });

  /// Cart item unique identifier (UUID).
  final String id;

  /// User ID who owns this cart item.
  final String userId;

  /// Product ID.
  final String productId;

  /// Product variant ID (null for simple products).
  final String? variantId;

  /// Number of units.
  final int quantity;

  /// Timestamp when added to cart.
  final DateTime addedAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Create CartItem from JSON.
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      quantity: json['quantity'] as int,
      addedAt: DateTime.parse(json['addedAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert CartItem to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'userId': userId,
      'productId': productId,
      'variantId': variantId,
      'quantity': quantity,
      'addedAt': addedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    String? variantId,
    int? quantity,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if cart item has a variant.
  bool get hasVariant => variantId != null;

  @override
  String toString() {
    return 'CartItem(id: $id, productId: $productId, quantity: $quantity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CartItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
