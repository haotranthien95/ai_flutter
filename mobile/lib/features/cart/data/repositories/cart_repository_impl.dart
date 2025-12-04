import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/storage/database/cart_local_data_source.dart';
import 'package:ai_flutter/features/cart/data/data_sources/cart_remote_data_source.dart';
import 'package:ai_flutter/features/cart/domain/repositories/cart_repository.dart';

/// Cart repository implementation with offline-first approach (T134).
class CartRepositoryImpl implements CartRepository {
  /// Creates cart repository.
  const CartRepositoryImpl(this._remoteDataSource, this._localDataSource);

  final CartRemoteDataSource _remoteDataSource;
  final CartLocalDataSource _localDataSource;

  @override
  Future<List<CartItem>> getCart(String userId) async {
    // Try to get from local first
    final localItemsData = await _localDataSource.getCartItems(userId);
    final localItems =
        localItemsData.map((data) => CartItem.fromJson(data)).toList();

    // Sync with server in background
    try {
      final remoteItems = await _remoteDataSource.getCart(userId);
      // Update local database with products loaded from server
      await _localDataSource.clearCart(userId);
      final productIds = remoteItems.map((item) => item.productId).toList();
      final products = await _remoteDataSource.getProducts(productIds);

      for (final item in remoteItems) {
        final product = products.firstWhere((p) => p.id == item.productId);
        await _localDataSource.insertCartItem(item, product);
      }
      return remoteItems;
    } catch (e) {
      // If sync fails, return local items
      return localItems;
    }
  }

  @override
  Future<List<Product>> getProductsForCart(List<String> productIds) async {
    return _remoteDataSource.getProducts(productIds);
  }

  @override
  Future<CartItem> addToCart({
    required String userId,
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    // Load product data for offline storage
    final products = await _remoteDataSource.getProducts([productId]);
    if (products.isEmpty) {
      throw Exception('Product not found');
    }
    final product = products.first;

    // Add to local first
    final cartItem = CartItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      productId: productId,
      variantId: variantId,
      quantity: quantity,
      addedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _localDataSource.insertCartItem(cartItem, product);

    // Sync with server
    try {
      final remoteItem = await _remoteDataSource.addToCart(
        productId: productId,
        variantId: variantId,
        quantity: quantity,
      );

      // Update local with server ID
      await _localDataSource.deleteCartItem(cartItem.id);
      await _localDataSource.insertCartItem(remoteItem, product);

      return remoteItem;
    } catch (e) {
      // Return local item if server sync fails
      return cartItem;
    }
  }

  @override
  Future<CartItem> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    // Update local first
    await _localDataSource.updateQuantity(cartItemId, quantity);

    // Sync with server
    try {
      final remoteItem = await _remoteDataSource.updateQuantity(
        cartItemId: cartItemId,
        quantity: quantity,
      );

      // Update local with server data - need to reload product
      final products =
          await _remoteDataSource.getProducts([remoteItem.productId]);
      if (products.isNotEmpty) {
        await _localDataSource.deleteCartItem(cartItemId);
        await _localDataSource.insertCartItem(remoteItem, products.first);
      }

      return remoteItem;
    } catch (e) {
      // If server fails, return updated local item
      final localItemData = await _localDataSource.getCartItemById(cartItemId);
      if (localItemData == null) {
        throw Exception('Cart item not found');
      }
      return CartItem.fromJson(localItemData);
    }
  }

  @override
  Future<void> removeCartItem(String cartItemId) async {
    // Remove from local first
    await _localDataSource.deleteCartItem(cartItemId);

    // Sync with server
    try {
      await _remoteDataSource.removeItem(cartItemId);
    } catch (e) {
      // Ignore server errors for removal
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    await _localDataSource.clearCart(userId);
  }

  @override
  Future<void> syncCart(String userId, List<CartItem> localItems) async {
    try {
      final remoteItems = await _remoteDataSource.syncCart(localItems);

      // Update local database with server state - need products
      await _localDataSource.clearCart(userId);
      final productIds = remoteItems.map((item) => item.productId).toList();
      final products = await _remoteDataSource.getProducts(productIds);

      for (final item in remoteItems) {
        final product = products.firstWhere((p) => p.id == item.productId);
        await _localDataSource.insertCartItem(item, product);
      }
    } catch (e) {
      // Sync will be retried later
      rethrow;
    }
  }
}
