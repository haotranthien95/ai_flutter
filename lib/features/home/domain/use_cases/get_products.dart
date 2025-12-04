import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/core/models/product.dart';

/// Use case for fetching paginated product list
///
/// Encapsulates business logic for retrieving products with
/// filtering, sorting, and pagination support.
class GetProductsUseCase {
  final ProductRepository _repository;

  GetProductsUseCase(this._repository);

  /// Executes the use case to fetch products
  ///
  /// Parameters:
  /// - [limit]: Maximum number of products to fetch (default: 20, max: 100)
  /// - [cursor]: Pagination cursor for fetching next page
  /// - [categoryId]: Optional filter by category ID
  /// - [filters]: Optional filters map containing:
  ///   * minPrice: Minimum price filter (VND)
  ///   * maxPrice: Maximum price filter (VND)
  ///   * rating: Minimum rating filter (1-5 stars)
  ///   * condition: Product condition ('new', 'used', 'refurbished')
  /// - [sortBy]: Optional sorting:
  ///   * 'relevance' (default)
  ///   * 'newest'
  ///   * 'best_selling'
  ///   * 'price_low_high'
  ///   * 'price_high_low'
  ///   * 'top_rated'
  ///
  /// Returns list of products matching the criteria
  ///
  /// Throws:
  /// - [ArgumentError] if limit is invalid
  /// - [NetworkException] on network errors
  /// - [ServerException] on server errors
  Future<List<Product>> execute({
    int limit = 20,
    String? cursor,
    String? categoryId,
    Map<String, dynamic>? filters,
    String? sortBy,
  }) async {
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

    // Fetch products from repository
    return await _repository.getProducts(
      limit: limit,
      cursor: cursor,
      categoryId: categoryId,
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
