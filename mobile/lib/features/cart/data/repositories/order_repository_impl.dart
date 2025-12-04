import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/core/models/voucher.dart';
import 'package:ai_flutter/features/cart/data/data_sources/order_remote_data_source.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';

/// Order repository implementation (T136).
class OrderRepositoryImpl implements OrderRepository {
  /// Creates order repository.
  const OrderRepositoryImpl(this._remoteDataSource);

  final OrderRemoteDataSource _remoteDataSource;

  @override
  Future<List<Order>> createOrder({
    required String userId,
    required List<CartItem> items,
    required String addressId,
    required String paymentMethod,
    String? voucherCode,
    String? notes,
  }) async {
    return _remoteDataSource.createOrder(
      userId: userId,
      items: items,
      addressId: addressId,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      notes: notes,
    );
  }

  @override
  Future<List<Order>> getOrders({
    required String userId,
    String? status,
    int? limit,
    String? cursor,
  }) async {
    return _remoteDataSource.getOrders(
      userId: userId,
      status: status,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  Future<Order> getOrderDetail(String orderId) async {
    return _remoteDataSource.getOrderDetail(orderId);
  }

  @override
  Future<Order> cancelOrder({
    required String orderId,
    required String reason,
    String? notes,
  }) async {
    return _remoteDataSource.cancelOrder(
      orderId: orderId,
      reason: reason,
      notes: notes,
    );
  }

  @override
  Future<Voucher> validateVoucher({
    required String voucherCode,
    required String shopId,
    required double orderSubtotal,
  }) async {
    return _remoteDataSource.validateVoucher(
      voucherCode: voucherCode,
      shopId: shopId,
      orderSubtotal: orderSubtotal,
    );
  }

  @override
  Future<List<Voucher>> getAvailableVouchers({
    required String shopId,
    required double orderSubtotal,
  }) async {
    return _remoteDataSource.getAvailableVouchers(
      shopId: shopId,
      orderSubtotal: orderSubtotal,
    );
  }
}
