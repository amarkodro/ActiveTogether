import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/activity.dart';
import '../theme/app_colors.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final String? reason;
  final VoidCallback? onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    this.reason,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('dd.MM.yyyy. HH:mm').format(activity.dateTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    AppColors.categoryEmoji(activity.categoryName),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$dateLabel • ${activity.locationName}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: activity.isFree
                          ? AppColors.success.withValues(alpha: 0.15)
                          : AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      activity.isFree
                          ? 'Besplatno'
                          : '${activity.price?.toStringAsFixed(0)} KM',
                      style: TextStyle(
                        color: activity.isFree
                            ? AppColors.success
                            : AppColors.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (activity.averageRating != null) ...[
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      '${activity.averageRating!.toStringAsFixed(1)} (${activity.ratingCount})',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(
                    Icons.people_outline,
                    size: 16,
                    color: AppColors.capacityColor(activity.fillRatio),
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '${activity.spotsLeft} mjesta preostalo',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.capacityColor(activity.fillRatio),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: activity.fillRatio.clamp(0, 1),
                  minHeight: 5,
                  backgroundColor: Colors.grey.shade200,
                  color: AppColors.capacityColor(activity.fillRatio),
                ),
              ),

              if (reason != null && reason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reason!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
