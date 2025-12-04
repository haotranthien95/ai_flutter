import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/core/models/voucher.dart';
import 'package:ai_flutter/core/models/cart_item.dart';

/// Repository interface for order operations.
abstract class OrderRepository {
  /// Create order from cart items.
  Future<List<Order>> createOrder({
    required String userId,
    required List<CartItem> items,
    required String addressId,
    required String paymentMethod,
    String? voucherCode,
    String? notes,
  });

  /// Get orders for user.
  Future<List<Order>> getOrders({
    required String userId,
    String? status,
    int? limit,
    String? cursor,
  });

  /// Get order detail.
  Future<Order> getOrderDetail(String orderId);

  /// Cancel order.
  Future<Order> cancelOrder({
    required String orderId,
    required String reason,
    String? notes,
  });

  /// Validate voucher.
  Future<Voucher> validateVoucher({
    required String voucherCode,
    required String shopId,
    required double orderSubtotal,
  });

  /// Get available vouchers for shop.
  Future<List<Voucher>> getAvailableVouchers({
    required String shopId,
    required double orderSubtotal,
  });
}
