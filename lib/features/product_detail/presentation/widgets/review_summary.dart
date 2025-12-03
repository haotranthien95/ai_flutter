import 'package:flutter/material.dart';

/// Review summary widget showing rating distribution.
class ReviewSummary extends StatelessWidget {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    super.key,
    this.ratingCounts,
  });

  final double averageRating;
  final int totalReviews;
  final Map<int, int>? ratingCounts;

  @override
  Widget build(BuildContext context) {
    // Mock rating distribution if not provided
    final distribution = ratingCounts ??
        {
          5: (totalReviews * 0.6).round(),
          4: (totalReviews * 0.2).round(),
          3: (totalReviews * 0.1).round(),
          2: (totalReviews * 0.05).round(),
          1: (totalReviews * 0.05).round(),
        };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Đánh giá sản phẩm',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16.0),

        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Average rating
            Column(
              children: [
                Text(
                  averageRating.toStringAsFixed(1),
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4.0),
                Row(
                  children: List.generate(
                    5,
                    (index) => Icon(
                      index < averageRating.round()
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber[700],
                      size: 20.0,
                    ),
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  '$totalReviews đánh giá',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),

            const SizedBox(width: 24.0),

            // Rating distribution
            Expanded(
              child: Column(
                children: List.generate(5, (index) {
                  final rating = 5 - index;
                  final count = distribution[rating] ?? 0;
                  final percentage = totalReviews > 0
                      ? (count / totalReviews * 100).round()
                      : 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20.0,
                          child: Text(
                            '$rating',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                        Icon(
                          Icons.star,
                          size: 16.0,
                          color: Colors.amber[700],
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4.0),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.amber[700]!,
                              ),
                              minHeight: 8.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        SizedBox(
                          width: 40.0,
                          child: Text(
                            '$percentage%',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
