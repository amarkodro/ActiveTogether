import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../models/paged_result.dart';
import '../../../models/reservation_item.dart';
import '../../../services/api_client.dart';
import '../../../services/reservation_service.dart';
import '../../../theme/app_colors.dart';
import 'reservation_details_dialog.dart';

/// Prikaz i upravljanje učesnicima (rezervacijama) jedne konkretne aktivnosti,
/// dostupan direktno iz admin pregleda aktivnosti. Koristi postojeći
/// GET /api/Reservations/activity/{activityId} endpoint i iste akcije
/// (Detalji/Potvrdi/Otkaži) koje već postoje na ekranu "Rezervacije".
class ActivityParticipantsDialog extends StatefulWidget {
  final int activityId;
  final String activityName;

  const ActivityParticipantsDialog({
    super.key,
    required this.activityId,
    required this.activityName,
  });

  @override
  State<ActivityParticipantsDialog> createState() =>
      _ActivityParticipantsDialogState();
}

class _ActivityParticipantsDialogState
    extends State<ActivityParticipantsDialog> {
  String? _selectedStatus;
  late Future<PagedResult<ReservationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PagedResult<ReservationItem>> _load() {
    final apiClient = context.read<ApiClient>();
    return ReservationService(apiClient).getForActivity(
      widget.activityId,
      status: _selectedStatus,
      pageSize: 100,
    );
  }

  void _refresh() => setState(() => _future = _load());

  void _showDetails(ReservationItem reservation) {
    showDialog(
      context: context,
      builder: (_) => ReservationDetailsDialog(reservation: reservation),
    );
  }

  Future<void> _confirm(ReservationItem reservation) async {
    final apiClient = context.read<ApiClient>();
    try {
      await ReservationService(apiClient).confirm(reservation.id);
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Došlo je do greške. Pokušajte ponovo.'),
          ),
        );
      }
    }
  }

  Future<void> _cancel(ReservationItem reservation) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otkazivanje rezervacije'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Otkazujete rezervaciju korisnika ${reservation.userName}.'),
                const SizedBox(height: 16),
                const Text(
                  'Razlog otkazivanja',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Razlog otkazivanja je obavezan.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Nazad'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final apiClient = context.read<ApiClient>();
    try {
      await ReservationService(
        apiClient,
      ).cancel(reservation.id, reasonController.text.trim());
      _refresh();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Došlo je do greške. Pokušajte ponovo.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 720,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Učesnici — ${widget.activityName}',
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
              const SizedBox(height: 12),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<String?>(
                  initialValue: _selectedStatus,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Svi statusi'),
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Svi statusi'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Pending',
                      child: Text('Na čekanju'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Confirmed',
                      child: Text('Potvrđeno'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Completed',
                      child: Text('Završeno'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Cancelled',
                      child: Text('Otkazano'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStatus = value);
                    _refresh();
                  },
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<PagedResult<ReservationItem>>(
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
                            const Text('Greška pri učitavanju učesnika.'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: _refresh,
                              child: const Text('Pokušaj ponovo'),
                            ),
                          ],
                        ),
                      );
                    }

                    final items = snapshot.data!.items;
                    if (items.isEmpty) {
                      return const Center(
                        child: Text(
                          'Nema učesnika za odabrani filter.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.separated(
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) =>
                          _buildRow(items[index]),
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

  Widget _buildRow(ReservationItem reservation) {
    final paymentNotCompleted =
        reservation.payment != null &&
        reservation.payment!.status != 'Completed';
    final canConfirm = reservation.status == 'Pending' && !paymentNotCompleted;
    final canCancel =
        (reservation.status == 'Pending' ||
            reservation.status == 'Confirmed') &&
        reservation.activityDateTime.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Rezervisano: ${DateFormat('dd.MM.yyyy.').format(reservation.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.statusColor(
                    reservation.status,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppColors.statusLabel(reservation.status),
                  style: TextStyle(
                    color: AppColors.statusColor(reservation.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  tooltip: 'Detalji',
                  onPressed: () => _showDetails(reservation),
                ),
                IconButton(
                  icon: const Icon(Icons.check_circle_outline, size: 20),
                  color: canConfirm
                      ? AppColors.success
                      : AppColors.textSecondary,
                  tooltip: paymentNotCompleted
                      ? 'Ne može se potvrditi dok uplata nije završena'
                      : 'Potvrdi',
                  onPressed: canConfirm ? () => _confirm(reservation) : null,
                ),
                IconButton(
                  icon: const Icon(Icons.cancel_outlined, size: 20),
                  color: canCancel ? AppColors.danger : AppColors.textSecondary,
                  tooltip: 'Otkaži',
                  onPressed: canCancel ? () => _cancel(reservation) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
