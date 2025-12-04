import 'package:ai_flutter/features/home/domain/repositories/product_repository.dart';
import 'package:ai_flutter/core/models/product.dart';
import 'package:ai_flutter/core/models/product_variant.dart';

/// Use case for fetching detailed product information
///
/// Encapsulates business logic for retrieving complete product
/// details including variants.
class GetProductDetailUseCase {
  final ProductRepository _repository;

  GetProductDetailUseCase(this._repository);

  /// Executes the use case to fetch product detail
  ///
  /// Parameters:
  /// - [productId]: The ID of the product to fetch (required)
  ///
  /// Returns complete product information
  ///
  /// Throws:
  /// - [ArgumentError] if productId is empty
  /// - [NotFoundException] if product doesn't exist
  /// - [NetworkException] on network errors
  /// - [ServerException] on server errors
  Future<Product> execute(String productId) async {
    // Validate productId
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    // Fetch product detail from repository
    final product = await _repository.getProductDetail(productId);

    // Additional business logic validation
    // Note: We return inactive products but the UI can decide how to display them

    return product;
  }

  /// Fetches product with its variants
  ///
  /// Returns a tuple-like structure with product and variants
  Future<ProductWithVariants> executeWithVariants(String productId) async {
    if (productId.isEmpty) {
      throw ArgumentError('Product ID cannot be empty');
    }

    // Fetch product and variants in parallel
    final results = await Future.wait([
      _repository.getProductDetail(productId),
      _repository.getProductVariants(productId),
    ]);

    final product = results[0] as Product;
    final variants = results[1] as List<ProductVariant>;

    return ProductWithVariants(
      product: product,
      variants: variants,
    );
  }

  /// Validates if product can be purchased
  ///
  /// Business rules:
  /// - Product must be active
  /// - Product must have stock > 0
  /// - If variants exist, at least one variant must have stock > 0
  Future<bool> canBePurchased(String productId) async {
    final productWithVariants = await executeWithVariants(productId);
    final product = productWithVariants.product;
    final variants = productWithVariants.variants;

    // Check if product is active
    if (!product.isActive) {
      return false;
    }

    // If product has variants, check if any variant has stock
    if (variants.isNotEmpty) {
      return variants.any((variant) => variant.isInStock && variant.isActive);
    }

    // If no variants, check product stock directly
    return product.isInStock;
  }
}

/// Data class to hold product with its variants
class ProductWithVariants {
  final Product product;
  final List<ProductVariant> variants;

  ProductWithVariants({
    required this.product,
    required this.variants,
  });

  /// Returns active variants only
  List<ProductVariant> get activeVariants =>
      variants.where((v) => v.isActive).toList();

  /// Returns in-stock variants only
  List<ProductVariant> get inStockVariants =>
      variants.where((v) => v.isInStock).toList();

  /// Returns variants that are both active and in stock
  List<ProductVariant> get availableVariants =>
      variants.where((v) => v.isActive && v.isInStock).toList();

  /// Checks if product has any variants
  bool get hasVariants => variants.isNotEmpty;

  /// Checks if product has any available variants
  bool get hasAvailableVariants => availableVariants.isNotEmpty;
}
