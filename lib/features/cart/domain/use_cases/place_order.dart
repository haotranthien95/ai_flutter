import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';

/// Place order use case (T142 - stub implementation)
/// 
/// Creates orders from cart items with address, payment, and voucher details.
class PlaceOrderUseCase {
  /// Creates place order use case.
  const PlaceOrderUseCase(this._orderRepository);

  final OrderRepository _orderRepository;

  /// Execute place order.
  /// 
  /// Parameters:
  /// - [userId]: User ID placing the order
  /// - [items]: Cart items to convert to orders
  /// - [addressId]: Delivery address ID
  /// - [paymentMethod]: Payment method selected
  /// - [voucherCode]: Optional voucher code to apply
  /// - [notes]: Optional order notes
  /// 
  /// Returns list of created orders (one per shop).
  Future<List<Order>> execute({
    required String userId,
    required List<CartItem> items,
    required String addressId,
    required String paymentMethod,
    String? voucherCode,
    String? notes,
  }) async {
    return _orderRepository.createOrder(
      userId: userId,
      items: items,
      addressId: addressId,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      notes: notes,
    );
  }
}
