import 'package:flutter/material.dart';

import '../../../../core/models/product_variant.dart';
import '../../../../core/utils/formatters.dart';

/// Variant selector widget for choosing product variants.
class VariantSelector extends StatelessWidget {
  const VariantSelector({
    required this.variants,
    required this.selectedVariant,
    required this.onVariantSelected,
    super.key,
  });

  final List<ProductVariant> variants;
  final ProductVariant? selectedVariant;
  final ValueChanged<ProductVariant> onVariantSelected;

  @override
  Widget build(BuildContext context) {
    if (variants.isEmpty) {
      return const SizedBox.shrink();
    }

    // Group variants by attribute type
    final variantsByAttribute = <String, List<ProductVariant>>{};
    for (final variant in variants) {
      for (final entry in variant.attributes.entries) {
        final key = entry.key;
        variantsByAttribute.putIfAbsent(key, () => []);
        if (!variantsByAttribute[key]!.contains(variant)) {
          variantsByAttribute[key]!.add(variant);
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chọn phiên bản',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12.0),

        // Show variants in a list
        ...variants.map((variant) {
          final isSelected = selectedVariant?.id == variant.id;
          final isAvailable = variant.isActive && variant.isInStock;

          return Card(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: InkWell(
              onTap: isAvailable ? () => onVariantSelected(variant) : null,
              borderRadius: BorderRadius.circular(12.0),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    // Radio indicator
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(width: 12.0),

                    // Variant info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatVariantName(variant),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                          ),
                          const SizedBox(height: 4.0),
                          Row(
                            children: [
                              Text(
                                formatVND(variant.price),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                isAvailable
                                    ? 'Còn ${variant.stock}'
                                    : 'Hết hàng',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isAvailable
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                          : Colors.red,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatVariantName(ProductVariant variant) {
    if (variant.attributes.isEmpty) {
      return variant.sku ?? 'Phiên bản ${variant.id.substring(0, 8)}';
    }
    return variant.attributes.values.join(' • ');
  }
}
