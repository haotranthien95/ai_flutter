import 'package:ai_flutter/core/api/api_client.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/category.dart';
import 'package:ai_flutter/core/models/product_variant.dart';
import 'package:ai_flutter/core/models/review.dart';

/// Remote data source for product-related API calls
///
/// Handles all HTTP requests related to products, categories, and search.
/// Uses [ApiClient] for making network requests.
class ProductRemoteDataSource {
  final ApiClient _apiClient;

  ProductRemoteDataSource(this._apiClient);

  /// Fetches products from GET /products endpoint
  ///
  /// Query parameters:
  /// - limit: number of items per page
  /// - cursor: pagination cursor
  /// - category_id: filter by category
  /// - min_price, max_price: price range filter
  /// - rating: minimum rating filter
  /// - condition: product condition filter
  /// - sort_by: sorting option
  Future<List<Product>> fetchProducts({
    int limit = 20,
    String? cursor,
    String? categoryId,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (categoryId != null) 'category_id': categoryId,
      if (sortBy != null) 'sort_by': sortBy,
    };

    // Add filters to query params
    if (filters != null) {
      if (filters.containsKey('minPrice')) {
        queryParams['min_price'] = filters['minPrice'];
      }
      if (filters.containsKey('maxPrice')) {
        queryParams['max_price'] = filters['maxPrice'];
      }
      if (filters.containsKey('rating')) {
        queryParams['rating'] = filters['rating'];
      }
      if (filters.containsKey('condition')) {
        queryParams['condition'] = filters['condition'];
      }
    }

    final response = await _apiClient.get(
      '/products',
      queryParameters: queryParams,
    );

    final List<dynamic> productsJson = response.data['data'] as List<dynamic>;
    return productsJson
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Searches products from GET /products/search endpoint
  Future<List<Product>> searchProducts({
    required String query,
    int limit = 20,
    String? cursor,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
    final queryParams = <String, dynamic>{
      'q': query,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (sortBy != null) 'sort_by': sortBy,
    };

    // Add filters
    if (filters != null) {
      if (filters.containsKey('minPrice')) {
        queryParams['min_price'] = filters['minPrice'];
      }
      if (filters.containsKey('maxPrice')) {
        queryParams['max_price'] = filters['maxPrice'];
      }
      if (filters.containsKey('rating')) {
        queryParams['rating'] = filters['rating'];
      }
      if (filters.containsKey('condition')) {
        queryParams['condition'] = filters['condition'];
      }
    }

    final response = await _apiClient.get(
      '/products/search',
      queryParameters: queryParams,
    );

    final List<dynamic> productsJson = response.data['data'] as List<dynamic>;
    return productsJson
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches product detail from GET /products/{id} endpoint
  Future<Product> fetchProductDetail(String productId) async {
    final response = await _apiClient.get('/products/$productId');
    return Product.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Fetches product variants from GET /products/{id}/variants endpoint
  Future<List<ProductVariant>> fetchProductVariants(String productId) async {
    final response = await _apiClient.get('/products/$productId/variants');
    final List<dynamic> variantsJson = response.data['data'] as List<dynamic>;
    return variantsJson
        .map((json) => ProductVariant.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches product reviews from GET /products/{id}/reviews endpoint
  Future<List<Review>> fetchProductReviews({
    required String productId,
    int limit = 20,
    String? cursor,
    int? rating,
  }) async {
    final queryParams = <String, dynamic>{
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
      if (rating != null) 'rating': rating,
    };

    final response = await _apiClient.get(
      '/products/$productId/reviews',
      queryParameters: queryParams,
    );

    final List<dynamic> reviewsJson = response.data['data'] as List<dynamic>;
    return reviewsJson
        .map((json) => Review.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches categories from GET /categories endpoint
  Future<List<Category>> fetchCategories() async {
    final response = await _apiClient.get('/categories');
    final List<dynamic> categoriesJson = response.data['data'] as List<dynamic>;
    return categoriesJson
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches search autocomplete suggestions from GET /products/search/autocomplete endpoint
  Future<List<String>> fetchSearchSuggestions({
    required String query,
    int limit = 5,
  }) async {
    final response = await _apiClient.get(
      '/products/search/autocomplete',
      queryParameters: {
        'q': query,
        'limit': limit,
      },
    );

    final List<dynamic> suggestions = response.data['data'] as List<dynamic>;
    return suggestions.cast<String>();
  }
}
