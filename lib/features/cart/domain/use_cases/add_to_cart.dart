import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';

/// Use case for adding product to cart (T139).
class AddToCartUseCase {
  /// Creates add to cart use case.
  const AddToCartUseCase(this._repository);

  final CartRepository _repository;

  /// Execute add to cart.
  ///
  /// Validates quantity > 0 and checks if item already exists.
  /// If exists with same variant, updates quantity instead.
  Future<CartItem> execute({
    required String userId,
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    // Validate quantity
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than 0');
    }

    // Get existing cart to check for duplicates
    final existingCart = await _repository.getCart(userId);

    // Check if item already exists with same product and variant
    final existingItem = existingCart.firstWhere(
      (item) => item.productId == productId && item.variantId == variantId,
      orElse: () => CartItem(
        id: '',
        userId: '',
        productId: '',
        variantId: null,
        quantity: 0,
        addedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    if (existingItem.id.isNotEmpty) {
      // Update existing item quantity
      final newQuantity = existingItem.quantity + quantity;
      return _repository.updateQuantity(
        cartItemId: existingItem.id,
        quantity: newQuantity,
      );
    }

    // Add new item
    return _repository.addToCart(
      userId: userId,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
    );
  }
}
