import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/error_view.dart';
import '../../../core/utils/formatters.dart';
import 'providers/product_detail_provider.dart';
import 'widgets/image_carousel.dart';
import 'widgets/variant_selector.dart';
import 'widgets/review_summary.dart';
import 'widgets/review_tile.dart';

/// Product detail screen showing complete product information.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({
    required this.productId,
    super.key,
  });

  final String productId;

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    // Load product detail on screen open
    Future.microtask(() {
      ref
          .read(productDetailProvider.notifier)
          .loadProductDetail(widget.productId);
    });
  }

  @override
  void dispose() {
    // Reset state when leaving screen
    ref.read(productDetailProvider.notifier).reset();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productDetailProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: Share product link
            },
            tooltip: 'Chia sẻ',
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
            tooltip: 'Giỏ hàng',
          ),
        ],
      ),
      body: _buildBody(state),
      floatingActionButton: state.product != null && state.canBePurchased
          ? FloatingActionButton.extended(
              onPressed: () => _handleAddToCart(context),
              icon: const Icon(Icons.add_shopping_cart),
              label: const Text('Thêm vào giỏ'),
            )
          : null,
    );
  }

  Widget _buildBody(ProductDetailState state) {
    // Loading state
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // Error state
    if (state.error != null) {
      return ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(productDetailProvider.notifier).retry(widget.productId),
      );
    }

    // Product loaded
    final product = state.product;
    if (product == null) {
      return const ErrorView(
        message: 'Không tìm thấy sản phẩm',
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel
          ImageCarousel(images: product.images),

          // Product info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8.0),

                // Price
                Row(
                  children: [
                    Text(
                      formatVND(state.currentPrice.toDouble()),
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    if (state.selectedVariant != null &&
                        state.selectedVariant!.price != product.basePrice) ...[
                      const SizedBox(width: 8.0),
                      Text(
                        formatVND(product.basePrice),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8.0),

                // Stock status
                Row(
                  children: [
                    Icon(
                      state.isInStock
                          ? Icons.check_circle_outline
                          : Icons.cancel_outlined,
                      size: 20.0,
                      color: state.isInStock ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      state.isInStock
                          ? 'Còn hàng (${state.currentStock})'
                          : 'Hết hàng',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: state.isInStock ? Colors.green : Colors.red,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),

                // Rating and sold count
                Row(
                  children: [
                    if (product.totalReviews > 0) ...[
                      Icon(
                        Icons.star,
                        size: 20.0,
                        color: Colors.amber[700],
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        product.formattedRating,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '(${product.totalReviews} đánh giá)',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16.0),
                    ],
                    Text(
                      product.soldCountText,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(),

          // Variant selector
          if (state.variants.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: VariantSelector(
                variants: state.variants,
                selectedVariant: state.selectedVariant,
                onVariantSelected: (variant) => ref
                    .read(productDetailProvider.notifier)
                    .selectVariant(variant),
              ),
            ),

          if (state.variants.isNotEmpty) const Divider(),

          // Description
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mô tả sản phẩm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Text(
                  product.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: _isDescriptionExpanded ? null : 4,
                  overflow: _isDescriptionExpanded
                      ? TextOverflow.visible
                      : TextOverflow.ellipsis,
                ),
                if (product.description.length > 100)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isDescriptionExpanded = !_isDescriptionExpanded;
                      });
                    },
                    child: Text(
                      _isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm',
                    ),
                  ),
              ],
            ),
          ),

          const Divider(),

          // Shop info (placeholder for MVP)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.store,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Tên cửa hàng'),
            subtitle: const Text('4.8 ⭐ • 1.2K người theo dõi'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to shop page (US-006)
            },
          ),

          const Divider(),

          // Reviews summary
          if (product.totalReviews > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ReviewSummary(
                averageRating: product.averageRating,
                totalReviews: product.totalReviews,
              ),
            ),

          // Review list
          if (state.reviews.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Đánh giá gần đây',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      if (product.totalReviews > 5)
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to all reviews page
                          },
                          child: const Text('Xem tất cả'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  ...state.reviews.map(
                    (review) => ReviewTile(review: review),
                  ),
                ],
              ),
            ),

          // Bottom spacing for FAB
          const SizedBox(height: 80.0),
        ],
      ),
    );
  }

  void _handleAddToCart(BuildContext context) {
    // TODO: Check authentication status
    // For now, show login dialog for guests
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng nhập'),
        content: const Text(
          'Vui lòng đăng nhập để thêm sản phẩm vào giỏ hàng',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/auth/login');
            },
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
  }
}
