import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/cart/presentation/providers/cart_provider.dart';

/// Animated cart icon with badge showing item count
class AnimatedCartBadge extends ConsumerWidget {
  /// Creates animated cart badge
  const AnimatedCartBadge({
    required this.onTap,
    super.key,
  });

  /// Tap callback for navigation to cart
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartProvider);

    return IconButton(
      icon: cartState.when(
        data: (cart) {
          final itemCount = cart.itemCount;

          return Badge(
            label: Text('$itemCount'),
            isLabelVisible: itemCount > 0,
            child: const Icon(Icons.shopping_cart_outlined),
          );
        },
        loading: () => const Icon(Icons.shopping_cart_outlined),
        error: (_, __) => const Icon(Icons.shopping_cart_outlined),
      ),
      onPressed: onTap,
      tooltip: 'Giỏ hàng',
    );
  }
}

/// Success checkmark animation widget
class SuccessCheckmark extends StatefulWidget {
  /// Creates success checkmark
  const SuccessCheckmark({
    required this.size,
    super.key,
  });

  /// Size of the checkmark
  final double size;

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _checkAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: AnimatedBuilder(
          animation: _checkAnimation,
          builder: (context, child) {
            return CustomPaint(
              painter: _CheckmarkPainter(
                progress: _checkAnimation.value,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Custom painter for animated checkmark
class _CheckmarkPainter extends CustomPainter {
  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final checkPath = Path();

    // Short arm of check
    final shortArmStart = Offset(
      center.dx - size.width * 0.2,
      center.dy,
    );
    final shortArmEnd = Offset(
      center.dx - size.width * 0.05,
      center.dy + size.height * 0.15,
    );

    // Long arm of check
    final longArmEnd = Offset(
      center.dx + size.width * 0.25,
      center.dy - size.height * 0.2,
    );

    if (progress < 0.5) {
      // Draw short arm
      final shortProgress = progress * 2;
      checkPath.moveTo(shortArmStart.dx, shortArmStart.dy);
      checkPath.lineTo(
        shortArmStart.dx + (shortArmEnd.dx - shortArmStart.dx) * shortProgress,
        shortArmStart.dy + (shortArmEnd.dy - shortArmStart.dy) * shortProgress,
      );
    } else {
      // Draw complete short arm and partial long arm
      final longProgress = (progress - 0.5) * 2;
      checkPath.moveTo(shortArmStart.dx, shortArmStart.dy);
      checkPath.lineTo(shortArmEnd.dx, shortArmEnd.dy);
      checkPath.lineTo(
        shortArmEnd.dx + (longArmEnd.dx - shortArmEnd.dx) * longProgress,
        shortArmEnd.dy + (longArmEnd.dy - shortArmEnd.dy) * longProgress,
      );
    }

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Dialog with success animation for order confirmation
class SuccessDialog extends StatelessWidget {
  /// Creates success dialog
  const SuccessDialog({
    required this.title,
    required this.message,
    this.actionText = 'OK',
    this.onAction,
    super.key,
  });

  /// Dialog title
  final String title;

  /// Success message
  final String message;

  /// Action button text
  final String actionText;

  /// Action button callback
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SuccessCheckmark(size: 80),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onAction ?? () => Navigator.of(context).pop(),
                child: Text(actionText),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show success dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    String actionText = 'OK',
    VoidCallback? onAction,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => SuccessDialog(
        title: title,
        message: message,
        actionText: actionText,
        onAction: onAction,
      ),
    );
  }
}
