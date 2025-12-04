import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/api/api_client.dart';
import '../core/storage/database/database_helper.dart';
import '../core/storage/database/cart_local_data_source.dart';
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
import '../features/auth/data/data_sources/auth_remote_data_source.dart';
import '../features/auth/data/repositories/auth_repository_impl.dart';
import '../features/auth/domain/repositories/auth_repository.dart';
import '../features/auth/domain/use_cases/register.dart';
import '../features/auth/domain/use_cases/verify_otp.dart';
import '../features/auth/domain/use_cases/login.dart';
import '../features/auth/domain/use_cases/logout.dart';
import '../features/auth/domain/use_cases/forgot_password.dart';
import '../features/auth/domain/use_cases/reset_password.dart';
import '../features/profile/data/data_sources/profile_remote_data_source.dart';
import '../features/profile/data/repositories/profile_repository_impl.dart';
import '../features/profile/domain/repositories/profile_repository.dart';
import '../features/profile/domain/use_cases/get_user_profile.dart';
import '../features/profile/domain/use_cases/update_profile.dart';
import '../features/profile/domain/use_cases/add_address.dart';
import '../features/profile/domain/use_cases/update_address.dart';
import '../features/profile/domain/use_cases/delete_address.dart';
import '../features/profile/domain/use_cases/set_default_address.dart';
import '../features/cart/data/data_sources/cart_remote_data_source.dart';
import '../features/cart/data/data_sources/order_remote_data_source.dart';
import '../features/cart/data/repositories/cart_repository_impl.dart';
import '../features/cart/data/repositories/order_repository_impl.dart';
import '../features/cart/domain/repositories/cart_repository.dart';
import '../features/cart/domain/repositories/order_repository.dart';
import '../features/cart/domain/use_cases/get_cart.dart';
import '../features/cart/domain/use_cases/add_to_cart.dart';
import '../features/cart/domain/use_cases/update_cart_item_quantity.dart';
import '../features/cart/domain/use_cases/remove_cart_item.dart';
import '../features/cart/domain/use_cases/place_order.dart';

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

/// Flutter secure storage provider (for repositories that need the raw FlutterSecureStorage).
final flutterSecureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Database helper provider (SQLite).
final databaseHelperProvider = Provider<DatabaseHelper>((ref) {
  return DatabaseHelper.instance;
});

/// Cart local data source provider.
final cartLocalDataSourceProvider = Provider<CartLocalDataSource>((ref) {
  final dbHelper = ref.watch(databaseHelperProvider);
  return CartLocalDataSource(dbHelper);
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

// ============================================================================
// Feature: Authentication (Phase 4)
// ============================================================================

/// Auth remote data source provider.
final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
});

/// Auth repository provider.
final authRepositoryProviderImpl = Provider<AuthRepository>((ref) {
  final remoteDataSource = ref.watch(authRemoteDataSourceProvider);
  final secureStorage = ref.watch(flutterSecureStorageProvider);
  return AuthRepositoryImpl(remoteDataSource, secureStorage);
});

/// Register use case provider.
final registerUseCaseProviderImpl = Provider<RegisterUseCase>((ref) {
  final repository = ref.watch(authRepositoryProviderImpl);
  return RegisterUseCase(repository);
});

/// Verify OTP use case provider.
final verifyOTPUseCaseProviderImpl = Provider<VerifyOTPUseCase>((ref) {
  final repository = ref.watch(authRepositoryProviderImpl);
  return VerifyOTPUseCase(repository);
});

/// Login use case provider.
final loginUseCaseProviderImpl = Provider<LoginUseCase>((ref) {
  final repository = ref.watch(authRepositoryProviderImpl);
  return LoginUseCase(repository);
});

/// Logout use case provider.
final logoutUseCaseProviderImpl = Provider<LogoutUseCase>((ref) {
  final repository = ref.watch(authRepositoryProviderImpl);
  return LogoutUseCase(repository);
});

/// Forgot password use case provider.
final forgotPasswordUseCaseProviderImpl =
    Provider<ForgotPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProviderImpl);
  return ForgotPasswordUseCase(repository);
});

