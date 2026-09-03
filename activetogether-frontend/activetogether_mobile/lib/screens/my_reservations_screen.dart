import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reservation.dart';
import '../services/api_client.dart';
import '../services/reservation_service.dart';
import '../theme/app_colors.dart';
import 'activity_detail_screen.dart';
import 'package:dio/dio.dart';
import '../services/rating_service.dart';

class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reservationsFuture = _load();
  }

  Future<List<Reservation>> _load() {
    final apiClient = context.read<ApiClient>();
    return ReservationService(apiClient).getMy();
  }

  Future<void> _refresh() async {
    setState(() {
      _reservationsFuture = _load();
    });
    await _reservationsFuture;
  }

  Future<void> _confirmCancel(Reservation reservation) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazivanje rezervacije'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Da li sigurno želiš otkazati rezervaciju za "${reservation.activityName}"?',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog (opciono)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Otkaži rezervaciju',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiClient = context.read<ApiClient>();
      await ReservationService(
        apiClient,
      ).cancel(reservation.id, reason: reasonController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rezervacija je otkazana.')));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Otkazivanje nije uspjelo.')),
      );
    }
  }

  Future<void> _rateActivity(Reservation reservation) async {
    int selectedScore = 5;
    final commentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Ocijeni "${reservation.activityName}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= selectedScore
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => selectedScore = starIndex),
                  );
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commentController,
                decoration: const InputDecoration(
                  labelText: 'Komentar (opciono)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Odustani'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Pošalji ocjenu'),
            ),
          ],
        ),
      ),
    );

    if (result != true) return;

    try {
      final apiClient = context.read<ApiClient>();
      await RatingService(apiClient).create(
        reservationId: reservation.id,
        score: selectedScore,
        comment: commentController.text.trim().isEmpty
            ? null
            : commentController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hvala na ocjeni!')));
    } catch (e) {
      String message = 'Slanje ocjene nije uspjelo.';
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
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Moje aktivnosti'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF1E3A8A),
          indicatorColor: const Color(0xFF1E3A8A),
          tabs: const [
            Tab(text: 'Nadolazeće'),
            Tab(text: 'Prošle'),
          ],
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Reservation>>(
          future: _reservationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            }

            final all = snapshot.data ?? [];
            final now = DateTime.now();
            final upcoming =
                all.where((r) => r.activityDateTime.isAfter(now)).toList()
                  ..sort(
                    (a, b) => a.activityDateTime.compareTo(b.activityDateTime),
                  );
            final past =
                all.where((r) => !r.activityDateTime.isAfter(now)).toList()
                  ..sort(
                    (a, b) => b.activityDateTime.compareTo(a.activityDateTime),
                  );

            return TabBarView(
              controller: _tabController,
              children: [_buildList(upcoming), _buildList(past)],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<Reservation> reservations) {
    if (reservations.isEmpty) {
      return const Center(child: Text('Nema rezervacija.'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservations.length,
        itemBuilder: (context, index) {
          final reservation = reservations[index];
          final dateLabel = DateFormat(
            'dd.MM.yyyy. HH:mm',
          ).format(reservation.activityDateTime);
          final canCancel =
              reservation.status == 'Confirmed' &&
              reservation.activityDateTime.isAfter(DateTime.now());

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event_note,
                        size: 22,
                        color: Color(0xFF1E3A8A),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.activityName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              dateLabel,
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
                          color: AppColors.reservationStatusColor(
                            reservation.status,
                          ).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppColors.reservationStatusLabel(reservation.status),
                          style: TextStyle(
                            color: AppColors.reservationStatusColor(
                              reservation.status,
                            ),
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (reservation.payment != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Plaćeno: ${reservation.payment!.amount.toStringAsFixed(2)} EUR',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ActivityDetailScreen(
                                  activityId: reservation.activityId,
                                ),
                              ),
                            );
                          },
                          child: const Text('Detalji'),
                        ),
                      ),
                      if (canCancel) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _confirmCancel(reservation),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            child: const Text('Otkaži'),
                          ),
                        ),
                      ],
                      if (reservation.status == 'Completed') ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _rateActivity(reservation),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade800,
                            ),
                            child: const Text('Ocijeni'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
