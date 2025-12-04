import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../models/cart_item.dart';
import '../../models/product.dart';
import 'database_helper.dart';

/// Local data source for cart operations using SQLite.
///
/// Provides offline cart persistence so users can add items to cart
/// even without internet connection. Cart is synced with server when online.
class CartLocalDataSource {
  /// Creates a cart local data source.
  ///
  /// [databaseHelper] is optional for testing.
  CartLocalDataSource({DatabaseHelper? databaseHelper})
      : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _databaseHelper;

  /// Insert a cart item into local database.
  ///
  /// [cartItem] is the item to insert.
  /// [product] is the full product data for offline display.
  /// Returns the row ID if successful.
  Future<int> insertCartItem(CartItem cartItem, Product product) async {
    final Database db = await _databaseHelper.database;

    final Map<String, dynamic> row = <String, dynamic>{
      'id': cartItem.id,
      'user_id': cartItem.userId,
      'product_id': cartItem.productId,
      'variant_id': cartItem.variantId,
      'quantity': cartItem.quantity,
      'added_at': cartItem.addedAt.toIso8601String(),
      'updated_at': cartItem.updatedAt.toIso8601String(),
      'product_data': jsonEncode(product.toJson()),
    };

    return db.insert(
      DatabaseHelper.cartItemsTable,
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all cart items for a user.
  ///
  /// Returns a list of cart items with embedded product data.
  Future<List<Map<String, dynamic>>> getCartItems(String userId) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
      DatabaseHelper.cartItemsTable,
      where: 'user_id = ?',
      whereArgs: <String>[userId],
      orderBy: 'added_at DESC',
    );

    // Parse product_data JSON for each item
    return results.map((Map<String, dynamic> row) {
      final Map<String, dynamic> cartItemData = Map<String, dynamic>.from(row);
      cartItemData['product'] = jsonDecode(row['product_data'] as String);
      cartItemData.remove('product_data'); // Remove raw JSON
      return cartItemData;
    }).toList();
  }

  /// Get a specific cart item by ID.
  ///
  /// Returns null if not found.
  Future<Map<String, dynamic>?> getCartItemById(String id) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
      DatabaseHelper.cartItemsTable,
      where: 'id = ?',
      whereArgs: <String>[id],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final Map<String, dynamic> row = results.first;
    final Map<String, dynamic> cartItemData = Map<String, dynamic>.from(row);
    cartItemData['product'] = jsonDecode(row['product_data'] as String);
    cartItemData.remove('product_data');
    return cartItemData;
  }

  /// Update cart item quantity.
  ///
  /// Returns the number of rows affected (should be 1).
  Future<int> updateQuantity(String id, int newQuantity) async {
    final Database db = await _databaseHelper.database;

    return db.update(
      DatabaseHelper.cartItemsTable,
      <String, dynamic>{
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: <String>[id],
    );
  }

  /// Delete a cart item by ID.
  ///
  /// Returns the number of rows affected (should be 1).
  Future<int> deleteCartItem(String id) async {
    final Database db = await _databaseHelper.database;

    return db.delete(
      DatabaseHelper.cartItemsTable,
      where: 'id = ?',
      whereArgs: <String>[id],
    );
  }

  /// Delete all cart items for a user.
  ///
  /// Useful for logout or after successful order placement.
  /// Returns the number of rows affected.
  Future<int> clearCart(String userId) async {
    final Database db = await _databaseHelper.database;

    return db.delete(
      DatabaseHelper.cartItemsTable,
      where: 'user_id = ?',
      whereArgs: <String>[userId],
    );
  }

  /// Get the total number of items in cart for a user.
  Future<int> getCartItemCount(String userId) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM ${DatabaseHelper.cartItemsTable} WHERE user_id = ?',
      <String>[userId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Check if a product/variant combination exists in cart.
  Future<bool> isInCart({
    required String userId,
    required String productId,
    String? variantId,
  }) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
      DatabaseHelper.cartItemsTable,
      where: variantId != null
          ? 'user_id = ? AND product_id = ? AND variant_id = ?'
          : 'user_id = ? AND product_id = ? AND variant_id IS NULL',
      whereArgs: variantId != null
          ? <String>[userId, productId, variantId]
          : <String>[userId, productId],
      limit: 1,
    );

    return results.isNotEmpty;
  }

  /// Get cart item by product and variant.
  ///
  /// Returns null if not found.
  Future<Map<String, dynamic>?> getCartItemByProduct({
    required String userId,
    required String productId,
    String? variantId,
  }) async {
    final Database db = await _databaseHelper.database;

    final List<Map<String, dynamic>> results = await db.query(
      DatabaseHelper.cartItemsTable,
      where: variantId != null
          ? 'user_id = ? AND product_id = ? AND variant_id = ?'
          : 'user_id = ? AND product_id = ? AND variant_id IS NULL',
      whereArgs: variantId != null
          ? <String>[userId, productId, variantId]
          : <String>[userId, productId],
      limit: 1,
    );

    if (results.isEmpty) return null;

    final Map<String, dynamic> row = results.first;
    final Map<String, dynamic> cartItemData = Map<String, dynamic>.from(row);
    cartItemData['product'] = jsonDecode(row['product_data'] as String);
    cartItemData.remove('product_data');
    return cartItemData;
  }
}
