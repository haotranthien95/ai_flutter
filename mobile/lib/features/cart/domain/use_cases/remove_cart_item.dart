import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';

/// Use case for removing item from cart (T141).
class RemoveCartItemUseCase {
  /// Creates remove cart item use case.
  const RemoveCartItemUseCase(this._repository);

  final CartRepository _repository;

  /// Execute cart item removal.
  Future<void> execute(String cartItemId) async {
    return _repository.removeCartItem(cartItemId);
  }
}
