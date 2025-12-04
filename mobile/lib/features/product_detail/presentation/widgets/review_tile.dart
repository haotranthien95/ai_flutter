import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/models/review.dart';
import '../../../../core/utils/formatters.dart';

/// Review tile widget for displaying product reviews.
class ReviewTile extends StatelessWidget {
  const ReviewTile({
    required this.review,
    super.key,
  });

  final Review review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Reviewer info
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20.0,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12.0),

                // Name and verified badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'User ${review.userId.substring(0, 8)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (review.isVerifiedPurchase) ...[
                            const SizedBox(width: 4.0),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6.0,
                                vertical: 2.0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.verified,
                                    size: 12.0,
                                    color: Colors.green.shade700,
                                  ),
                                  const SizedBox(width: 2.0),
                                  Text(
                                    'Đã mua',
                                    style: TextStyle(
                                      fontSize: 10.0,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        formatDateTime(review.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8.0),

            // Rating stars
            Row(
              children: List.generate(
                5,
                (index) => Icon(
                  index < review.rating ? Icons.star : Icons.star_border,
                  color: Colors.amber[700],
                  size: 18.0,
                ),
              ),
            ),

            const SizedBox(height: 8.0),

            // Review text
            Text(
              review.content ?? 'No comment provided',
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Review images
            if (review.images != null && review.images!.isNotEmpty) ...[
              const SizedBox(height: 12.0),
              SizedBox(
                height: 80.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: review.images!.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: CachedNetworkImage(
                          imageUrl: review.images![index],
                          width: 80.0,
                          height: 80.0,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child:
                                const Icon(Icons.image_not_supported_outlined),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
