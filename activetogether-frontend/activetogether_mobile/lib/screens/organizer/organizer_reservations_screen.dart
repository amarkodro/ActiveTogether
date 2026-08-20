import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/reservation.dart';
import '../../services/api_client.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_colors.dart';

class OrganizerReservationsScreen extends StatefulWidget {
  const OrganizerReservationsScreen({super.key});

  @override
  State<OrganizerReservationsScreen> createState() =>
      _OrganizerReservationsScreenState();
}

class _OrganizerReservationsScreenState
    extends State<OrganizerReservationsScreen> {
  late Future<List<Reservation>> _reservationsFuture;

  @override
  void initState() {
    super.initState();
    _reservationsFuture = _load();
  }

  Future<List<Reservation>> _load() {
    final apiClient = context.read<ApiClient>();
    return ReservationService(apiClient).getForMyActivities();
  }

  Future<void> _refresh() async {
    setState(() {
      _reservationsFuture = _load();
    });
    await _reservationsFuture;
  }

  Future<void> _confirm(Reservation reservation) async {
    try {
      final apiClient = context.read<ApiClient>();
      await ReservationService(apiClient).confirm(reservation.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rezervacija je potvrđena.')),
      );
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Potvrda nije uspjela.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Rezervacije'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
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

            final reservations = (snapshot.data ?? [])
              ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

            if (reservations.isEmpty) {
              return const Center(
                child: Text('Nema rezervacija za tvoje aktivnosti.'),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final r = reservations[index];
                  final dateLabel = DateFormat(
                    'dd.MM.yyyy. HH:mm',
                  ).format(r.createdAt);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r.activityName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${r.userName} • $dateLabel',
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
                                    r.status,
                                  ).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  AppColors.reservationStatusLabel(r.status),
                                  style: TextStyle(
                                    color: AppColors.reservationStatusColor(
                                      r.status,
                                    ),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (r.status == 'Pending') ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => _confirm(r),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Potvrdi'),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
