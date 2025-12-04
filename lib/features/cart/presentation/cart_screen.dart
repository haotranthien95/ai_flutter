import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/routes.dart';
import '../../../core/widgets/error_view.dart';
import 'providers/cart_provider.dart';
import 'widgets/shop_cart_section.dart';
import 'widgets/voucher_selector_bottom_sheet.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
      ),
      body: cartState.when(
        data: (cart) {
          if (cart.items.isEmpty) {
            return _buildEmptyCart(context);
          }

          final shopGroups = cart.shopGroups;

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: shopGroups.length,
                  itemBuilder: (context, index) {
                    final shopId = shopGroups.keys.elementAt(index);
                    final shopItems = shopGroups[shopId]!;
                    final shopName = shopItems
                        .first.product.shopId; // Use shopId as name for now

                    return ShopCartSection(
                      shopId: shopId,
                      shopName: shopName,
                      items: shopItems,
                      voucher: null, // TODO: Add voucher support later
                      onRemoveItem: (cartItemId) {
                        ref.read(cartProvider.notifier).removeItem(cartItemId);
                      },
                      onUpdateQuantity: (cartItemId, quantity) {
                        ref.read(cartProvider.notifier).updateQuantity(
                              cartItemId: cartItemId,
                              quantity: quantity,
                            );
                      },
                      onSelectVoucher: () {
                        _showVoucherSelector(context, ref, shopId);
                      },
                      onRemoveVoucher: null,
                    );
                  },
                ),
              ),
              _buildBottomBar(context, ref, cart),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(
          message: error.toString(),
          onRetry: () {
            ref.invalidate(cartProvider);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Start Shopping'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, cart) {
    final theme = Theme.of(context);
    final totalAmount = cart.totalAmount;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '\$${totalAmount.toStringAsFixed(2)}',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: cart.items.isEmpty
                  ? null
                  : () {
                      Navigator.of(context).pushNamed(Routes.checkout);
                    },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
              child: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }

  void _showVoucherSelector(
      BuildContext context, WidgetRef ref, String shopId) {
    final cart = ref.read(cartProvider).value;
    if (cart == null) return;

    final shopTotal = cart.getShopSubtotal(shopId);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoucherSelectorBottomSheet(
        shopId: shopId,
        orderTotal: shopTotal,
      ),
    );
  }
}
