import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/product.dart';
import '../utils/formatters.dart';

/// Product card widget for displaying products in lists and grids.
///
/// Shows product image, title, price, rating, and shop badge.
/// Optimized for grid layouts (2-column).
class ProductCard extends StatelessWidget {
  /// Creates a product card.
  const ProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  /// Product data to display.
  final Product product;

  /// Tap callback (navigate to product detail).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product image
            AspectRatio(
              aspectRatio: 1.0,
              child: CachedNetworkImage(
                imageUrl: product.primaryImageUrl,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (BuildContext context, String url, Object error) =>
                    Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Product title (2 lines max)
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    // Price
                    Text(
                      formatVND(product.basePrice),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    // Rating and sold count
                    Row(
                      children: <Widget>[
                        if (product.totalReviews > 0) ...<Widget>[
                          Icon(
                            Icons.star,
                            size: 14.0,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            product.formattedRating,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Expanded(
                          child: Text(
                            product.soldCountText,
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal product card for list views.
class HorizontalProductCard extends StatelessWidget {
  /// Creates a horizontal product card.
  const HorizontalProductCard({
    required this.product,
    required this.onTap,
    super.key,
  });

  /// Product data to display.
  final Product product;

  /// Tap callback (navigate to product detail).
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Product image (square thumbnail)
            SizedBox(
              width: 100.0,
              height: 100.0,
              child: CachedNetworkImage(
                imageUrl: product.primaryImageUrl,
                fit: BoxFit.cover,
                placeholder: (BuildContext context, String url) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (BuildContext context, String url, Object error) =>
                    Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
            // Product info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Product title
                    Text(
                      product.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8.0),
                    // Price
                    Text(
                      formatVND(product.basePrice),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    // Rating and sold count
                    Row(
                      children: <Widget>[
                        if (product.totalReviews > 0) ...<Widget>[
                          Icon(
                            Icons.star,
                            size: 14.0,
                            color: Colors.amber[700],
                          ),
                          const SizedBox(width: 4.0),
                          Text(
                            product.formattedRating,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(width: 8.0),
                        ],
                        Text(
                          product.soldCountText,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact product card for cart items.
class CompactProductCard extends StatelessWidget {
  /// Creates a compact product card.
  const CompactProductCard({
    required this.product,
    required this.quantity,
    super.key,
    this.variantName,
    this.onTap,
  });

  /// Product data to display.
  final Product product;

  /// Quantity in cart.
  final int quantity;

  /// Optional variant name.
  final String? variantName;

  /// Optional tap callback.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Product image (small thumbnail)
          SizedBox(
            width: 60.0,
            height: 60.0,
            child: CachedNetworkImage(
              imageUrl: product.primaryImageUrl,
              fit: BoxFit.cover,
              placeholder: (BuildContext context, String url) => Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              errorWidget: (BuildContext context, String url, Object error) =>
                  Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child:
                    const Icon(Icons.image_not_supported_outlined, size: 20.0),
              ),
            ),
          ),
          const SizedBox(width: 12.0),
          // Product info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  product.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variantName != null) ...<Widget>[
                  const SizedBox(height: 4.0),
                  Text(
                    variantName!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
                const SizedBox(height: 4.0),
                Row(
                  children: <Widget>[
                    Text(
                      formatVND(product.basePrice),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'x$quantity',
                      style: Theme.of(context).textTheme.bodyMedium,
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
