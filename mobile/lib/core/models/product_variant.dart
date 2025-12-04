/// Product variant entity for specific configurations (size, color, etc.).
class ProductVariant {
  /// Creates a product variant instance.
  const ProductVariant({
    required this.id,
    required this.productId,
    required this.name,
    required this.attributes,
    this.sku,
    required this.price,
    required this.stock,
    required this.isActive,
    required this.createdAt,
  });

  /// Variant unique identifier (UUID).
  final String id;

  /// Parent product ID.
  final String productId;

  /// Variant display name (e.g., "Red - Size M").
  final String name;

  /// Variant attributes (e.g., {"color": "Red", "size": "M"}).
  final Map<String, String> attributes;

  /// Stock Keeping Unit for inventory tracking.
  final String? sku;

  /// Variant-specific price in VND.
  final double price;

  /// Available quantity for this variant.
  final int stock;

  /// Availability status.
  final bool isActive;

  /// Variant creation timestamp.
  final DateTime createdAt;

  /// Create ProductVariant from JSON.
  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      productId: json['productId'] as String,
      name: json['name'] as String,
      attributes: Map<String, String>.from(json['attributes'] as Map),
      sku: json['sku'] as String?,
      price: (json['price'] as num).toDouble(),
      stock: json['stock'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Convert ProductVariant to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'name': name,
      'attributes': attributes,
      'sku': sku,
      'price': price,
      'stock': stock,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  ProductVariant copyWith({
    String? id,
    String? productId,
    String? name,
    Map<String, String>? attributes,
    String? sku,
    double? price,
    int? stock,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      attributes: attributes ?? this.attributes,
      sku: sku ?? this.sku,
      price: price ?? this.price,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if variant is in stock.
  bool get isInStock => stock > 0;

  /// Get formatted attributes (e.g., "Màu: Đỏ | Kích cỡ: M").
  String get formattedAttributes {
    return attributes.entries
        .map((MapEntry<String, String> e) => '${e.key}: ${e.value}')
        .join(' | ');
  }

  @override
  String toString() {
    return 'ProductVariant(id: $id, name: $name, price: $price, stock: $stock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductVariant && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
