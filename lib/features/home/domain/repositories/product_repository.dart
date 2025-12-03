import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/category.dart';
import 'package:ai_flutter/core/models/product_variant.dart';
import 'package:ai_flutter/core/models/review.dart';

/// Repository interface for product-related operations
///
/// This interface defines the contract for accessing product data,
/// following the Repository pattern in Clean Architecture.
abstract class ProductRepository {
  /// Fetches a paginated list of products
  ///
  /// Parameters:
  /// - [limit]: Maximum number of products to fetch (default: 20)
  /// - [cursor]: Pagination cursor for fetching next page
  /// - [categoryId]: Optional filter by category
  /// - [filters]: Optional filters (price range, rating, condition, etc.)
  /// - [sortBy]: Optional sorting (relevance, newest, best_selling, price_low_high, price_high_low, top_rated)
  ///
  /// Returns list of products matching the criteria
  /// Throws [NetworkException] on network errors
  /// Throws [ServerException] on server errors
  Future<List<Product>> getProducts({
    int limit = 20,
    String? cursor,
    String? categoryId,
    Map<String, dynamic>? filters,
    String? sortBy,
  });

  /// Searches products by keyword
  ///
  /// Parameters:
  /// - [query]: Search keyword (required, min 1 character)
  /// - [limit]: Maximum number of results (default: 20)
  /// - [cursor]: Pagination cursor
  /// - [filters]: Optional filters
  /// - [sortBy]: Optional sorting
  ///
  /// Returns list of products matching the search query
  Future<List<Product>> searchProducts({
    required String query,
    int limit = 20,
    String? cursor,
    Map<String, dynamic>? filters,
    String? sortBy,
  });

  /// Fetches detailed information for a specific product
  ///
  /// Parameters:
  /// - [productId]: The ID of the product to fetch
  ///
  /// Returns the complete product details
  /// Throws [NotFoundException] if product doesn't exist
  Future<Product> getProductDetail(String productId);

  /// Fetches all variants for a specific product
  ///
  /// Parameters:
  /// - [productId]: The ID of the product
  ///
  /// Returns list of product variants (empty if product has no variants)
  Future<List<ProductVariant>> getProductVariants(String productId);

  /// Fetches reviews for a specific product
  ///
  /// Parameters:
  /// - [productId]: The ID of the product
  /// - [limit]: Maximum number of reviews to fetch
  /// - [cursor]: Pagination cursor
  /// - [rating]: Optional filter by rating (1-5 stars)
  ///
  /// Returns list of reviews for the product
  Future<List<Review>> getProductReviews({
    required String productId,
    int limit = 20,
    String? cursor,
    int? rating,
  });

  /// Fetches all categories (root and subcategories)
  ///
  /// Returns hierarchical list of categories
  /// Root categories have parentId == null
  /// Subcategories have parentId pointing to parent
  Future<List<Category>> getCategories();

  /// Fetches autocomplete suggestions for search
  ///
  /// Parameters:
  /// - [query]: Partial search query
  /// - [limit]: Maximum number of suggestions (default: 5)
  ///
  /// Returns list of suggested search terms
  Future<List<String>> getSearchSuggestions({
    required String query,
    int limit = 5,
  });
}
