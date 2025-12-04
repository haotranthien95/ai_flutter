/// Voucher type enum.
enum VoucherType {
  /// Percentage discount (e.g., 20%).
  percentage,

  /// Fixed amount discount (e.g., 50,000 VND).
  fixedAmount;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static VoucherType fromJson(String value) {
    return VoucherType.values.firstWhere(
      (VoucherType e) => e.name == value,
      orElse: () => VoucherType.percentage,
    );
  }

  /// Get display label in Vietnamese.
  String get displayName {
    switch (this) {
      case VoucherType.percentage:
        return 'Giảm theo phần trăm';
      case VoucherType.fixedAmount:
        return 'Giảm số tiền cố định';
    }
  }
}

/// Voucher entity for discount codes.
class Voucher {
  /// Creates a voucher instance.
  const Voucher({
    required this.id,
    required this.shopId,
    required this.code,
    required this.title,
    this.description,
    required this.type,
    required this.value,
    this.minOrderValue,
    this.maxDiscount,
    this.usageLimit,
    required this.usageCount,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  /// Voucher unique identifier (UUID).
  final String id;

  /// Shop ID (voucher owner).
  final String shopId;

  /// Discount code (e.g., "SALE20").
  final String code;

  /// Display name (e.g., "20% off orders above 500k").
  final String title;

  /// Usage terms and conditions.
  final String? description;

  /// Voucher type (PERCENTAGE, FIXED_AMOUNT).
  final VoucherType type;

  /// Discount value (20 for 20%, or fixed VND amount).
  final double value;

  /// Minimum order subtotal to apply voucher.
  final double? minOrderValue;

  /// Maximum discount cap (for percentage type).
  final double? maxDiscount;

  /// Total usage limit (null = unlimited).
  final int? usageLimit;

  /// Current usage count.
  final int usageCount;

  /// Voucher validity start date.
  final DateTime startDate;

  /// Voucher validity end date.
  final DateTime endDate;

  /// Seller can deactivate early.
  final bool isActive;

  /// Create Voucher from JSON.
  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['id'] as String,
      shopId: json['shopId'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      type: VoucherType.fromJson(json['type'] as String),
      value: (json['value'] as num).toDouble(),
      minOrderValue: (json['minOrderValue'] as num?)?.toDouble(),
      maxDiscount: (json['maxDiscount'] as num?)?.toDouble(),
      usageLimit: json['usageLimit'] as int?,
      usageCount: json['usageCount'] as int? ?? 0,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  /// Convert Voucher to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'shopId': shopId,
      'code': code,
      'title': title,
      'description': description,
      'type': type.toJson(),
      'value': value,
      'minOrderValue': minOrderValue,
      'maxDiscount': maxDiscount,
      'usageLimit': usageLimit,
      'usageCount': usageCount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
    };
  }

  /// Create a copy with updated fields.
  Voucher copyWith({
    String? id,
    String? shopId,
    String? code,
    String? title,
    String? description,
    VoucherType? type,
    double? value,
    double? minOrderValue,
    double? maxDiscount,
    int? usageLimit,
    int? usageCount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) {
    return Voucher(
      id: id ?? this.id,
      shopId: shopId ?? this.shopId,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxDiscount: maxDiscount ?? this.maxDiscount,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Check if voucher can be applied to an order.
  bool canApplyVoucher(double orderSubtotal) {
    if (!isActive) return false;
    final DateTime now = DateTime.now();
    if (now.isBefore(startDate) || now.isAfter(endDate)) return false;
    if (usageLimit != null && usageCount >= usageLimit!) return false;
    if (minOrderValue != null && orderSubtotal < minOrderValue!) return false;
    return true;
  }

  /// Calculate discount amount for a given order subtotal.
  double calculateDiscount(double orderSubtotal) {
    if (!canApplyVoucher(orderSubtotal)) return 0.0;

    if (type == VoucherType.percentage) {
      final double discount = orderSubtotal * (value / 100);
      if (maxDiscount != null && discount > maxDiscount!) {
        return maxDiscount!;
      }
      return discount;
    } else {
      // Fixed amount
      return value;
    }
  }

  /// Check if voucher is expired.
  bool get isExpired => DateTime.now().isAfter(endDate);

  /// Check if voucher is not yet valid.
  bool get isNotYetValid => DateTime.now().isBefore(startDate);

  /// Check if voucher is at usage limit.
  bool get isAtLimit => usageLimit != null && usageCount >= usageLimit!;

  /// Get formatted discount text (e.g., "Giảm 20%" or "Giảm 50.000 ₫").
  String get discountText {
    if (type == VoucherType.percentage) {
      return 'Giảm ${value.toInt()}%';
    } else {
      return 'Giảm ${value.toInt()} ₫';
    }
  }

  @override
  String toString() {
    return 'Voucher(id: $id, code: $code, type: $type, value: $value)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Voucher && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
