import 'package:flutter/material.dart';

import 'loading_indicator.dart';

/// Button style variant enum.
enum ButtonVariant {
  /// Filled button (primary action).
  primary,

  /// Secondary button with outline.
  secondary,

  /// Outlined button.
  outlined,

  /// Text button (tertiary action).
  text;
}

/// Custom button widget with loading states and variants.
///
/// Provides consistent button styling across the app with support for
/// loading states, disabled states, and multiple style variants.
class CustomButton extends StatelessWidget {
  /// Creates a custom button.
  const CustomButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.variant = ButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  /// Button press callback (null disables button).
  final VoidCallback? onPressed;

  /// Button child widget (usually Text).
  final Widget child;

  /// Button style variant.
  final ButtonVariant variant;

  /// Loading state (shows spinner, disables button).
  final bool isLoading;

  /// Full width button flag.
  final bool isFullWidth;

  /// Optional leading icon.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    Widget buttonChild = isLoading
        ? const SmallLoadingIndicator(color: Colors.white)
        : child;

    if (icon != null && !isLoading) {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          icon!,
          const SizedBox(width: 8.0),
          child,
        ],
      );
    }

    Widget button;

    switch (variant) {
      case ButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
      case ButtonVariant.secondary:
        button = FilledButton.tonal(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
      case ButtonVariant.outlined:
        button = OutlinedButton(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
      case ButtonVariant.text:
        button = TextButton(
          onPressed: isDisabled ? null : onPressed,
          child: buttonChild,
        );
    }

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        child: button,
      );
    }

    return button;
  }
}

/// Icon button with loading state.
class CustomIconButton extends StatelessWidget {
  /// Creates a custom icon button.
  const CustomIconButton({
    required this.icon,
    required this.onPressed,
    super.key,
    this.tooltip,
    this.isLoading = false,
  });

  /// Button icon.
  final IconData icon;

  /// Button press callback (null disables button).
  final VoidCallback? onPressed;

  /// Optional tooltip.
  final String? tooltip;

  /// Loading state (shows spinner, disables button).
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    final Widget child = isLoading
        ? const SizedBox(
            width: 24.0,
            height: 24.0,
            child: SmallLoadingIndicator(),
          )
        : Icon(icon);

    return IconButton(
      onPressed: isDisabled ? null : onPressed,
      icon: child,
      tooltip: tooltip,
    );
  }
}

/// Floating action button with loading state.
class CustomFAB extends StatelessWidget {
  /// Creates a custom floating action button.
  const CustomFAB({
    required this.icon,
    required this.onPressed,
    super.key,
    this.label,
    this.isLoading = false,
  });

  /// FAB icon.
  final IconData icon;

  /// FAB press callback (null disables FAB).
  final VoidCallback? onPressed;

  /// Optional label for extended FAB.
  final String? label;

  /// Loading state (shows spinner, disables FAB).
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null || isLoading;

    final Widget iconWidget = isLoading
        ? const SizedBox(
            width: 24.0,
            height: 24.0,
            child: SmallLoadingIndicator(color: Colors.white),
          )
        : Icon(icon);

    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: isDisabled ? null : onPressed,
        icon: iconWidget,
        label: Text(label!),
      );
    }

    return FloatingActionButton(
      onPressed: isDisabled ? null : onPressed,
      child: iconWidget,
    );
  }
}
