import 'package:flutter/material.dart';

/// Loading indicator widget with centered CircularProgressIndicator.
///
/// Reusable component for displaying loading states throughout the app.
class LoadingIndicator extends StatelessWidget {
  /// Creates a loading indicator.
  const LoadingIndicator({
    super.key,
    this.size = 40.0,
    this.color,
    this.strokeWidth = 4.0,
  });

  /// Size of the loading indicator.
  final double size;

  /// Color of the loading indicator (defaults to theme primary color).
  final Color? color;

  /// Stroke width of the circular indicator.
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: AlwaysStoppedAnimation<Color>(
            color ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

/// Small loading indicator for inline use (e.g., inside buttons).
class SmallLoadingIndicator extends StatelessWidget {
  /// Creates a small loading indicator.
  const SmallLoadingIndicator({
    super.key,
    this.color,
  });

  /// Color of the loading indicator (defaults to theme primary color).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20.0,
      height: 20.0,
      child: CircularProgressIndicator(
        strokeWidth: 2.0,
        valueColor: AlwaysStoppedAnimation<Color>(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

/// Full-screen loading overlay.
class LoadingOverlay extends StatelessWidget {
  /// Creates a full-screen loading overlay.
  const LoadingOverlay({
    super.key,
    this.message,
  });

  /// Optional message to display below the loading indicator.
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const LoadingIndicator(),
                if (message != null) ...<Widget>[
                  const SizedBox(height: 16.0),
                  Text(
                    message!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
