import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/reservation.dart';
import '../../services/api_client.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_colors.dart';

class ParticipantsScreen extends StatefulWidget {
  final int activityId;
  final String activityName;

  const ParticipantsScreen({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  late Future<List<Reservation>> _participantsFuture;
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _participantsFuture = _load();
  }

  Future<List<Reservation>> _load() {
    final apiClient = context.read<ApiClient>();
    return ReservationService(apiClient).getForActivity(widget.activityId);
  }

  Future<void> _refresh() async {
    setState(() {
      _participantsFuture = _load();
    });
    await _participantsFuture;
  }

  Future<void> _confirm(Reservation r) async {
    try {
      final apiClient = context.read<ApiClient>();
      await ReservationService(apiClient).confirm(r.id);
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Potvrda nije uspjela.')));
    }
  }

  Future<void> _reject(Reservation r) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkaži rezervaciju'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Otkazujete rezervaciju korisnika ${r.userName}. Razlog je obavezan.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja',
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
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(context).pop(true);
            },
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
      ).cancel(r.id, reason: reasonController.text.trim());
      if (!mounted) return;
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Otkazivanje nije uspjelo.')),
      );
    }
  }

  Future<void> _confirmAll(List<Reservation> pending) async {
    for (final r in pending) {
      try {
        final apiClient = context.read<ApiClient>();
        await ReservationService(apiClient).confirm(r.id);
      } catch (_) {
        // nastavi sa ostalima i ako jedna ne uspije
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sve rezervacije na čekanju su potvrđene.')),
    );
    _refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: Text('Učesnici — ${widget.activityName}'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Reservation>>(
          future: _participantsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            }

            var participants = snapshot.data ?? [];
            if (_query.isNotEmpty) {
              participants = participants
                  .where(
                    (r) =>
                        r.userName.toLowerCase().contains(_query.toLowerCase()),
                  )
                  .toList();
            }
            final pending = participants
                .where((r) => r.status == 'Pending')
                .toList();

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _query = v),
                    decoration: InputDecoration(
                      hintText: 'Pretraži učesnika po imenu...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: participants.isEmpty
                      ? const Center(child: Text('Nema učesnika.'))
                      : RefreshIndicator(
                          onRefresh: _refresh,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            itemCount: participants.length,
                            itemBuilder: (context, index) {
                              final r = participants[index];
                              final dateLabel = DateFormat(
                                'dd.MM.yyyy.',
                              ).format(r.createdAt);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    backgroundImage:
                                        ApiConfig.resolveImageUrl(
                                              r.userProfileImageUrl,
                                            ) !=
                                            null
                                        ? NetworkImage(
                                            ApiConfig.resolveImageUrl(
                                              r.userProfileImageUrl,
                                            )!,
                                          )
                                        : null,
                                    child:
                                        ApiConfig.resolveImageUrl(
                                              r.userProfileImageUrl,
                                            ) !=
                                            null
                                        ? null
                                        : Text(
                                            r.userName.isNotEmpty
                                                ? r.userName[0].toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                  ),
                                  title: Text(r.userName),
                                  subtitle: Text('Rezervisano: $dateLabel'),
                                  trailing: r.status == 'Pending'
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.check_circle,
                                                color: Colors.green,
                                              ),
                                              onPressed: () => _confirm(r),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.cancel,
                                                color: r.activityDateTime
                                                        .isAfter(
                                                          DateTime.now(),
                                                        )
                                                    ? Colors.red
                                                    : Colors.grey,
                                              ),
                                              onPressed:
                                                  r.activityDateTime.isAfter(
                                                    DateTime.now(),
                                                  )
                                                  ? () => _reject(r)
                                                  : null,
                                            ),
                                          ],
                                        )
                                      : Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                AppColors.reservationStatusColor(
                                                  r.status,
                                                ).withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            AppColors.reservationStatusLabel(
                                              r.status,
                                            ),
                                            style: TextStyle(
                                              color:
                                                  AppColors.reservationStatusColor(
                                                    r.status,
                                                  ),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                ),
                if (pending.length > 1)
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: SizedBox(
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () => _confirmAll(pending),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Potvrdi sve'),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
