import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/product.dart';

/// Repository interface for cart operations.
abstract class CartRepository {
  /// Get all cart items for a user.
  Future<List<CartItem>> getCart(String userId);

  /// Get products for cart items.
  Future<List<Product>> getProductsForCart(List<String> productIds);

  /// Add item to cart.
  Future<CartItem> addToCart({
    required String userId,
    required String productId,
    String? variantId,
    required int quantity,
  });

  /// Update cart item quantity.
  Future<CartItem> updateQuantity({
    required String cartItemId,
    required int quantity,
  });

  /// Remove item from cart.
  Future<void> removeCartItem(String cartItemId);

  /// Clear all cart items for a user.
  Future<void> clearCart(String userId);

  /// Sync cart with server.
  Future<void> syncCart(String userId, List<CartItem> localItems);
}
