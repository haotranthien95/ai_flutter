import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../home/presentation/widgets/filter_bottom_sheet.dart';
import 'providers/search_provider.dart';
import 'widgets/sort_options_dialog.dart';

/// Search screen with autocomplete and filters.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(searchProvider.notifier).loadMoreResults();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Tìm kiếm sản phẩm...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(searchProvider.notifier).clear();
                    },
                  )
                : null,
          ),
          onChanged: (query) {
            ref.read(searchProvider.notifier).updateQuery(query);
          },
          onSubmitted: (query) {
            if (query.trim().isNotEmpty) {
              ref.read(searchProvider.notifier).search();
              _searchFocusNode.unfocus();
            }
          },
          textInputAction: TextInputAction.search,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
            tooltip: 'Giỏ hàng',
          ),
        ],
      ),
      body: Column(
        children: [
          // Autocomplete suggestions
          if (state.suggestions.isNotEmpty && _searchFocusNode.hasFocus)
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: state.suggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = state.suggestions[index];
                  return ListTile(
                    leading: const Icon(Icons.search),
                    title: Text(suggestion),
                    onTap: () {
                      _searchController.text = suggestion;
                      ref
                          .read(searchProvider.notifier)
                          .selectSuggestion(suggestion);
                      _searchFocusNode.unfocus();
                    },
                  );
                },
              ),
            ),

          // Filter and sort bar
          if (state.query.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Text(
                    state.results.isEmpty && !state.isSearching
                        ? 'Không có kết quả'
                        : '${state.results.length} kết quả',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () => _showFilterSheet(context),
                    icon: const Icon(Icons.filter_list, size: 20.0),
                    label: const Text('Lọc'),
                  ),
                  const SizedBox(width: 8.0),
                  OutlinedButton.icon(
                    onPressed: () => _showSortDialog(context),
                    icon: const Icon(Icons.sort, size: 20.0),
                    label: const Text('Sắp xếp'),
                  ),
                ],
              ),
            ),

          // Search results
          Expanded(
            child: _buildSearchResults(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults(SearchState state) {
    // Initial state - no search yet
    if (state.query.isEmpty && state.results.isEmpty) {
      return const EmptyState(
        icon: Icons.search,
        message: 'Nhập từ khóa để tìm kiếm sản phẩm',
      );
    }

    // Loading state
    if (state.isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state.error != null) {
      return ErrorView(
        message: state.error!,
        onRetry: () => ref.read(searchProvider.notifier).retry(),
      );
    }

    // Empty results
    if (state.results.isEmpty) {
      return EmptySearchResults(searchQuery: state.query);
    }

    // Results grid
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final product = state.results[index];
                return ProductCard(
                  product: product,
                  onTap: () => context.push('/product/${product.id}'),
                );
              },
              childCount: state.results.length,
            ),
          ),
        ),

        // Load more indicator
        if (state.isLoadingMore)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          ),

        // End of list indicator
        if (!state.hasMore && state.results.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  'Đã hiển thị tất cả kết quả',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        currentFilters: ref.read(searchProvider).filters,
      ),
    ).then((filters) {
      if (filters != null) {
        ref.read(searchProvider.notifier).applyFilters(filters);
      }
    });
  }

  void _showSortDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (context) => SortOptionsDialog(
        currentSortBy: ref.read(searchProvider).sortBy,
      ),
    ).then((sortBy) {
      if (sortBy != null) {
        ref.read(searchProvider.notifier).applySorting(sortBy);
      }
    });
  }
}
