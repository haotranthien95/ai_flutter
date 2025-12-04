import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/core/models/review.dart';

/// Use case for fetching product reviews
///
/// Encapsulates business logic for retrieving and filtering
/// product reviews with pagination.
class GetProductReviewsUseCase {
  final ProductRepository _repository;

  GetProductReviewsUseCase(this._repository);

  /// Executes the use case to fetch product reviews
  ///
  /// Parameters:
  /// - [productId]: The ID of the product (required)
  /// - [limit]: Maximum number of reviews to fetch (default: 20, max: 100)
  /// - [cursor]: Pagination cursor for fetching next page
  /// - [rating]: Optional filter by rating (1-5 stars)
  ///
  /// Returns list of reviews for the product
  ///
  /// Throws:
  /// - [ArgumentError] if parameters are invalid
  /// - [NetworkException] on network errors
  /// - [ServerException] on server errors
  Future<List<Review>> execute({
    required String productId,
    int limit = 20,
    String? cursor,
    int? rating,
  }) async {
    // Validate productId
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    // Validate limit
    if (limit <= 0 || limit > 100) {
      throw ArgumentError('Limit must be between 1 and 100');
    }

    // Validate rating if provided
    if (rating != null && (rating < 1 || rating > 5)) {
      throw ArgumentError('Rating must be between 1 and 5');
    }

    // Fetch reviews from repository
    final reviews = await _repository.getProductReviews(
      productId: productId,
      limit: limit,
      cursor: cursor,
      rating: rating,
    );

    // Return only visible reviews
    return reviews.where((review) => review.isVisible).toList();
  }

  /// Fetches reviews with images only
  ///
  /// Useful for displaying a photo gallery of product reviews
  Future<List<Review>> getReviewsWithImages({
    required String productId,
    int limit = 20,
    String? cursor,
  }) async {
    final reviews = await execute(
      productId: productId,
      limit: limit,
      cursor: cursor,
    );

    return reviews.where((review) => review.hasImages).toList();
  }

  /// Fetches verified purchase reviews only
  ///
  /// More trustworthy reviews from actual buyers
  Future<List<Review>> getVerifiedReviews({
    required String productId,
    int limit = 20,
    String? cursor,
  }) async {
    final reviews = await execute(
      productId: productId,
      limit: limit,
      cursor: cursor,
    );

    return reviews.where((review) => review.isVerifiedPurchase).toList();
  }

  /// Fetches reviews sorted by helpfulness or date
  ///
  /// Note: Actual sorting is done on the backend via API
  /// This is a convenience method for common use cases
  Future<List<Review>> getTopReviews({
    required String productId,
    int limit = 5,
  }) async {
    // Fetch limited number of top reviews
    // Backend should return most helpful or highest rated first
    return await execute(
      productId: productId,
      limit: limit,
    );
  }

  /// Calculates review statistics
  ///
  /// Returns breakdown of review counts by rating
  Future<ReviewStatistics> getReviewStatistics({
    required String productId,
  }) async {
    // Fetch all reviews (may need pagination for large datasets)
    // For now, fetch first 100 to calculate statistics
    final reviews = await execute(
      productId: productId,
      limit: 100,
    );

    // Count reviews by rating
    final ratingCounts = <int, int>{
      5: 0,
      4: 0,
      3: 0,
      2: 0,
      1: 0,
    };

    double totalRating = 0;
    int withImagesCount = 0;
    int verifiedCount = 0;

    for (final review in reviews) {
      ratingCounts[review.rating] = (ratingCounts[review.rating] ?? 0) + 1;
      totalRating += review.rating;
      if (review.hasImages) withImagesCount++;
      if (review.isVerifiedPurchase) verifiedCount++;
    }

    final averageRating = reviews.isEmpty ? 0.0 : totalRating / reviews.length;

    return ReviewStatistics(
      totalReviews: reviews.length,
      averageRating: averageRating,
      ratingCounts: ratingCounts,
      reviewsWithImages: withImagesCount,
      verifiedPurchases: verifiedCount,
    );
  }
}

/// Data class for review statistics
class ReviewStatistics {
  final int totalReviews;
  final double averageRating;
  final Map<int, int> ratingCounts;
  final int reviewsWithImages;
  final int verifiedPurchases;

  ReviewStatistics({
    required this.totalReviews,
    required this.averageRating,
    required this.ratingCounts,
    required this.reviewsWithImages,
    required this.verifiedPurchases,
  });

  /// Returns percentage of reviews for each rating
  Map<int, double> get ratingPercentages {
    if (totalReviews == 0) {
      return {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    }

    return ratingCounts.map(
      (rating, count) => MapEntry(rating, (count / totalReviews) * 100),
    );
  }

  /// Returns percentage of verified purchases
  double get verifiedPercentage {
    if (totalReviews == 0) return 0;
    return (verifiedPurchases / totalReviews) * 100;
  }

  /// Returns percentage of reviews with images
  double get withImagesPercentage {
    if (totalReviews == 0) return 0;
    return (reviewsWithImages / totalReviews) * 100;
  }
}
