import 'package:ai_flutter/core/models/order.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';
import 'package:ai_flutter/features/cart/domain/repositories/order_repository.dart';

/// Use case for checkout (T145).
class CheckoutUseCase {
  /// Creates checkout use case.
  const CheckoutUseCase(this._cartRepository, this._orderRepository);

  final CartRepository _cartRepository;
  final OrderRepository _orderRepository;

  /// Execute checkout.
  ///
  /// Creates order(s) from cart items and clears cart on success.
  Future<List<Order>> execute({
    required String userId,
    required String addressId,
    required String paymentMethod,
    String? voucherCode,
    String? notes,
  }) async {
    // Get cart items
    final cartItems = await _cartRepository.getCart(userId);

    if (cartItems.isEmpty) {
      throw Exception('Cart is empty');
    }

    // Create order(s)
    final orders = await _orderRepository.createOrder(
      userId: userId,
      items: cartItems,
      addressId: addressId,
      paymentMethod: paymentMethod,
      voucherCode: voucherCode,
      notes: notes,
    );

    // Clear cart after successful order creation
    await _cartRepository.clearCart(userId);

    return orders;
  }
}
