import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/features/home/data/data_sources/product_remote_data_source.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/category.dart';
import 'package:ai_flutter/core/models/product_variant.dart';
import 'package:ai_flutter/core/models/review.dart';

/// Implementation of [ProductRepository] using remote API
///
/// Delegates all operations to [ProductRemoteDataSource] and handles
/// data transformation if needed.
class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource _remoteDataSource;

  ProductRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<Product>> getProducts({
    int limit = 20,
    String? cursor,
    String? categoryId,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
    return await _remoteDataSource.fetchProducts(
      limit: limit,
      cursor: cursor,
      categoryId: categoryId,
      filters: filters,
      sortBy: sortBy,
    );
  }

  @override
  Future<List<Product>> searchProducts({
    required String query,
    int limit = 20,
    String? cursor,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    return await _remoteDataSource.searchProducts(
      query: query,
      limit: limit,
      cursor: cursor,
      filters: filters,
      sortBy: sortBy,
    );
  }

  @override
  Future<Product> getProductDetail(String productId) async {
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    return await _remoteDataSource.fetchProductDetail(productId);
  }

  @override
  Future<List<ProductVariant>> getProductVariants(String productId) async {
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    return await _remoteDataSource.fetchProductVariants(productId);
  }

  @override
  Future<List<Review>> getProductReviews({
    required String productId,
    int limit = 20,
    String? cursor,
    int? rating,
  }) async {
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    return await _remoteDataSource.fetchProductReviews(
      productId: productId,
      limit: limit,
      cursor: cursor,
      rating: rating,
    );
  }

  @override
  Future<List<Category>> getCategories() async {
    return await _remoteDataSource.fetchCategories();
  }

  @override
  Future<List<String>> getSearchSuggestions({
    required String query,
    int limit = 5,
  }) async {
    if (query.isEmpty) {
      return [];
    }

    return await _remoteDataSource.fetchSearchSuggestions(
      query: query,
      limit: limit,
    );
  }
}
