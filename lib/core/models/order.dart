/// Order status enum.
enum OrderStatus {
  /// Order placed, awaiting seller confirmation.
  pending,

  /// Seller confirmed order.
  confirmed,

  /// Seller packed the order.
  packed,

  /// Order is being shipped.
  shipping,

  /// Order delivered to buyer.
  delivered,

  /// Order completed (7 days after delivery).
  completed,

  /// Order cancelled by buyer or seller.
  cancelled,

  /// Buyer requested return.
  returnRequested,

  /// Return approved and processed.
  returned;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static OrderStatus fromJson(String value) {
    return OrderStatus.values.firstWhere(
      (OrderStatus e) => e.name == value,
      orElse: () => OrderStatus.pending,
    );
  }

  /// Get display label in Vietnamese.
  String get displayName {
    switch (this) {
      case OrderStatus.pending:
        return 'Chờ xác nhận';
      case OrderStatus.confirmed:
        return 'Đã xác nhận';
      case OrderStatus.packed:
        return 'Đã đóng gói';
      case OrderStatus.shipping:
        return 'Đang giao';
      case OrderStatus.delivered:
        return 'Đã giao';
      case OrderStatus.completed:
        return 'Hoàn thành';
      case OrderStatus.cancelled:
        return 'Đã hủy';
      case OrderStatus.returnRequested:
        return 'Yêu cầu trả hàng';
      case OrderStatus.returned:
        return 'Đã trả hàng';
    }
  }
}

/// Payment method enum.
enum PaymentMethod {
  /// Cash on delivery.
  cod,

  /// Bank transfer (future).
  bankTransfer,

  /// E-wallet (future).
  eWallet;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static PaymentMethod fromJson(String value) {
    return PaymentMethod.values.firstWhere(
      (PaymentMethod e) => e.name == value,
      orElse: () => PaymentMethod.cod,
    );
  }

  /// Get display label in Vietnamese.
  String get displayName {
    switch (this) {
      case PaymentMethod.cod:
        return 'Thanh toán khi nhận hàng';
      case PaymentMethod.bankTransfer:
        return 'Chuyển khoản ngân hàng';
      case PaymentMethod.eWallet:
        return 'Ví điện tử';
    }
  }
}

/// Payment status enum.
enum PaymentStatus {
  /// Payment pending.
  pending,

  /// Payment completed.
  paid,

  /// Payment failed.
  failed,

  /// Payment refunded.
  refunded;

  /// Convert enum to string for JSON serialization.
  String toJson() => name;

  /// Convert string to enum.
  static PaymentStatus fromJson(String value) {
    return PaymentStatus.values.firstWhere(
      (PaymentStatus e) => e.name == value,
      orElse: () => PaymentStatus.pending,
    );
  }

  /// Get display label in Vietnamese.
  String get displayName {
    switch (this) {
      case PaymentStatus.pending:
        return 'Chờ thanh toán';
      case PaymentStatus.paid:
        return 'Đã thanh toán';
      case PaymentStatus.failed:
        return 'Thanh toán thất bại';
      case PaymentStatus.refunded:
        return 'Đã hoàn tiền';
    }
  }
}

/// Order entity representing a transaction.
class Order {
  /// Creates an order instance.
  const Order({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.shopId,
    required this.addressId,
    required this.shippingAddress,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.subtotal,
    required this.shippingFee,
    required this.discount,
    required this.total,
    required this.currency,
    this.voucherCode,
    this.notes,
    this.cancellationReason,
    required this.createdAt,
    required this.updatedAt,
    this.completedAt,
  });

  /// Order unique identifier (UUID).
  final String id;

  /// Human-readable order number (e.g., "ORD-20231203-ABCD").
  final String orderNumber;

  /// Buyer user ID.
  final String buyerId;

  /// Shop ID (seller).
  final String shopId;

  /// Shipping address ID reference.
  final String addressId;

  /// Shipping address snapshot (preserved if address deleted).
  final Map<String, dynamic> shippingAddress;

  /// Order status.
  final OrderStatus status;

  /// Payment method.
  final PaymentMethod paymentMethod;

  /// Payment status.
  final PaymentStatus paymentStatus;

  /// Order subtotal (sum of order items).
  final double subtotal;

  /// Shipping fee.
  final double shippingFee;

  /// Applied discount amount.
  final double discount;

  /// Total amount (subtotal + shippingFee - discount).
  final double total;

  /// Currency code (always "VND" for now).
  final String currency;

  /// Applied voucher code.
  final String? voucherCode;

  /// Buyer notes to seller.
  final String? notes;

  /// Cancellation reason.
  final String? cancellationReason;

  /// Order placement timestamp.
  final DateTime createdAt;

  /// Last status update timestamp.
  final DateTime updatedAt;

  /// Delivery completion timestamp.
  final DateTime? completedAt;

  /// Create Order from JSON.
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['orderNumber'] as String,
      buyerId: json['buyerId'] as String,
      shopId: json['shopId'] as String,
      addressId: json['addressId'] as String,
      shippingAddress:
          Map<String, dynamic>.from(json['shippingAddress'] as Map),
      status: OrderStatus.fromJson(json['status'] as String),
      paymentMethod: PaymentMethod.fromJson(json['paymentMethod'] as String),
      paymentStatus: PaymentStatus.fromJson(json['paymentStatus'] as String),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingFee: (json['shippingFee'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'VND',
      voucherCode: json['voucherCode'] as String?,
      notes: json['notes'] as String?,
      cancellationReason: json['cancellationReason'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  /// Convert Order to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'orderNumber': orderNumber,
      'buyerId': buyerId,
      'shopId': shopId,
      'addressId': addressId,
      'shippingAddress': shippingAddress,
      'status': status.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'paymentStatus': paymentStatus.toJson(),
      'subtotal': subtotal,
      'shippingFee': shippingFee,
      'discount': discount,
      'total': total,
      'currency': currency,
      'voucherCode': voucherCode,
      'notes': notes,
      'cancellationReason': cancellationReason,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  /// Create a copy with updated fields.
  Order copyWith({
    String? id,
    String? orderNumber,
    String? buyerId,
    String? shopId,
    String? addressId,
    Map<String, dynamic>? shippingAddress,
    OrderStatus? status,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    double? subtotal,
    double? shippingFee,
    double? discount,
    double? total,
    String? currency,
    String? voucherCode,
    String? notes,
    String? cancellationReason,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNumber: orderNumber ?? this.orderNumber,
      buyerId: buyerId ?? this.buyerId,
      shopId: shopId ?? this.shopId,
      addressId: addressId ?? this.addressId,
      shippingAddress: shippingAddress ?? this.shippingAddress,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      subtotal: subtotal ?? this.subtotal,
      shippingFee: shippingFee ?? this.shippingFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      currency: currency ?? this.currency,
      voucherCode: voucherCode ?? this.voucherCode,
      notes: notes ?? this.notes,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  /// Check if order can be cancelled by buyer.
  bool get canBeCancelled {
    return status == OrderStatus.pending || status == OrderStatus.confirmed;
  }

  /// Check if order is completed.
  bool get isCompleted => status == OrderStatus.completed;

  /// Check if order is cancelled.
  bool get isCancelled => status == OrderStatus.cancelled;

  /// Check if payment is pending.
  bool get isPaymentPending => paymentStatus == PaymentStatus.pending;

  @override
  String toString() {
    return 'Order(id: $id, orderNumber: $orderNumber, status: $status, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Order && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
