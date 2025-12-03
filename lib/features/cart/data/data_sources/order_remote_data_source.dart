import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/core/models/voucher.dart';
import 'package:dio/dio.dart';

/// Remote data source for order operations (T135).
class OrderRemoteDataSource {
  /// Creates order remote data source.
  const OrderRemoteDataSource(this._dio);

  final Dio _dio;

  /// Creates order from cart items.
  /// Returns list of orders (one per shop).
  Future<List<Order>> createOrder({
    required String userId,
    required List<CartItem> items,
    required String addressId,
    required String paymentMethod,
    String? voucherCode,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders',
      data: {
        'userId': userId,
        'items': items.map((item) => item.toJson()).toList(),
        'addressId': addressId,
        'paymentMethod': paymentMethod,
        if (voucherCode != null) 'voucherCode': voucherCode,
        if (notes != null) 'notes': notes,
      },
    );

    final ordersData = response.data!['orders'] as List<dynamic>;
    return ordersData.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Gets user's orders with optional filters.
  Future<List<Order>> getOrders({
    required String userId,
    String? status,
    int? limit,
    String? cursor,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/orders',
      queryParameters: {
        'userId': userId,
        if (status != null) 'status': status,
        if (limit != null) 'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );

    final ordersData = response.data!['orders'] as List<dynamic>;
    return ordersData.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Gets order detail by ID.
  Future<Order> getOrderDetail(String orderId) async {
    final response = await _dio.get<Map<String, dynamic>>('/orders/$orderId');
    return Order.fromJson(response.data!);
  }

  /// Cancels order with reason.
  Future<Order> cancelOrder({
    required String orderId,
    required String reason,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/orders/$orderId/cancel',
      data: {
        'reason': reason,
        if (notes != null) 'notes': notes,
      },
    );

    return Order.fromJson(response.data!);
  }

  /// Validates voucher code for shop and order subtotal.
  Future<Voucher> validateVoucher({
    required String voucherCode,
    required String shopId,
    required double orderSubtotal,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/vouchers/validate',
      data: {
        'code': voucherCode,
        'shopId': shopId,
        'orderSubtotal': orderSubtotal,
      },
    );

    return Voucher.fromJson(response.data!);
  }

  /// Gets available vouchers for shop and order subtotal.
  Future<List<Voucher>> getAvailableVouchers({
    required String shopId,
    required double orderSubtotal,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/vouchers/available',
      queryParameters: {
        'shopId': shopId,
        'orderSubtotal': orderSubtotal,
      },
    );

    final vouchersData = response.data!['vouchers'] as List<dynamic>;
    return vouchersData.map((json) => Voucher.fromJson(json as Map<String, dynamic>)).toList();
  }
}
