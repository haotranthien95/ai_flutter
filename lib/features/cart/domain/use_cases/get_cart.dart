import 'package:ai_flutter/features/cart/domain/models/cart.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';

/// Use case for getting user's cart (T142).
class GetCartUseCase {
  /// Creates get cart use case.
  const GetCartUseCase(this._repository);

  final CartRepository _repository;

  /// Execute get cart.
  ///
  /// Fetches cart items, groups by shop, and calculates totals.
  Future<Cart> execute(String userId) async {
    // Get cart items
    final cartItems = await _repository.getCart(userId);

    if (cartItems.isEmpty) {
      return const Cart(
        items: [],
        products: [],
        shopGroups: {},
        itemCount: 0,
        totalAmount: 0,
      );
    }

    // Get products for cart items
    final productIds = cartItems.map((item) => item.productId).toList();
    final products = await _repository.getProductsForCart(productIds);

    // Group items by shop
    final shopGroups = <String, List<CartItemWithProduct>>{};
    var totalAmount = 0.0;
    var itemCount = 0;

    for (final cartItem in cartItems) {
      final product = products.firstWhere(
        (p) => p.id == cartItem.productId,
        orElse: () => throw Exception('Product not found: ${cartItem.productId}'),
      );

      final itemWithProduct = CartItemWithProduct(
        cartItem: cartItem,
        product: product,
      );

      // Group by shop
      if (shopGroups.containsKey(product.shopId)) {
        shopGroups[product.shopId]!.add(itemWithProduct);
      } else {
        shopGroups[product.shopId] = [itemWithProduct];
      }

      // Calculate totals
      totalAmount += product.basePrice * cartItem.quantity;
      itemCount += cartItem.quantity;
    }

    return Cart(
      items: cartItems,
      products: products,
      shopGroups: shopGroups,
      itemCount: itemCount,
      totalAmount: totalAmount,
    );
  }
}
