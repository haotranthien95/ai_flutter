/// Review entity for product feedback.
class Review {
  /// Creates a review instance.
  const Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.orderId,
    required this.rating,
    this.content,
    this.images,
    required this.isVerifiedPurchase,
    required this.isVisible,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Review unique identifier (UUID).
  final String id;

  /// Product ID being reviewed.
  final String productId;

  /// User ID (reviewer).
  final String userId;

  /// Order ID (verified purchase proof).
  final String orderId;

  /// Star rating (1 to 5).
  final int rating;

  /// Review text content.
  final String? content;

  /// Review photos (max 5).
  final List<String>? images;

  /// Verified purchase badge indicator.
  final bool isVerifiedPurchase;

  /// Visibility flag (admin can hide inappropriate reviews).
  final bool isVisible;

  /// Review submission timestamp.
  final DateTime createdAt;

  /// Last edit timestamp.
  final DateTime updatedAt;

  /// Create Review from JSON.
  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as String,
      productId: json['productId'] as String,
      userId: json['userId'] as String,
      orderId: json['orderId'] as String,
      rating: json['rating'] as int,
      content: json['content'] as String?,
      images: (json['images'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      isVerifiedPurchase: json['isVerifiedPurchase'] as bool? ?? true,
      isVisible: json['isVisible'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Review to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'productId': productId,
      'userId': userId,
      'orderId': orderId,
      'rating': rating,
      'content': content,
      'images': images,
      'isVerifiedPurchase': isVerifiedPurchase,
      'isVisible': isVisible,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Review copyWith({
    String? id,
    String? productId,
    String? userId,
    String? orderId,
    int? rating,
    String? content,
    List<String>? images,
    bool? isVerifiedPurchase,
    bool? isVisible,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Review(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      userId: userId ?? this.userId,
      orderId: orderId ?? this.orderId,
      rating: rating ?? this.rating,
      content: content ?? this.content,
      images: images ?? this.images,
      isVerifiedPurchase: isVerifiedPurchase ?? this.isVerifiedPurchase,
      isVisible: isVisible ?? this.isVisible,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if review has images.
  bool get hasImages => images != null && images!.isNotEmpty;

  /// Check if review can be edited (within 30 days).
  bool get canBeEdited {
    final Duration timeSinceCreated = DateTime.now().difference(createdAt);
    return timeSinceCreated.inDays <= 30;
  }

  /// Get star rating as formatted string (e.g., "★★★★★").
  String get starRating {
    return '★' * rating + '☆' * (5 - rating);
  }

  @override
  String toString() {
    return 'Review(id: $id, productId: $productId, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