/// Reset password use case provider.
final resetPasswordUseCaseProviderImpl = Provider<ResetPasswordUseCase>((ref) {
  final repository = ref.watch(authRepositoryProviderImpl);
  return ResetPasswordUseCase(repository);
});

// ============================================================================
// Feature: Profile (Phase 4)
// ============================================================================

/// Profile remote data source provider.
final profileRemoteDataSourceProvider =
    Provider<ProfileRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return ProfileRemoteDataSource(dio);
});

/// Profile repository provider.
final profileRepositoryProviderImpl = Provider<ProfileRepository>((ref) {
  final remoteDataSource = ref.watch(profileRemoteDataSourceProvider);
  return ProfileRepositoryImpl(remoteDataSource);
});

/// Get user profile use case provider.
final getUserProfileUseCaseProviderImpl =
    Provider<GetUserProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProviderImpl);
  return GetUserProfileUseCase(repository);
});

/// Update profile use case provider.
final updateProfileUseCaseProviderImpl = Provider<UpdateProfileUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProviderImpl);
  return UpdateProfileUseCase(repository);
});

/// Add address use case provider.
final addAddressUseCaseProviderImpl = Provider<AddAddressUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProviderImpl);
  return AddAddressUseCase(repository);
});

/// Update address use case provider.
final updateAddressUseCaseProviderImpl = Provider<UpdateAddressUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProviderImpl);
  return UpdateAddressUseCase(repository);
});

/// Delete address use case provider.
final deleteAddressUseCaseProviderImpl = Provider<DeleteAddressUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProviderImpl);
  return DeleteAddressUseCase(repository);
});

/// Set default address use case provider.
final setDefaultAddressUseCaseProviderImpl =
    Provider<SetDefaultAddressUseCase>((ref) {
  final repository = ref.watch(profileRepositoryProviderImpl);
  return SetDefaultAddressUseCase(repository);
});

// ============================================================================
// Feature: Cart & Checkout (Phase 5)
// ============================================================================

/// Cart remote data source provider.
final cartRemoteDataSourceProvider = Provider<CartRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return CartRemoteDataSource(dio);
});

/// Cart repository provider.
final cartRepositoryProviderImpl = Provider<CartRepository>((ref) {
  final remoteDataSource = ref.watch(cartRemoteDataSourceProvider);
  final localDataSource = ref.watch(cartLocalDataSourceProvider);
  return CartRepositoryImpl(remoteDataSource, localDataSource);
});

/// Order remote data source provider.
final orderRemoteDataSourceProvider = Provider<OrderRemoteDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return OrderRemoteDataSource(dio);
});

/// Order repository provider.
final orderRepositoryProviderImpl = Provider<OrderRepository>((ref) {
  final remoteDataSource = ref.watch(orderRemoteDataSourceProvider);
  return OrderRepositoryImpl(remoteDataSource);
});

/// Get cart use case provider.
final getCartUseCaseProviderImpl = Provider<GetCartUseCase>((ref) {
  final repository = ref.watch(cartRepositoryProviderImpl);
  return GetCartUseCase(repository);
});

/// Add to cart use case provider.
final addToCartUseCaseProviderImpl = Provider<AddToCartUseCase>((ref) {
  final repository = ref.watch(cartRepositoryProviderImpl);
  return AddToCartUseCase(repository);
});

/// Update cart item quantity use case provider.
final updateCartItemQuantityUseCaseProviderImpl =
    Provider<UpdateCartItemQuantityUseCase>((ref) {
  final repository = ref.watch(cartRepositoryProviderImpl);
  return UpdateCartItemQuantityUseCase(repository);
});

/// Remove cart item use case provider.
final removeCartItemUseCaseProviderImpl =
    Provider<RemoveCartItemUseCase>((ref) {
  final repository = ref.watch(cartRepositoryProviderImpl);
  return RemoveCartItemUseCase(repository);
});

/// Place order use case provider.
final placeOrderUseCaseProviderImpl = Provider<PlaceOrderUseCase>((ref) {
  final orderRepository = ref.watch(orderRepositoryProviderImpl);
  return PlaceOrderUseCase(orderRepository);
});
