import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/features/auth/presentation/providers/auth_provider.dart';
import 'package:ai_flutter/features/cart/domain/models/cart.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/add_to_cart.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/get_cart.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/remove_cart_item.dart';
import 'package:ai_flutter/features/cart/domain/use_cases/update_cart_item_quantity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Cart state notifier (T148).
class CartNotifier extends StateNotifier<AsyncValue<Cart>> {
  /// Creates cart notifier.
  CartNotifier(
    this._getCartUseCase,
    this._addToCartUseCase,
    this._updateQuantityUseCase,
    this._removeItemUseCase,
    this._authNotifier,
  ) : super(const AsyncValue.loading()) {
    loadCart();
  }

  final GetCartUseCase _getCartUseCase;
  final AddToCartUseCase _addToCartUseCase;
  final UpdateCartItemQuantityUseCase _updateQuantityUseCase;
  final RemoveCartItemUseCase _removeItemUseCase;
  final AuthNotifier _authNotifier;

  /// Loads cart for current user.
  Future<void> loadCart() async {
    final authState = _authNotifier.state;
    final user = authState.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    if (user == null) {
      state = const AsyncValue.data(Cart(
        items: [],
        products: [],
        shopGroups: {},
        itemCount: 0,
        totalAmount: 0,
      ));
      return;
    }

    state = const AsyncValue.loading();
    try {
      final cart = await _getCartUseCase.execute(user.id);
      state = AsyncValue.data(cart);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Adds product to cart with optimistic update.
  Future<void> addToCart({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    final authState = _authNotifier.state;
    final user = authState.maybeWhen(
      authenticated: (user) => user,
      orElse: () => null,
    );
    if (user == null) throw Exception('User not authenticated');

    try {
      await _addToCartUseCase.execute(
        userId: user.id,
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );

      // Reload cart to get updated state
      await loadCart();
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  /// Updates cart item quantity with optimistic update.
  Future<void> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    // Optimistic update
    state.whenData((cart) {
      final updatedItems = cart.items.map((item) {
        if (item.id == cartItemId) {
          return CartItem(
            id: item.id,
            userId: item.userId,
            productId: item.productId,
            variantId: item.variantId,
            quantity: quantity,
            addedAt: item.addedAt,
            updatedAt: DateTime.now(),
          );
        }
        return item;
      }).toList();

      // Recalculate cart with updated items
      final shopGroups = <String, List<CartItemWithProduct>>{};
      var itemCount = 0;
      var totalAmount = 0.0;

      for (final item in updatedItems) {
        final product = cart.products.firstWhere((p) => p.id == item.productId);
        final cartItemWithProduct = CartItemWithProduct(
          cartItem: item,
          product: product,
        );

        final shopId = product.shopId;
        shopGroups.putIfAbsent(shopId, () => []).add(cartItemWithProduct);
        itemCount += item.quantity;
        totalAmount += product.basePrice * item.quantity;
      }

      state = AsyncValue.data(Cart(
        items: updatedItems,
        products: cart.products,
        shopGroups: shopGroups,
        itemCount: itemCount,
        totalAmount: totalAmount,
      ));
    });

    try {
      await _updateQuantityUseCase.execute(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      // Reload to get server state
      await loadCart();
    } catch (error) {
      // Revert on error
      await loadCart();
      rethrow;
    }
  }

  /// Removes item from cart with optimistic update.
  Future<void> removeItem(String cartItemId) async {
    // Optimistic update
    state.whenData((cart) {
      final updatedItems =
          cart.items.where((item) => item.id != cartItemId).toList();

      // Recalculate cart
      final shopGroups = <String, List<CartItemWithProduct>>{};
      var itemCount = 0;
      var totalAmount = 0.0;

      for (final item in updatedItems) {
        final product = cart.products.firstWhere((p) => p.id == item.productId);
        final cartItemWithProduct = CartItemWithProduct(
          cartItem: item,
          product: product,
        );

        final shopId = product.shopId;
        shopGroups.putIfAbsent(shopId, () => []).add(cartItemWithProduct);
        itemCount += item.quantity;
        totalAmount += product.basePrice * item.quantity;
      }

      state = AsyncValue.data(Cart(
        items: updatedItems,
        products: cart.products,
        shopGroups: shopGroups,
        itemCount: itemCount,
        totalAmount: totalAmount,
      ));
    });

    try {
      await _removeItemUseCase.execute(cartItemId);

      // Reload to confirm server state
      await loadCart();
    } catch (error) {
      // Revert on error
      await loadCart();
      rethrow;
    }
  }

  /// Gets item count for badge display.
  int get itemCount {
    return state.maybeWhen(
      data: (cart) => cart.itemCount,
      orElse: () => 0,
    );
  }
}

/// Cart provider (T148).
final cartProvider =
    StateNotifierProvider<CartNotifier, AsyncValue<Cart>>((ref) {
  final getCartUseCase = ref.watch(getCartUseCaseProvider);
  final addToCartUseCase = ref.watch(addToCartUseCaseProvider);
  final updateQuantityUseCase =
      ref.watch(updateCartItemQuantityUseCaseProvider);
  final removeItemUseCase = ref.watch(removeCartItemUseCaseProvider);
  final authNotifier = ref.watch(authProvider.notifier);

  return CartNotifier(
    getCartUseCase,
    addToCartUseCase,
    updateQuantityUseCase,
    removeItemUseCase,
    authNotifier,
  );
});

/// Use case providers (need to be defined in app/providers.dart).
final getCartUseCaseProvider = Provider<GetCartUseCase>((ref) {
  throw UnimplementedError('Define in app/providers.dart');
});

final addToCartUseCaseProvider = Provider<AddToCartUseCase>((ref) {
  throw UnimplementedError('Define in app/providers.dart');
});

final updateCartItemQuantityUseCaseProvider =
    Provider<UpdateCartItemQuantityUseCase>((ref) {
  throw UnimplementedError('Define in app/providers.dart');
});

final removeCartItemUseCaseProvider = Provider<RemoveCartItemUseCase>((ref) {
  throw UnimplementedError('Define in app/providers.dart');
});
