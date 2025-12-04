/// Order item entity representing a line item in an order.
class OrderItem {
  /// Creates an order item instance.
  const OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    this.variantId,
    required this.productSnapshot,
    this.variantSnapshot,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    required this.currency,
  });

  /// Order item unique identifier (UUID).
  final String id;

  /// Order ID.
  final String orderId;

  /// Product ID reference.
  final String productId;

  /// Product variant ID reference (null for simple products).
  final String? variantId;

  /// Product details at order time (title, image, price).
  final Map<String, dynamic> productSnapshot;

  /// Variant details at order time (if applicable).
  final Map<String, dynamic>? variantSnapshot;

  /// Number of units purchased.
  final int quantity;

  /// Price per unit at order time.
  final double unitPrice;

  /// Subtotal (quantity * unitPrice).
  final double subtotal;

  /// Currency code (always "VND" for now).
  final String currency;

  /// Create OrderItem from JSON.
  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      productId: json['productId'] as String,
      variantId: json['variantId'] as String?,
      productSnapshot:
          Map<String, dynamic>.from(json['productSnapshot'] as Map),
      variantSnapshot: json['variantSnapshot'] != null
          ? Map<String, dynamic>.from(json['variantSnapshot'] as Map)
          : null,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
      subtotal: (json['subtotal'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
    );
  }

  /// Convert OrderItem to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'orderId': orderId,
      'productId': productId,
      'variantId': variantId,
      'productSnapshot': productSnapshot,
      'variantSnapshot': variantSnapshot,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'currency': currency,
    };
  }

  /// Create a copy with updated fields.
  OrderItem copyWith({
    String? id,
    String? orderId,
    String? productId,
    String? variantId,
    Map<String, dynamic>? productSnapshot,
    Map<String, dynamic>? variantSnapshot,
    int? quantity,
    double? unitPrice,
    double? subtotal,
    String? currency,
  }) {
    return OrderItem(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      productId: productId ?? this.productId,
      variantId: variantId ?? this.variantId,
      productSnapshot: productSnapshot ?? this.productSnapshot,
      variantSnapshot: variantSnapshot ?? this.variantSnapshot,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      subtotal: subtotal ?? this.subtotal,
      currency: currency ?? this.currency,
    );
  }

  /// Get product title from snapshot.
  String get productTitle =>
      productSnapshot['title'] as String? ?? 'Unknown Product';

  /// Get product image URL from snapshot.
  String? get productImageUrl => productSnapshot['imageUrl'] as String?;

  /// Get variant name from snapshot.
  String? get variantName => variantSnapshot?['name'] as String?;

  /// Check if order item has a variant.
  bool get hasVariant => variantId != null;

  @override
  String toString() {
    return 'OrderItem(id: $id, productTitle: $productTitle, quantity: $quantity, unitPrice: $unitPrice)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is OrderItem && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
