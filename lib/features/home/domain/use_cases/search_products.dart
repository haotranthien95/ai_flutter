import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/core/models/product.dart';

/// Use case for searching products by keyword
///
/// Encapsulates business logic for product search with
/// filtering, sorting, and pagination support.
class SearchProductsUseCase {
  final ProductRepository _repository;

  SearchProductsUseCase(this._repository);

  /// Executes the use case to search products
  ///
  /// Parameters:
  /// - [query]: Search keyword (required, min 1 character)
  /// - [limit]: Maximum number of results (default: 20, max: 100)
  /// - [cursor]: Pagination cursor for fetching next page
  /// - [filters]: Optional filters (same as GetProductsUseCase)
  /// - [sortBy]: Optional sorting (same as GetProductsUseCase)
  ///
  /// Returns list of products matching the search query
  ///
  /// Throws:
  /// - [ArgumentError] if query is empty or parameters invalid
  /// - [NetworkException] on network errors
  /// - [ServerException] on server errors
  Future<List<Product>> execute({
    required String query,
    int limit = 20,
    String? cursor,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
    // Validate query
    if (query.isEmpty) {
      throw ArgumentError('Search query cannot be empty');
    }

    // Trim and validate minimum length
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      throw ArgumentError('Search query cannot be only whitespace');
    }

    // Validate limit
    if (limit <= 0 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }

    // Validate filters if provided
    if (filters != null) {
      _validateFilters(filters);
    }

    // Validate sortBy if provided
    if (sortBy != null) {
      _validateSortBy(sortBy);
    }

    // Search products from repository
    return await _repository.searchProducts(
      query: trimmedQuery,
      limit: limit,
      cursor: cursor,
      filters: filters,
      sortBy: sortBy,
    );
  }

  /// Validates filter parameters
  void _validateFilters(Map<String, dynamic> filters) {
    // Validate price range
    if (filters.containsKey('minPrice')) {
      final minPrice = filters['minPrice'];
      if (minPrice is! num || minPrice < 0) {
        throw ArgumentError('minPrice must be a non-negative number');
      }
    }

    if (filters.containsKey('maxPrice')) {
      final maxPrice = filters['maxPrice'];
      if (maxPrice is! num || maxPrice < 0) {
        throw ArgumentError('maxPrice must be a non-negative number');
      }
    }

    // Ensure minPrice <= maxPrice
    if (filters.containsKey('minPrice') && filters.containsKey('maxPrice')) {
      final minPrice = filters['minPrice'] as num;
      final maxPrice = filters['maxPrice'] as num;
      if (minPrice > maxPrice) {
        throw ArgumentError('minPrice cannot be greater than maxPrice');
      }
    }

    // Validate rating
    if (filters.containsKey('rating')) {
      final rating = filters['rating'];
      if (rating is! num || rating < 1 || rating > 5) {
        throw ArgumentError('rating must be between 1 and 5');
      }
    }

    // Validate condition
    if (filters.containsKey('condition')) {
      final condition = filters['condition'];
      const validConditions = ['new', 'used', 'refurbished'];
      if (condition is! String || !validConditions.contains(condition)) {
        throw ArgumentError(
            'condition must be one of: ${validConditions.join(", ")}');
      }
    }
  }

  /// Validates sort parameter
  void _validateSortBy(String sortBy) {
    const validSortOptions = [
      'relevance',
      'newest',
      'best_selling',
      'price_low_high',
      'price_high_low',
      'top_rated',
    ];

    if (!validSortOptions.contains(sortBy)) {
      throw ArgumentError(
          'sortBy must be one of: ${validSortOptions.join(", ")}');
    }
  }
}
