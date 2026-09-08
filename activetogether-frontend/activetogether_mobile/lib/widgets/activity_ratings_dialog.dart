import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/rating.dart';
import '../services/api_client.dart';
import '../services/rating_service.dart';

/// Prikaz ocjena i komentara jedne aktivnosti, dostupan organizatoru direktno
/// iz "Moje aktivnosti". Koristi postojeći GET /api/Ratings/activity/{id}
/// endpoint (isti koji koristi i ActivityDetailScreen) - bez novog odvojenog
/// modula, samo drugi ulaz u isti podatak.
class ActivityRatingsDialog extends StatefulWidget {
  final int activityId;
  final String activityName;

  const ActivityRatingsDialog({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  State<ActivityRatingsDialog> createState() => _ActivityRatingsDialogState();
}

class _ActivityRatingsDialogState extends State<ActivityRatingsDialog> {
  late Future<List<Rating>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Rating>> _load() {
    final apiClient = context.read<ApiClient>();
    return RatingService(apiClient).getForActivity(widget.activityId);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ocjene — ${widget.activityName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              Flexible(
                child: FutureBuilder<List<Rating>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Greška pri učitavanju ocjena.'),
                      );
                    }

                    final ratings = snapshot.data!;
                    if (ratings.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('Za ovu aktivnost još nema ocjena.'),
                      );
                    }

                    final average =
                        ratings.map((r) => r.score).reduce((a, b) => a + b) /
                        ratings.length;

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${average.toStringAsFixed(1)} (${ratings.length} ocjena)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          for (final rating in ratings) _buildItem(rating),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(Rating rating) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rating.userName.isEmpty ? 'Korisnik' : rating.userName,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.score ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          Text(
            DateFormat('dd.MM.yyyy.').format(rating.createdAt),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          if (rating.comment != null && rating.comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(rating.comment!),
          ],
        ],
      ),
    );
  }
}
