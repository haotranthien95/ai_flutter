/// Product condition enum.
enum ProductCondition {
  /// Brand new product.
  newProduct,

  /// Used/second-hand product.
  used,

  /// Refurbished product.
  refurbished;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static ProductCondition fromJson(String value) {
    return ProductCondition.values.firstWhere(
      (ProductCondition e) => e.name == value,
      orElse: () => ProductCondition.newProduct,
    );
  }

  /// Get display label in Vietnamese.
  String get displayName {
    switch (this) {
      case ProductCondition.newProduct:
        return 'Mới';
      case ProductCondition.used:
        return 'Đã sử dụng';
      case ProductCondition.refurbished:
        return 'Tân trang';
    }
  }
}

/// Product entity representing items sold on the platform.
class Product {
  /// Creates a product instance.
  const Product({
    required this.id,
    required this.shopId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.basePrice,
    required this.currency,
    required this.totalStock,
    required this.images,
    required this.condition,
    required this.averageRating,
    required this.totalReviews,
    required this.soldCount,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Product unique identifier (UUID).
  final String id;

  /// Shop ID (seller).
  final String shopId;

  /// Category ID for classification.
  final String categoryId;

  /// Product title.
  final String title;

  /// Product description (Markdown format).
  final String description;

  /// Base price in VND (display price if no variants).
  final double basePrice;

  /// Currency code (always "VND" for now).
  final String currency;

  /// Total available stock (sum of variant stocks if variants exist).
  final int totalStock;

  /// Product image URLs (1-10 images).
  final List<String> images;

  /// Product condition (NEW, USED, REFURBISHED).
  final ProductCondition condition;

  /// Average rating (1.0-5.0).
  final double averageRating;

  /// Total number of reviews.
  final int totalReviews;

  /// Total units sold (lifetime counter).
  final int soldCount;

  /// Active status (hidden if false).
  final bool isActive;

  /// Product creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Create Product from JSON.
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      categoryId: json['categoryId'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      basePrice: (json['basePrice'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
      totalStock: json['totalStock'] as int? ?? 0,
      images: (json['images'] as List<dynamic>?)
              ?.map((dynamic e) => e as String)
              .toList() ??
          <String>[],
      condition: ProductCondition.fromJson(json['condition'] as String),
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      soldCount: json['soldCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Product to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'categoryId': categoryId,
      'title': title,
      'description': description,
      'basePrice': basePrice,
      'currency': currency,
      'totalStock': totalStock,
      'images': images,
      'condition': condition.toJson(),
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'soldCount': soldCount,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Product copyWith({
    String? id,
    String? shopId,
    String? categoryId,
    String? title,
    String? description,
    double? basePrice,
    String? currency,
    int? totalStock,
    List<String>? images,
    ProductCondition? condition,
    double? averageRating,
    int? totalReviews,
    int? soldCount,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      currency: currency ?? this.currency,
      totalStock: totalStock ?? this.totalStock,
      images: images ?? this.images,
      condition: condition ?? this.condition,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      soldCount: soldCount ?? this.soldCount,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if product is in stock.
  bool get isInStock => totalStock > 0;

  /// Get primary image URL (first image or placeholder).
  String get primaryImageUrl =>
      images.isNotEmpty ? images.first : 'https://via.placeholder.com/300';

  /// Check if product has discount (requires finalPrice comparison).
  /// Note: This is a simplified check. Real discount requires variant/voucher logic.
  bool get hasDiscount => false; // Placeholder for future discount logic

  /// Get formatted rating (e.g., "4.5" or "Chưa có đánh giá").
  String get formattedRating {
    if (totalReviews == 0) return 'Chưa có đánh giá';
    return averageRating.toStringAsFixed(1);
  }

  /// Get review count text (e.g., "123 đánh giá").
  String get reviewCountText {
    if (totalReviews == 0) return 'Chưa có đánh giá';
    return '$totalReviews đánh giá';
  }

  /// Get sold count text (e.g., "Đã bán 1.5K").
  String get soldCountText {
    if (soldCount >= 1000) {
      return 'Đã bán ${(soldCount / 1000).toStringAsFixed(1)}K';
    }
    return 'Đã bán $soldCount';
  }

  @override
  String toString() {
    return 'Product(id: $id, title: $title, price: $basePrice, stock: $totalStock)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Product && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
