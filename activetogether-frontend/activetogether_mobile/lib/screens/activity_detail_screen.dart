import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../models/activity.dart';
import '../services/activity_service.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../services/reservation_service.dart';
import '../theme/app_colors.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../services/payment_service.dart';

class ActivityDetailScreen extends StatefulWidget {
  final int activityId;

  const ActivityDetailScreen({super.key, required this.activityId});

  @override
  State<ActivityDetailScreen> createState() => _ActivityDetailScreenState();
}

class _ActivityDetailScreenState extends State<ActivityDetailScreen> {
  late Future<Activity> _activityFuture;
  bool _isReserving = false;
  String? _myReservationStatus;
  bool _isFavorite = false;
  bool _favoriteBusy = false;

  @override
  void initState() {
    super.initState();
    _activityFuture = _load();
  }

  Future<Activity> _load() async {
    final apiClient = context.read<ApiClient>();
    final activity = await ActivityService(
      apiClient,
    ).getById(widget.activityId);
    try {
      final myReservations = await ReservationService(apiClient).getMy();
      final existing = myReservations.where(
        (r) => r.activityId == widget.activityId && r.status != 'Cancelled',
      );
      _myReservationStatus = existing.isNotEmpty ? existing.first.status : null;
    } catch (_) {
      _myReservationStatus = null;
    }
    try {
      _isFavorite = await FavoriteService(
        apiClient,
      ).getStatus(widget.activityId);
    } catch (_) {
      _isFavorite = false;
    }
    return activity;
  }

  Future<void> _toggleFavorite(int activityId) async {
    setState(() => _favoriteBusy = true);
    final apiClient = context.read<ApiClient>();
    try {
      if (_isFavorite) {
        await FavoriteService(apiClient).remove(activityId);
      } else {
        await FavoriteService(apiClient).add(activityId);
      }
      if (mounted) setState(() => _isFavorite = !_isFavorite);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Došlo je do greške. Pokušajte ponovo.')),
      );
    } finally {
      if (mounted) setState(() => _favoriteBusy = false);
    }
  }

  Future<void> _openInMaps(Activity activity) async {
    final lat = activity.locationLatitude;
    final lng = activity.locationLongitude;
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nije moguće otvoriti mape.')),
      );
    }
  }

  Future<void> _reserve(Activity activity) async {
    setState(() => _isReserving = true);
    final apiClient = context.read<ApiClient>();
    int? createdReservationId;
    try {
      final result = await ReservationService(apiClient).create(activity.id);
      createdReservationId = result['id'] as int;

      if (!activity.isFree) {
        final payment = result['payment'] as Map<String, dynamic>?;
        final clientSecret = payment?['clientSecret'] as String?;

        if (clientSecret == null) {
          throw Exception('Nije moguće pokrenuti plaćanje.');
        }

        await Stripe.instance.initPaymentSheet(
          paymentSheetParameters: SetupPaymentSheetParameters(
            paymentIntentClientSecret: clientSecret,
            merchantDisplayName: 'ActiveTogether',
          ),
        );

        await Stripe.instance.presentPaymentSheet();

        await PaymentService(apiClient).confirm(createdReservationId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plaćanje uspješno! Rezervacija je kreirana.'),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rezervacija je poslana. Čeka potvrdu organizatora.'),
          ),
        );
      }

      setState(() {
        _activityFuture = _load();
      });
    } on StripeException catch (e) {
      if (createdReservationId != null) {
        try {
          await ReservationService(
            apiClient,
          ).cancel(createdReservationId, reason: 'Plaćanje otkazano');
        } catch (_) {}
      }
      if (!mounted) return;
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plaćanje otkazano. Rezervacija nije napravljena.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Plaćanje nije uspjelo: ${e.error.localizedMessage ?? e.error.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (createdReservationId != null) {
        try {
          await ReservationService(
            apiClient,
          ).cancel(createdReservationId, reason: 'Greška pri plaćanju');
        } catch (_) {}
      }
      String message = 'Rezervacija nije uspjela.';
      if (e is DioException) {
        final data = e.response?.data;
        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _isReserving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Activity>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Greška: ${snapshot.error}'));
          }

          final activity = snapshot.data!;
          final dateLabel = DateFormat(
            'dd.MM.yyyy. HH:mm',
          ).format(activity.dateTime);
          final categoryColor = AppColors.categoryColor(activity.categoryName);

          final resolvedImageUrl = ApiConfig.resolveImageUrl(
            activity.imageUrl,
          );

          return SafeArea(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  color: categoryColor.withValues(alpha: 0.12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: _favoriteBusy
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: _isFavorite ? Colors.red : null,
                                  ),
                            onPressed: _favoriteBusy
                                ? null
                                : () => _toggleFavorite(activity.id),
                          ),
                        ],
                      ),
                      if (resolvedImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            resolvedImageUrl,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Center(
                              child: Text(
                                AppColors.categoryEmoji(activity.categoryName),
                                style: const TextStyle(fontSize: 56),
                              ),
                            ),
                          ),
                        )
                      else
                        Center(
                          child: Text(
                            AppColors.categoryEmoji(activity.categoryName),
                            style: const TextStyle(fontSize: 56),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        activity.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activity.organizerName,
                        style: const TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow(Icons.calendar_today, dateLabel),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${activity.locationName}, ${activity.locationAddress}',
                                  style: const TextStyle(color: Colors.black87),
                                ),
                              ),
                              if (activity.locationLatitude != 0 ||
                                  activity.locationLongitude != 0)
                                TextButton.icon(
                                  onPressed: () => _openInMaps(activity),
                                  icon: const Icon(Icons.directions, size: 18),
                                  label: const Text('Navigiraj'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        _infoRow(
                          Icons.people_outline,
                          '${activity.reservedCount}/${activity.capacity} učesnika',
                        ),
                        _infoRow(
                          Icons.payments_outlined,
                          activity.isFree
                              ? 'Besplatno'
                              : '${activity.price?.toStringAsFixed(2)} EUR',
                          valueColor: activity.isFree
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Opis',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activity.description,
                          style: const TextStyle(color: Colors.black87),
                        ),
                        const SizedBox(height: 16),
                        if (activity.averageRating != null) ...[
                          const Text(
                            'Ocjena',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${activity.averageRating!.toStringAsFixed(1)} (${activity.ratingCount} ocjena)',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: activity.fillRatio.clamp(0, 1),
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: AppColors.capacityColor(activity.fillRatio),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: FutureBuilder<Activity>(
        future: _activityFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();
          final activity = snapshot.data!;
          final full = activity.spotsLeft <= 0;
          final alreadyReserved = _myReservationStatus != null;

          String label;
          if (alreadyReserved) {
            switch (_myReservationStatus) {
              case 'Confirmed':
                label = 'REZERVACIJA POTVRĐENA';
                break;
              case 'Completed':
                label = 'AKTIVNOST ZAVRŠENA';
                break;
              default:
                label = 'REZERVACIJA NA ČEKANJU';
            }
          } else if (full) {
            label = 'POPUNJENO';
          } else {
            label = activity.isFree ? 'REZERVIŠI' : 'PLATI I REZERVIŠI';
          }

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isReserving || full || alreadyReserved)
                      ? null
                      : () => _reserve(activity),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                  child: _isReserving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(label),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueColor != null ? FontWeight.w600 : null,
            ),
          ),
        ],
      ),
    );
  }
}
