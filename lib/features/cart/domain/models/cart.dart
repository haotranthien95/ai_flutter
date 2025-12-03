import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/product.dart';

/// Cart model representing user's shopping cart with grouped items.
class Cart {
  /// Creates a cart instance.
  const Cart({
    required this.items,
    required this.products,
    required this.shopGroups,
    required this.itemCount,
    required this.totalAmount,
  });

  /// List of cart items.
  final List<CartItem> items;

  /// Products associated with cart items.
  final List<Product> products;

  /// Cart items grouped by shop ID.
  final Map<String, List<CartItemWithProduct>> shopGroups;

  /// Total number of items (sum of quantities).
  final int itemCount;

  /// Grand total amount (sum of all item prices × quantities).
  final double totalAmount;

  /// Check if cart is empty.
  bool get isEmpty => items.isEmpty;

  /// Check if cart has items.
  bool get isNotEmpty => items.isNotEmpty;

  /// Get subtotal for specific shop.
  double getShopSubtotal(String shopId) {
    final shopItems = shopGroups[shopId] ?? [];
    return shopItems.fold(
      0,
      (sum, item) => sum + (item.product.currentPrice * item.cartItem.quantity),
    );
  }
}

/// Cart item with associated product information.
class CartItemWithProduct {
  /// Creates a cart item with product instance.
  const CartItemWithProduct({
    required this.cartItem,
    required this.product,
  });

  /// Cart item.
  final CartItem cartItem;

  /// Associated product.
  final Product product;

  /// Get total price for this item (price × quantity).
  double get totalPrice => product.currentPrice * cartItem.quantity;

  /// Check if item is available (product active and has stock).
  bool get isAvailable => product.isActive && product.stockQuantity > 0;

  /// Check if quantity exceeds stock.
  bool get exceedsStock => cartItem.quantity > product.stockQuantity;
}
