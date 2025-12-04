import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Category chip widget for filtering products.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.iconUrl,
  });

  final String label;
  final String? iconUrl;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (iconUrl != null) ...[
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: iconUrl!,
                    width: 24.0,
                    height: 24.0,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 24.0,
                      height: 24.0,
                      color: colorScheme.surfaceContainerHighest,
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.category_outlined,
                      size: 24.0,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
              ],
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurface,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
