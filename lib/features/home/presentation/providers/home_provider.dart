import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/product.dart';
import '../../../../core/models/category.dart';
import '../../domain/use_cases/get_products.dart';
import '../../domain/use_cases/get_categories.dart';

/// Home screen state.
class HomeState {
  const HomeState({
    this.products = const [],
    this.categories = const [],
    this.selectedCategoryId,
    this.sortBy = 'relevance',
    this.filters,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.cursor,
  });

  final List<Product> products;
  final List<Category> categories;
  final String? selectedCategoryId;
  final String sortBy;
  final Map<String, dynamic>? filters;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? cursor;

  HomeState copyWith({
    List<Product>? products,
    List<Category>? categories,
    String? selectedCategoryId,
    String? sortBy,
    Map<String, dynamic>? filters,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? cursor,
  }) {
    return HomeState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      sortBy: sortBy ?? this.sortBy,
      filters: filters ?? this.filters,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      cursor: cursor ?? this.cursor,
    );
  }

  HomeState clearError() {
    return HomeState(
      products: products,
      categories: categories,
      selectedCategoryId: selectedCategoryId,
      sortBy: sortBy,
      filters: filters,
      isLoading: isLoading,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      error: null,
      cursor: cursor,
    );
  }
}

/// Home provider for managing product list and categories.
class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier(this._getProductsUseCase, this._getCategoriesUseCase)
      : super(const HomeState()) {
    // Load initial data
    loadCategories();
    loadProducts();
  }

  final GetProductsUseCase _getProductsUseCase;
  final GetCategoriesUseCase _getCategoriesUseCase;

  /// Loads categories from repository.
  Future<void> loadCategories() async {
    try {
      final categories = await _getCategoriesUseCase.getActiveCategories();
      state = state.copyWith(categories: categories);
    } catch (e) {
      // Categories are optional, don't block UI if they fail
      print('Failed to load categories: $e');
    }
  }

  /// Loads products with current filters and sorting.
  Future<void> loadProducts({bool refresh = false}) async {
    if (state.isLoading) return;

    state = state.copyWith(
      isLoading: true,
      error: null,
    );

    try {
      final products = await _getProductsUseCase.execute(
        limit: 20,
        categoryId: state.selectedCategoryId,
        filters: state.filters,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        products: products,
        isLoading: false,
        hasMore: products.length >= 20,
        cursor: products.isNotEmpty ? products.last.id : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _formatError(e),
      );
    }
  }

  /// Loads more products for pagination.
  Future<void> loadMoreProducts() async {
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreProducts = await _getProductsUseCase.execute(
        limit: 20,
        cursor: state.cursor,
        categoryId: state.selectedCategoryId,
        filters: state.filters,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        products: [...state.products, ...moreProducts],
        isLoadingMore: false,
        hasMore: moreProducts.length >= 20,
        cursor: moreProducts.isNotEmpty ? moreProducts.last.id : state.cursor,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: _formatError(e),
      );
    }
  }

  /// Filters products by category.
  void filterByCategory(String? categoryId) {
    if (state.selectedCategoryId == categoryId) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      products: [],
      cursor: null,
      hasMore: true,
    );

    loadProducts();
  }

  /// Changes product sorting.
  void sortProducts(String sortBy) {
    if (state.sortBy == sortBy) return;

    state = state.copyWith(
      sortBy: sortBy,
      products: [],
      cursor: null,
      hasMore: true,
    );

    loadProducts();
  }

  /// Applies filters to product list.
  void applyFilters(Map<String, dynamic>? filters) {
    state = state.copyWith(
      filters: filters,
      products: [],
      cursor: null,
      hasMore: true,
    );

    loadProducts();
  }

  /// Clears all filters and category selection.
  void clearFilters() {
    state = state.copyWith(
      selectedCategoryId: null,
      filters: null,
      sortBy: 'relevance',
      products: [],
      cursor: null,
      hasMore: true,
    );

    loadProducts();
  }

  /// Retries loading products after error.
  void retry() {
    loadProducts();
  }

  /// Formats error message for display.
  String _formatError(Object error) {
    if (error is ArgumentError) {
      return error.message.toString();
    }
    return 'Không thể tải sản phẩm. Vui lòng thử lại.';
  }
}

/// Provider for home screen state.
///
/// This is a stub that will be overridden in app/providers.dart with proper dependencies.
/// Use homeProviderOverride from app/providers.dart in production code.
final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  throw UnimplementedError(
    'homeProvider must be overridden with homeProviderOverride from app/providers.dart',
  );
});
