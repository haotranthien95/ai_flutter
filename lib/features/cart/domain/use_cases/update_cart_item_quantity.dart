import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';

/// Use case for updating cart item quantity (T140).
class UpdateCartItemQuantityUseCase {
  /// Creates update quantity use case.
  const UpdateCartItemQuantityUseCase(this._repository);

  final CartRepository _repository;

  /// Execute quantity update.
  ///
  /// Validates quantity > 0.
  Future<CartItem> execute({
    required String cartItemId,
    required int quantity,
  }) async {
    // Validate quantity
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0');
    }

    return _repository.updateQuantity(
      cartItemId: cartItemId,
      quantity: quantity,
    );
  }
}
