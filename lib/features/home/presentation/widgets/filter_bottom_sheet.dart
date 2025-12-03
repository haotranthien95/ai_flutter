import 'package:flutter/material.dart';

import '../../../../core/models/product.dart';
import '../../../../core/utils/formatters.dart';

/// Filter bottom sheet for product filtering.
class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({
    super.key,
    this.currentFilters,
  });

  final Map<String, dynamic>? currentFilters;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _priceRange;
  late double _minRating;
  ProductCondition? _condition;

  // Price range constants (in VND)
  static const double _minPrice = 0;
  static const double _maxPrice = 50000000; // 50 million VND
  static const double _priceStep = 100000; // 100k VND

  @override
  void initState() {
    super.initState();

    // Initialize from current filters
    final filters = widget.currentFilters ?? {};
    final minPrice = (filters['minPrice'] as num?)?.toDouble() ?? _minPrice;
    final maxPrice = (filters['maxPrice'] as num?)?.toDouble() ?? _maxPrice;
    _priceRange = RangeValues(minPrice, maxPrice);
    _minRating = (filters['rating'] as num?)?.toDouble() ?? 0;
    
    final conditionStr = filters['condition'] as String?;
    if (conditionStr != null) {
      _condition = ProductCondition.values.firstWhere(
        (c) => c.name == conditionStr,
        orElse: () => ProductCondition.newProduct,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  'Bộ lọc',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Xóa tất cả'),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(),

          // Price range filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Khoảng giá',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Row(
                  children: [
                    Text(
                      formatVND(_priceRange.start.toInt()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      formatVND(_priceRange.end.toInt()),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
                RangeSlider(
                  values: _priceRange,
                  min: _minPrice,
                  max: _maxPrice,
                  divisions: (_maxPrice / _priceStep).round(),
                  onChanged: (values) {
                    setState(() {
                      _priceRange = values;
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(),

          // Rating filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá tối thiểu',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: [
                    for (var rating = 1; rating <= 5; rating++)
                      ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.star,
                              size: 16.0,
                              color: _minRating >= rating
                                  ? Colors.amber[700]
                                  : Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(width: 4.0),
                            Text('$rating+'),
                          ],
                        ),
                        selected: _minRating >= rating,
                        onSelected: (selected) {
                          setState(() {
                            _minRating = selected ? rating.toDouble() : 0;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(),

          // Condition filter
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tình trạng',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  children: [
                    for (var condition in ProductCondition.values)
                      ChoiceChip(
                        label: Text(condition.displayName),
                        selected: _condition == condition,
                        onSelected: (selected) {
                          setState(() {
                            _condition = selected ? condition : null;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Apply button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _applyFilters,
                child: const Text('Áp dụng'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _priceRange = const RangeValues(_minPrice, _maxPrice);
      _minRating = 0;
      _condition = null;
    });
  }

  void _applyFilters() {
    final filters = <String, dynamic>{};

    // Add price range if not default
    if (_priceRange.start > _minPrice) {
      filters['minPrice'] = _priceRange.start.toInt();
    }
    if (_priceRange.end < _maxPrice) {
      filters['maxPrice'] = _priceRange.end.toInt();
    }

    // Add rating if selected
    if (_minRating > 0) {
      filters['rating'] = _minRating.toInt();
    }

    // Add condition if selected
    if (_condition != null) {
      filters['condition'] = _condition!.name;
    }

    Navigator.pop(context, filters.isEmpty ? null : filters);
  }
}
