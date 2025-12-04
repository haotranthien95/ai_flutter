import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Base shimmer container for skeleton loading effects
class SkeletonBox extends StatelessWidget {
  /// Creates skeleton box
  const SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius = 8.0,
    super.key,
  });

  /// Width of skeleton box
  final double width;

  /// Height of skeleton box
  final double height;

  /// Border radius of skeleton box
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor: Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

/// Product card skeleton for list loading
class ProductCardSkeleton extends StatelessWidget {
  /// Creates product card skeleton
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image skeleton
          const SkeletonBox(
            width: double.infinity,
            height: 180,
            borderRadius: 0,
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton (2 lines)
                const SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: 150,
                  height: 16,
                  borderRadius: 4,
                ),

                const SizedBox(height: 12),

                // Price skeleton
                const SkeletonBox(
                  width: 100,
                  height: 20,
                  borderRadius: 4,
                ),

                const SizedBox(height: 8),

                // Rating and sold count skeleton
                Row(
                  children: [
                    const SkeletonBox(
                      width: 80,
                      height: 14,
                      borderRadius: 4,
                    ),
                    const SizedBox(width: 12),
                    const SkeletonBox(
                      width: 60,
                      height: 14,
                      borderRadius: 4,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal product card skeleton
class HorizontalProductCardSkeleton extends StatelessWidget {
  /// Creates horizontal product card skeleton
  const HorizontalProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Row(
        children: [
          // Product image skeleton
          const SkeletonBox(
            width: 100,
            height: 100,
            borderRadius: 8,
          ),

          const SizedBox(width: 12),

          // Product info skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: 150,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 12),
                const SkeletonBox(
                  width: 100,
                  height: 20,
                  borderRadius: 4,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

/// Product detail page skeleton
class ProductDetailSkeleton extends StatelessWidget {
  /// Creates product detail skeleton
  const ProductDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image carousel skeleton
          const SkeletonBox(
            width: double.infinity,
            height: 375,
            borderRadius: 0,
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton (3 lines)
                const SkeletonBox(
                  width: double.infinity,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: double.infinity,
                  height: 20,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: 200,
                  height: 20,
                  borderRadius: 4,
                ),

                const SizedBox(height: 16),

                // Price skeleton
                const SkeletonBox(
                  width: 150,
                  height: 28,
                  borderRadius: 4,
                ),

                const SizedBox(height: 8),

                // Rating skeleton
                const SkeletonBox(
                  width: 120,
                  height: 16,
                  borderRadius: 4,
                ),

                const SizedBox(height: 24),

                // Variants section skeleton
                const SkeletonBox(
                  width: 100,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SkeletonBox(
                      width: 80,
                      height: 40,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 8),
                    const SkeletonBox(
                      width: 80,
                      height: 40,
                      borderRadius: 8,
                    ),
                    const SizedBox(width: 8),
                    const SkeletonBox(
                      width: 80,
                      height: 40,
                      borderRadius: 8,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Description section skeleton
                const SkeletonBox(
                  width: 120,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 12),
                const SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: double.infinity,
                  height: 16,
                  borderRadius: 4,
                ),
                const SizedBox(height: 8),
                const SkeletonBox(
                  width: 250,
                  height: 16,
                  borderRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cart item skeleton
class CartItemSkeleton extends StatelessWidget {
  /// Creates cart item skeleton
  const CartItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Product image skeleton
            const SkeletonBox(
              width: 80,
              height: 80,
              borderRadius: 8,
            ),

            const SizedBox(width: 12),

            // Product info skeleton
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SkeletonBox(
                    width: double.infinity,
                    height: 16,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 8),
                  const SkeletonBox(
                    width: 120,
                    height: 14,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SkeletonBox(
                        width: 100,
                        height: 20,
                        borderRadius: 4,
                      ),
                      const SkeletonBox(
                        width: 100,
                        height: 32,
                        borderRadius: 16,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category chip skeleton
class CategoryChipSkeleton extends StatelessWidget {
  /// Creates category chip skeleton
  const CategoryChipSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(right: 8.0),
      child: SkeletonBox(
        width: 100,
        height: 40,
        borderRadius: 20,
      ),
    );
  }
}

/// Search result skeleton (list of products)
class SearchResultSkeleton extends StatelessWidget {
  /// Creates search result skeleton
  const SearchResultSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: HorizontalProductCardSkeleton(),
      ),
    );
  }
}
