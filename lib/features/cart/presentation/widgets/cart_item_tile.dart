import 'package:flutter/material.dart';
import '../../domain/models/cart.dart';

class CartItemTile extends StatelessWidget {
  final CartItemWithProduct itemWithProduct;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;

  const CartItemTile({
    super.key,
    required this.itemWithProduct,
    required this.onRemove,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final product = itemWithProduct.product;
    final cartItem = itemWithProduct.cartItem;
    final subtotal = itemWithProduct.totalPrice;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                product.images.isNotEmpty
                    ? product.images.first
                    : 'https://via.placeholder.com/80',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Product details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name
                  Text(
                    product.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Variant info (if any)
                  if (cartItem.variantId != null)
                    Text(
                      'Variant: ${cartItem.variantId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Price and quantity controls
                  Row(
                    children: [
                      // Price
                      Text(
                        '\$${product.basePrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const Spacer(),

                      // Quantity controls
                      _buildQuantityControls(context, theme),
                    ],
                  ),

                  // Subtotal
                  const SizedBox(height: 4),
                  Text(
                    'Subtotal: \$${subtotal.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: onRemove,
              tooltip: 'Remove from cart',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context, ThemeData theme) {
    final cartItem = itemWithProduct.cartItem;
    final product = itemWithProduct.product;
    final canDecrement = cartItem.quantity > 1;
    final canIncrement = cartItem.quantity < product.totalStock;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Decrement button
          InkWell(
            onTap: canDecrement
                ? () => onQuantityChanged(cartItem.quantity - 1)
                : null,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                Icons.remove,
                size: 18,
                color: canDecrement
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),

          // Quantity display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.symmetric(
                vertical: BorderSide(color: theme.colorScheme.outline),
              ),
            ),
            child: Text(
              '${cartItem.quantity}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Increment button
          InkWell(
            onTap: canIncrement
                ? () => onQuantityChanged(cartItem.quantity + 1)
                : null,
            borderRadius: const BorderRadius.horizontal(
              right: Radius.circular(8),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Icon(
                Icons.add,
                size: 18,
                color: canIncrement
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
