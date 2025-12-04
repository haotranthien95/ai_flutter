/// Shop status enum.
enum ShopStatus {
  /// Shop pending approval.
  pending,

  /// Shop active and visible.
  active,

  /// Shop suspended by admin.
  suspended;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static ShopStatus fromJson(String value) {
    return ShopStatus.values.firstWhere(
      (ShopStatus e) => e.name == value,
      orElse: () => ShopStatus.pending,
    );
  }

  /// Get display label in Vietnamese.
  String get displayName {
    switch (this) {
      case ShopStatus.pending:
        return 'Chờ duyệt';
      case ShopStatus.active:
        return 'Đang hoạt động';
      case ShopStatus.suspended:
        return 'Đã tạm ngưng';
    }
  }
}

/// Shop entity representing a seller's store.
class Shop {
  /// Creates a shop instance.
  const Shop({
    required this.id,
    required this.ownerId,
    required this.shopName,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.businessAddress,
    required this.rating,
    required this.totalRatings,
    required this.followerCount,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Shop unique identifier (UUID).
  final String id;

  /// Owner user ID (seller).
  final String ownerId;

  /// Shop display name.
  final String shopName;

  /// Shop description (Markdown format).
  final String? description;

  /// Shop logo URL.
  final String? logoUrl;

  /// Shop cover image URL.
  final String? coverImageUrl;

  /// Business address (can differ from shipping address).
  final String? businessAddress;

  /// Shop average rating (1.0-5.0, computed from product reviews).
  final double rating;

  /// Total number of ratings.
  final int totalRatings;

  /// Number of users following this shop.
  final int followerCount;

  /// Shop status (PENDING, ACTIVE, SUSPENDED).
  final ShopStatus status;

  /// Shop creation timestamp.
  final DateTime createdAt;

  /// Last update timestamp.
  final DateTime updatedAt;

  /// Create Shop from JSON.
  factory Shop.fromJson(Map<String, dynamic> json) {
    return Shop(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String,
      shopName: json['shopName'] as String,
      description: json['description'] as String?,
      logoUrl: json['logoUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      businessAddress: json['businessAddress'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalRatings: json['totalRatings'] as int? ?? 0,
      followerCount: json['followerCount'] as int? ?? 0,
      status: ShopStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// Convert Shop to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ownerId': ownerId,
      'shopName': shopName,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'businessAddress': businessAddress,
      'rating': rating,
      'totalRatings': totalRatings,
      'followerCount': followerCount,
      'status': status.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Shop copyWith({
    String? id,
    String? ownerId,
    String? shopName,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? businessAddress,
    double? rating,
    int? totalRatings,
    int? followerCount,
    ShopStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Shop(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      shopName: shopName ?? this.shopName,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      businessAddress: businessAddress ?? this.businessAddress,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      followerCount: followerCount ?? this.followerCount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Check if shop is active.
  bool get isActive => status == ShopStatus.active;

  /// Check if shop is pending approval.
  bool get isPending => status == ShopStatus.pending;

  /// Check if shop is suspended.
  bool get isSuspended => status == ShopStatus.suspended;

  /// Get formatted rating (e.g., "4.5" or "Chưa có đánh giá").
  String get formattedRating {
    if (totalRatings == 0) return 'Chưa có đánh giá';
    return rating.toStringAsFixed(1);
  }

  /// Get follower count text (e.g., "1.5K người theo dõi").
  String get followerCountText {
    if (followerCount >= 1000) {
      return '${(followerCount / 1000).toStringAsFixed(1)}K người theo dõi';
    }
    return '$followerCount người theo dõi';
  }

  @override
  String toString() {
    return 'Shop(id: $id, shopName: $shopName, status: $status, rating: $rating)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Shop && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
