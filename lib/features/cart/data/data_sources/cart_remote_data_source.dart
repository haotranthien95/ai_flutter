import 'package:dio/dio.dart';
import 'package:ai_flutter/core/models/cart_item.dart';
import 'package:ai_flutter/core/models/product.dart';

/// Remote data source for cart operations (T133).
class CartRemoteDataSource {
  /// Creates cart remote data source.
  const CartRemoteDataSource(this._dio);

  final Dio _dio;

  /// Get user's cart from server.
  Future<List<CartItem>> getCart(String userId) async {
    final response = await _dio.get('/cart');
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => CartItem.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Get products for cart items.
  Future<List<Product>> getProducts(List<String> productIds) async {
    if (productIds.isEmpty) return [];
    
    final response = await _dio.get(
      '/products',
      queryParameters: {
        'ids': productIds.join(','),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final products = data['items'] as List<dynamic>;
    return products.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Add item to cart.
  Future<CartItem> addToCart({
    required String productId,
    String? variantId,
    required int quantity,
  }) async {
    final response = await _dio.post(
      '/cart',
      data: {
        'productId': productId,
        if (variantId != null) 'variantId': variantId,
        'quantity': quantity,
      },
    );
    return CartItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// Update cart item quantity.
  Future<CartItem> updateQuantity({
    required String cartItemId,
    required int quantity,
  }) async {
    final response = await _dio.patch(
      '/cart/items/$cartItemId',
      data: {'quantity': quantity},
    );
    return CartItem.fromJson(response.data as Map<String, dynamic>);
  }

  /// Remove item from cart.
  Future<void> removeItem(String cartItemId) async {
    await _dio.delete('/cart/items/$cartItemId');
  }

  /// Sync local cart with server.
  Future<List<CartItem>> syncCart(List<CartItem> localItems) async {
    final response = await _dio.post(
      '/cart/sync',
      data: {
        'items': localItems.map((item) => item.toJson()).toList(),
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>;
    return items.map((json) => CartItem.fromJson(json as Map<String, dynamic>)).toList();
  }
}
