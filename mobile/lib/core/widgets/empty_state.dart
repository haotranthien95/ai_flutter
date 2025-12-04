import 'package:flutter/material.dart';

/// Empty state widget for displaying when lists are empty.
///
/// Shows an icon, message, and optional action button.
class EmptyState extends StatelessWidget {
  /// Creates an empty state view.
  const EmptyState({
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  /// Empty state message.
  final String message;

  /// Empty state icon (defaults to inbox_outlined).
  final IconData icon;

  /// Optional action button label.
  final String? actionLabel;

  /// Optional action button callback.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              icon,
              size: 80.0,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact empty state for inline use.
class CompactEmptyState extends StatelessWidget {
  /// Creates a compact empty state view.
  const CompactEmptyState({
    required this.message,
    super.key,
    this.icon = Icons.inbox_outlined,
  });

  /// Empty state message.
  final String message;

  /// Empty state icon.
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            icon,
            size: 24.0,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 12.0),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// Empty search results view.
class EmptySearchResults extends StatelessWidget {
  /// Creates an empty search results view.
  const EmptySearchResults({
    super.key,
    this.searchQuery,
  });

  /// Optional search query to display in message.
  final String? searchQuery;

  @override
  Widget build(BuildContext context) {
    final String message = searchQuery != null
        ? 'Không tìm thấy kết quả cho "$searchQuery"'
        : 'Không tìm thấy kết quả';

    return EmptyState(
      icon: Icons.search_off_outlined,
      message: message,
    );
  }
}

/// Empty cart view.
class EmptyCart extends StatelessWidget {
  /// Creates an empty cart view.
  const EmptyCart({
    super.key,
    this.onStartShopping,
  });

  /// Optional callback to navigate to shopping.
  final VoidCallback? onStartShopping;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.shopping_cart_outlined,
      message: 'Giỏ hàng của bạn đang trống',
      actionLabel: 'Bắt đầu mua sắm',
      onAction: onStartShopping,
    );
  }
}

/// Empty order history view.
class EmptyOrderHistory extends StatelessWidget {
  /// Creates an empty order history view.
  const EmptyOrderHistory({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.receipt_long_outlined,
      message: 'Bạn chưa có đơn hàng nào',
    );
  }
}
