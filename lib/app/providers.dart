import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api/api_client.dart';
import '../core/storage/database/database_helper.dart';
import '../core/storage/local_storage.dart';
import '../core/storage/secure_storage.dart';
import '../features/home/data/data_sources/product_remote_data_source.dart';
import '../features/home/data/repositories/product_repository_impl.dart';
import '../features/home/domain/repositories/product_repository.dart';
import '../features/home/domain/use_cases/get_products.dart';
import '../features/home/domain/use_cases/get_categories.dart';
import '../features/home/domain/use_cases/search_products.dart';
import '../features/home/presentation/providers/home_provider.dart';
import '../features/search/presentation/providers/search_provider.dart';
import '../features/product_detail/domain/use_cases/get_product_detail.dart';
import '../features/product_detail/domain/use_cases/get_product_reviews.dart';
import '../features/product_detail/presentation/providers/product_detail_provider.dart';

/// Global providers for dependency injection.
///
/// These providers are available throughout the app via ProviderScope.

/// Dio provider (HTTP client).
final dioProvider = Provider<Dio>((ref) => Dio());

/// API client provider.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Local storage provider (SharedPreferences).
final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage();
});

/// Secure storage provider (FlutterSecureStorage).
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

/// Database helper provider (SQLite).
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

// ============================================================================
// Feature: Home / Product Discovery
// ============================================================================

/// Product remote data source provider.
final productRemoteDataSourceProvider =
    Provider<ProductRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProductRemoteDataSource(apiClient);
});

/// Product repository provider.
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final remoteDataSource = ref.watch(productRemoteDataSourceProvider);
  return ProductRepositoryImpl(remoteDataSource);
});

/// Get products use case provider.
final getProductsUseCaseProvider = Provider<GetProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductsUseCase(repository);
});

/// Get categories use case provider.
final getCategoriesUseCaseProvider = Provider<GetCategoriesUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetCategoriesUseCase(repository);
});

/// Search products use case provider.
final searchProductsUseCaseProvider = Provider<SearchProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return SearchProductsUseCase(repository);
});

/// Get product detail use case provider.
final getProductDetailUseCaseProvider =
    Provider<GetProductDetailUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductDetailUseCase(repository);
});

/// Get product reviews use case provider.
final getProductReviewsUseCaseProvider =
    Provider<GetProductReviewsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetProductReviewsUseCase(repository);
});

/// Home provider (overrides the stub in home_provider.dart).
final homeProviderOverride =
    StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final getProductsUseCase = ref.watch(getProductsUseCaseProvider);
  final getCategoriesUseCase = ref.watch(getCategoriesUseCaseProvider);
  return HomeNotifier(getProductsUseCase, getCategoriesUseCase);
});

/// Search provider (overrides the stub in search_provider.dart).
final searchProviderOverride =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final searchProductsUseCase = ref.watch(searchProductsUseCaseProvider);
  final productRepository = ref.watch(productRepositoryProvider);
  return SearchNotifier(searchProductsUseCase, productRepository);
});

/// Product detail provider (overrides the stub in product_detail_provider.dart).
final productDetailProviderOverride =
    StateNotifierProvider<ProductDetailNotifier, ProductDetailState>((ref) {
  final getProductDetailUseCase = ref.watch(getProductDetailUseCaseProvider);
  final getProductReviewsUseCase = ref.watch(getProductReviewsUseCaseProvider);
  return ProductDetailNotifier(
      getProductDetailUseCase, getProductReviewsUseCase);
});
