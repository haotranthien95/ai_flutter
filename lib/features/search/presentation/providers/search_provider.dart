import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/product.dart';
import '../../../home/domain/use_cases/search_products.dart';
import '../../../home/domain/repositories/product_repository.dart';

/// Search screen state.
class SearchState {
  const SearchState({
    this.query = '',
    this.suggestions = const [],
    this.results = const [],
    this.sortBy = 'relevance',
    this.filters,
    this.isSearching = false,
    this.isLoadingSuggestions = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
    this.cursor,
  });

  final String query;
  final List<String> suggestions;
  final List<Product> results;
  final String sortBy;
  final Map<String, dynamic>? filters;
  final bool isSearching;
  final bool isLoadingSuggestions;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;
  final String? cursor;

  SearchState copyWith({
    String? query,
    List<String>? suggestions,
    List<Product>? results,
    String? sortBy,
    Map<String, dynamic>? filters,
    bool? isSearching,
    bool? isLoadingSuggestions,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
    String? cursor,
  }) {
    return SearchState(
      query: query ?? this.query,
      suggestions: suggestions ?? this.suggestions,
      results: results ?? this.results,
      sortBy: sortBy ?? this.sortBy,
      filters: filters ?? this.filters,
      isSearching: isSearching ?? this.isSearching,
      isLoadingSuggestions: isLoadingSuggestions ?? this.isLoadingSuggestions,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      error: error,
      cursor: cursor ?? this.cursor,
    );
  }

  SearchState clearError() {
    return SearchState(
      query: query,
      suggestions: suggestions,
      results: results,
      sortBy: sortBy,
      filters: filters,
      isSearching: isSearching,
      isLoadingSuggestions: isLoadingSuggestions,
      isLoadingMore: isLoadingMore,
      hasMore: hasMore,
      error: null,
      cursor: cursor,
    );
  }
}

/// Search provider for managing product search.
class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._searchProductsUseCase, this._productRepository)
      : super(const SearchState());

  final SearchProductsUseCase _searchProductsUseCase;
  final ProductRepository _productRepository;
  Timer? _debounceTimer;

  static const _debounceDuration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Updates search query and triggers debounced autocomplete.
  void updateQuery(String query) {
    state = state.copyWith(query: query);

    // Cancel previous timer
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      state = state.copyWith(suggestions: []);
      return;
    }

    // Debounce autocomplete requests
    _debounceTimer = Timer(_debounceDuration, () {
      _loadSuggestions(query);
    });
  }

  /// Loads autocomplete suggestions.
  Future<void> _loadSuggestions(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(isLoadingSuggestions: true);

    try {
      final suggestions = await _productRepository.getSearchSuggestions(
        query: query.trim(),
        limit: 5,
      );

      // Only update if query hasn't changed
      if (state.query == query) {
        state = state.copyWith(
          suggestions: suggestions,
          isLoadingSuggestions: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingSuggestions: false,
        suggestions: [],
      );
    }
  }

  /// Performs product search with current query.
  Future<void> search() async {
    final query = state.query.trim();
    if (query.isEmpty) return;

    state = state.copyWith(
      isSearching: true,
      error: null,
      suggestions: [], // Clear suggestions when searching
    );

    try {
      final results = await _searchProductsUseCase.execute(
        query: query,
        limit: 20,
        filters: state.filters,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        results: results,
        isSearching: false,
        hasMore: results.length >= 20,
        cursor: results.isNotEmpty ? results.last.id : null,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: _formatError(e),
      );
    }
  }

  /// Loads more search results for pagination.
  Future<void> loadMoreResults() async {
    if (state.isLoadingMore || !state.hasMore || state.cursor == null) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreResults = await _searchProductsUseCase.execute(
        query: state.query,
        limit: 20,
        cursor: state.cursor,
        filters: state.filters,
        sortBy: state.sortBy,
      );

      state = state.copyWith(
        results: [...state.results, ...moreResults],
        isLoadingMore: false,
        hasMore: moreResults.length >= 20,
        cursor: moreResults.isNotEmpty ? moreResults.last.id : state.cursor,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: _formatError(e),
      );
    }
  }

  /// Applies filters to search results.
  void applyFilters(Map<String, dynamic>? filters) {
    state = state.copyWith(
      filters: filters,
      results: [],
      cursor: null,
      hasMore: true,
    );

    if (state.query.trim().isNotEmpty) {
      search();
    }
  }

  /// Changes search result sorting.
  void applySorting(String sortBy) {
    if (state.sortBy == sortBy) return;

    state = state.copyWith(
      sortBy: sortBy,
      results: [],
      cursor: null,
      hasMore: true,
    );

    if (state.query.trim().isNotEmpty) {
      search();
    }
  }

  /// Clears search query and results.
  void clear() {
    _debounceTimer?.cancel();
    state = const SearchState();
  }

  /// Selects a suggestion and performs search.
  void selectSuggestion(String suggestion) {
    state = state.copyWith(
      query: suggestion,
      suggestions: [],
    );
    search();
  }

  /// Retries search after error.
  void retry() {
    search();
  }

  /// Formats error message for display.
  String _formatError(Object error) {
    if (error is ArgumentError) {
      return error.message.toString();
    }
    return 'Không thể tìm kiếm. Vui lòng thử lại.';
  }
}

/// Provider for search screen state.
///
/// This is a stub that will be overridden in app/providers.dart with proper dependencies.
final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  throw UnimplementedError(
    'searchProvider must be overridden with searchProviderOverride from app/providers.dart',
  );
});
