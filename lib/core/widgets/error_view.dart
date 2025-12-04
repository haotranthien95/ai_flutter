import 'package:flutter/material.dart';

/// Error view widget for displaying error states.
///
/// Shows an error icon, message, and optional retry button.
class ErrorView extends StatelessWidget {
  /// Creates an error view.
  const ErrorView({
    required this.message,
    super.key,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  /// Error message to display.
  final String message;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  /// Error icon (defaults to error_outline).
  final IconData icon;

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
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16.0),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 24.0),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Compact error view for inline error states.
class CompactErrorView extends StatelessWidget {
  /// Creates a compact error view.
  const CompactErrorView({
    required this.message,
    super.key,
    this.onRetry,
  });

  /// Error message to display.
  final String message;

  /// Optional retry callback.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(width: 12.0),
            IconButton(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              tooltip: 'Thử lại',
            ),
          ],
        ],
      ),
    );
  }
}

/// Error banner for displaying non-blocking errors.
class ErrorBanner extends StatelessWidget {
  /// Creates an error banner.
  const ErrorBanner({
    required this.message,
    super.key,
    this.onDismiss,
  });

  /// Error message to display.
  final String message;

  /// Optional dismiss callback.
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.warning_amber_rounded,
            color: Theme.of(context).colorScheme.onErrorContainer,
            size: 24.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onErrorContainer,
              ),
              iconSize: 20.0,
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
