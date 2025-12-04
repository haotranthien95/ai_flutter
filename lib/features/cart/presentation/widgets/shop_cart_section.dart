import 'package:flutter/material.dart';
import 'package:ai_flutter/core/models/voucher.dart';
import '../../domain/models/cart.dart';
import 'cart_item_tile.dart';

class ShopCartSection extends StatelessWidget {
  final String shopId;
  final String shopName;
  final List<CartItemWithProduct> items;
  final Voucher? voucher;
  final ValueChanged<String> onRemoveItem;
  final void Function(String cartItemId, int quantity) onUpdateQuantity;
  final VoidCallback onSelectVoucher;
  final VoidCallback? onRemoveVoucher;

  const ShopCartSection({
    super.key,
    required this.shopId,
    required this.shopName,
    required this.items,
    this.voucher,
    required this.onRemoveItem,
    required this.onUpdateQuantity,
    required this.onSelectVoucher,
    this.onRemoveVoucher,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shopTotal = items.fold<double>(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    final discount = voucher?.calculateDiscount(shopTotal) ?? 0.0;
    final finalTotal = shopTotal - discount;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shop header
            Row(
              children: [
                Icon(
                  Icons.store,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    shopName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Optional: Navigate to shop
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () {
                    // TODO: Navigate to shop page
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Cart items
            ...items.map((item) => CartItemTile(
                  itemWithProduct: item,
                  onRemove: () => onRemoveItem(item.cartItem.id),
                  onQuantityChanged: (quantity) =>
                      onUpdateQuantity(item.cartItem.id, quantity),
                )),

            // Shop voucher section
            const SizedBox(height: 8),
            if (voucher != null)
              _buildAppliedVoucher(context, theme, discount)
            else
              _buildSelectVoucherButton(context, theme),

            // Shop subtotal
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Shop Total:',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (discount > 0) ...[
                      Text(
                        '\$${shopTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          decoration: TextDecoration.lineThrough,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '\$${finalTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ] else
                      Text(
                        '\$${shopTotal.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppliedVoucher(
      BuildContext context, ThemeData theme, double discount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_offer,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucher!.code,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  voucher!.description ?? 'Shop voucher',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '-\$${discount.toStringAsFixed(2)}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onRemoveVoucher,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Remove voucher',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectVoucherButton(BuildContext context, ThemeData theme) {
    return InkWell(
      onTap: onSelectVoucher,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.outline,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_offer_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Select shop voucher',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
