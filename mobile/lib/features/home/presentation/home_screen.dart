import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/product_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/skeleton_loading.dart';
import '../../../core/widgets/animated_widgets.dart';
import 'providers/home_provider.dart';
import 'widgets/category_chip.dart';
import 'widgets/filter_bottom_sheet.dart';

/// Home screen showing product grid with categories and filters.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      // Load more when scrolled to 90% of the list
      ref.read(homeProvider.notifier).loadMoreProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trang chủ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push('/search'),
            tooltip: 'Tìm kiếm',
          ),
          AnimatedCartBadge(
            onTap: () => context.push('/cart'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(homeProvider.notifier).loadProducts(refresh: true);
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Categories horizontal list
            if (state.categories.isNotEmpty)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 56.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 8.0,
                    ),
                    itemCount: state.categories.length + 1, // +1 for "All"
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // "All" category chip
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CategoryChip(
                            label: 'Tất cả',
                            isSelected: state.selectedCategoryId == null,
                            onTap: () => ref
                                .read(homeProvider.notifier)
                                .filterByCategory(null),
                          ),
                        );
                      }

                      final category = state.categories[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: CategoryChip(
                          label: category.name,
                          iconUrl: category.iconUrl,
                          isSelected: state.selectedCategoryId == category.id,
                          onTap: () => ref
                              .read(homeProvider.notifier)
                              .filterByCategory(category.id),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Filter and sort bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _showFilterSheet(context),
                      icon: const Icon(Icons.filter_list, size: 20.0),
                      label: const Text('Lọc'),
                    ),
                    const SizedBox(width: 8.0),
                    OutlinedButton.icon(
                      onPressed: () => _showSortOptions(context),
                      icon: const Icon(Icons.sort, size: 20.0),
                      label: Text(_getSortLabel(state.sortBy)),
                    ),
                    const Spacer(),
                    if (state.filters != null ||
                        state.selectedCategoryId != null)
                      TextButton(
                        onPressed: () =>
                            ref.read(homeProvider.notifier).clearFilters(),
                        child: const Text('Xóa bộ lọc'),
                      ),
                  ],
                ),
              ),
            ),

            // Loading state - show skeleton
            if (state.isLoading && state.products.isEmpty)
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
                    (context, index) => const ProductCardSkeleton(),
                    childCount: 6, // Show 6 skeleton cards
                  ),
                ),
              ),

            // Error state
            if (!state.isLoading && state.error != null)
              SliverFillRemaining(
                child: ErrorView(
                  message: state.error!,
                  onRetry: () => ref.read(homeProvider.notifier).retry(),
                ),
              ),

            // Empty state
            if (!state.isLoading &&
                state.error == null &&
                state.products.isEmpty)
              const SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.inventory_2_outlined,
                  message: 'Không có sản phẩm nào',
                ),
              ),

            // Product grid
            if (!state.isLoading &&
                state.error == null &&
                state.products.isNotEmpty)
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
                      final product = state.products[index];
                      return ProductCard(
                        product: product,
                        onTap: () => context.push('/product/${product.id}'),
                      );
                    },
                    childCount: state.products.length,
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
            if (!state.hasMore && state.products.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      'Đã hiển thị tất cả sản phẩm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        currentFilters: ref.read(homeProvider).filters,
      ),
    ).then((filters) {
      if (filters != null) {
        ref.read(homeProvider.notifier).applyFilters(filters);
      }
    });
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet<String>(
      context: context,
      builder: (context) => _SortOptionsSheet(
        currentSortBy: ref.read(homeProvider).sortBy,
      ),
    ).then((sortBy) {
      if (sortBy != null) {
        ref.read(homeProvider.notifier).sortProducts(sortBy);
      }
    });
  }

  String _getSortLabel(String sortBy) {
    switch (sortBy) {
      case 'relevance':
        return 'Liên quan';
      case 'newest':
        return 'Mới nhất';
      case 'best_selling':
        return 'Bán chạy';
      case 'price_low_high':
        return 'Giá thấp';
      case 'price_high_low':
        return 'Giá cao';
      case 'top_rated':
        return 'Đánh giá';
      default:
        return 'Sắp xếp';
    }
  }
}

/// Sort options bottom sheet.
class _SortOptionsSheet extends StatelessWidget {
  const _SortOptionsSheet({required this.currentSortBy});

  final String currentSortBy;

  @override
  Widget build(BuildContext context) {
    final options = [
      ('relevance', 'Liên quan', Icons.featured_play_list_outlined),
      ('newest', 'Mới nhất', Icons.new_releases_outlined),
      ('best_selling', 'Bán chạy nhất', Icons.trending_up),
      ('price_low_high', 'Giá: Thấp đến cao', Icons.arrow_upward),
      ('price_high_low', 'Giá: Cao đến thấp', Icons.arrow_downward),
      ('top_rated', 'Đánh giá cao', Icons.star_outline),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Sắp xếp theo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),
          ...options.map((option) {
            final (value, label, icon) = option;
            final isSelected = currentSortBy == value;

            return ListTile(
              leading: Icon(icon),
              title: Text(label),
              trailing: isSelected
                  ? Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              selected: isSelected,
              onTap: () => Navigator.pop(context, value),
            );
          }),
        ],
      ),
    );
  }
}
