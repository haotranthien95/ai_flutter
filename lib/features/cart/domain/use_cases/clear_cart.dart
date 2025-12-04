import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';

/// Use case for clearing user's cart (T143).
class ClearCartUseCase {
  /// Creates clear cart use case.
  const ClearCartUseCase(this._repository);

  final CartRepository _repository;

  /// Execute clear cart.
  Future<void> execute(String userId) async {
    return _repository.clearCart(userId);
  }
}
