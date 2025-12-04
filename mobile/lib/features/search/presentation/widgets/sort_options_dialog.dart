import 'package:flutter/material.dart';

/// Sort options dialog for product search/browse.
class SortOptionsDialog extends StatelessWidget {
  const SortOptionsDialog({
    required this.currentSortBy,
    super.key,
  });

  final String currentSortBy;

  @override
  Widget build(BuildContext context) {
    final options = [
      ('relevance', 'Liên quan', Icons.featured_play_list_outlined),
      ('newest', 'Mới nhất', Icons.new_releases_outlined),
      ('best_selling', 'Bán chạy nhất', Icons.trending_up),
      ('price_low_high', 'Giá: Thấp đến cao', Icons.arrow_upward),
      ('price_high_low', 'Giá: Cao đến thấp', Icons.arrow_downward),
      ('top_rated', 'Đánh giá cao nhất', Icons.star_outline),
    ];

    return AlertDialog(
      title: const Text('Sắp xếp theo'),
      contentPadding: EdgeInsets.zero,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final (value, label, icon) = option;
          final isSelected = currentSortBy == value;

          return RadioListTile<String>(
            value: value,
            groupValue: currentSortBy,
            onChanged: (value) {
              Navigator.pop(context, value);
            },
            title: Row(
              children: [
                Icon(icon, size: 20.0),
                const SizedBox(width: 12.0),
                Text(label),
              ],
            ),
            selected: isSelected,
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
