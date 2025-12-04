import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/product.dart';
import '../../../../core/models/product_variant.dart';
import '../../../../core/models/review.dart';
import '../../domain/use_cases/get_product_detail.dart';
import '../../domain/use_cases/get_product_reviews.dart';

/// Product detail screen state.
class ProductDetailState {
  const ProductDetailState({
    this.product,
    this.variants = const [],
    this.selectedVariant,
    this.reviews = const [],
    this.isLoading = false,
    this.isLoadingReviews = false,
    this.error,
  });

  final Product? product;
  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final List<Review> reviews;
  final bool isLoading;
  final bool isLoadingReviews;
  final String? error;

  ProductDetailState copyWith({
    Product? product,
    List<ProductVariant>? variants,
    ProductVariant? selectedVariant,
    List<Review>? reviews,
    bool? isLoading,
    bool? isLoadingReviews,
    String? error,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      variants: variants ?? this.variants,
      selectedVariant: selectedVariant ?? this.selectedVariant,
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isLoadingReviews: isLoadingReviews ?? this.isLoadingReviews,
      error: error,
    );
  }

  ProductDetailState clearError() {
    return ProductDetailState(
      product: product,
      variants: variants,
      selectedVariant: selectedVariant,
      reviews: reviews,
      isLoading: isLoading,
      isLoadingReviews: isLoadingReviews,
      error: null,
    );
  }

  /// Returns current price (variant price if selected, otherwise base price).
  num get currentPrice {
    if (selectedVariant != null) {
      return selectedVariant!.price;
    }
    return product?.basePrice ?? 0;
  }

  /// Returns current stock.
  int get currentStock {
    if (selectedVariant != null) {
      return selectedVariant!.stock;
    }
    return product?.totalStock ?? 0;
  }

  /// Checks if product/variant is in stock.
  bool get isInStock => currentStock > 0;

  /// Checks if product can be purchased.
  bool get canBePurchased {
    if (product == null || !product!.isActive) return false;
    if (variants.isEmpty) return isInStock;
    return selectedVariant != null && selectedVariant!.isActive && isInStock;
  }
}

/// Product detail provider.
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  ProductDetailNotifier(
    this._getProductDetailUseCase,
    this._getProductReviewsUseCase,
  ) : super(const ProductDetailState());

  final GetProductDetailUseCase _getProductDetailUseCase;
  final GetProductReviewsUseCase _getProductReviewsUseCase;

  /// Loads product detail with variants and reviews.
  Future<void> loadProductDetail(String productId) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final productWithVariants =
          await _getProductDetailUseCase.executeWithVariants(productId);

      state = state.copyWith(
        product: productWithVariants.product,
        variants: productWithVariants.variants,
        selectedVariant: productWithVariants.availableVariants.isNotEmpty
            ? productWithVariants.availableVariants.first
            : null,
        isLoading: false,
      );

      // Load reviews in parallel
      loadReviews(productId);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatError(e),
      );
    }
  }

  /// Loads product reviews.
  Future<void> loadReviews(String productId) async {
    state = state.copyWith(isLoadingReviews: true);

    try {
      final reviews = await _getProductReviewsUseCase.execute(
        productId: productId,
        limit: 5, // Show first 5 reviews
      );

      state = state.copyWith(
        reviews: reviews,
        isLoadingReviews: false,
      );
    } catch (e) {
      // Reviews are optional, don't block UI
      state = state.copyWith(
        isLoadingReviews: false,
        reviews: [],
      );
    }
  }

  /// Selects a product variant.
  void selectVariant(ProductVariant variant) {
    if (state.variants.contains(variant)) {
      state = state.copyWith(selectedVariant: variant);
    }
  }

  /// Selects variant by ID.
  void selectVariantById(String variantId) {
    final variant = state.variants.firstWhere(
      (v) => v.id == variantId,
      orElse: () => state.variants.first,
    );
    selectVariant(variant);
  }

  /// Retries loading product after error.
  void retry(String productId) {
    loadProductDetail(productId);
  }

  /// Resets state (for cleanup).
  void reset() {
    state = const ProductDetailState();
  }

  /// Formats error message for display.
  String _formatError(Object error) {
    if (error is ArgumentError) {
      return error.message.toString();
    }
    return 'Không thể tải thông tin sản phẩm. Vui lòng thử lại.';
  }
}

/// Provider for product detail screen state.
///
/// This is a stub that will be overridden in app/providers.dart with proper dependencies.
final productDetailProvider =
    StateNotifierProvider<ProductDetailNotifier, ProductDetailState>((ref) {
  throw UnimplementedError(
    'productDetailProvider must be overridden with productDetailProviderOverride from app/providers.dart',
  );
});
