import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/rating.dart';
import '../services/api_client.dart';
import '../services/rating_service.dart';
import '../theme/app_colors.dart';

/// Prikaz ocjena i komentara jedne aktivnosti, dostupan organizatoru/adminu
/// direktno iz pregleda aktivnosti. Koristi postojeći
/// GET /api/Ratings/activity/{activityId} endpoint (isti koji koristi i
/// mobilna aplikacija na detaljima aktivnosti) - bez novog odvojenog modula.
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
      child: SizedBox(
        width: 560,
        height: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ocjene i komentari — ${widget.activityName}',
                      style: const TextStyle(
                        fontSize: 18,
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
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<Rating>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Greška pri učitavanju ocjena.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () =>
                                  setState(() => _future = _load()),
                              child: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      );
                    }

                    final ratings = snapshot.data!;
                    if (ratings.isEmpty) {
                      return const Center(
                        child: Text(
                          'Za ovu aktivnost još nema ocjena.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    final average =
                        ratings.map((r) => r.score).reduce((a, b) => a + b) /
                        ratings.length;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${average.toStringAsFixed(1)} (${ratings.length} ocjena)',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: ListView.separated(
                            itemCount: ratings.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 16),
                            itemBuilder: (context, index) =>
                                _buildRatingItem(ratings[index]),
                          ),
                        ),
                      ],
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

  Widget _buildRatingItem(Rating rating) {
    return Column(
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
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          DateFormat('dd.MM.yyyy.').format(rating.createdAt),
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        if (rating.comment != null && rating.comment!.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(rating.comment!),
        ],
      ],
    );
  }
}
