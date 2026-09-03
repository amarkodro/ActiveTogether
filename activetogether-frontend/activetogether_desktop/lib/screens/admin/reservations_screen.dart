import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/paged_result.dart';
import '../../models/reservation_item.dart';
import '../../services/api_client.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/reservation_details_dialog.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  String? _selectedStatus;
  int _page = 1;
  final int _pageSize = 10;

  late Future<PagedResult<ReservationItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PagedResult<ReservationItem>> _load() {
    final apiClient = context.read<ApiClient>();
    return ReservationService(
      apiClient,
    ).getAll(status: _selectedStatus, page: _page, pageSize: _pageSize);
  }

  void _refresh({bool resetPage = false}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

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

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otkazivanje rezervacije'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Otkazujete rezervaciju korisnika ${reservation.userName} za "${reservation.activityName}".',
              ),
              const SizedBox(height: 16),
              const Text(
                'Razlog (opciono)',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Otkaži rezervaciju'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final apiClient = context.read<ApiClient>();
    try {
      final reason = reasonController.text.trim();
      await ReservationService(
        apiClient,
      ).cancel(reservation.id, reason.isEmpty ? null : reason);
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
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rezervacije',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 240,
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
                _selectedStatus = value;
                _refresh(resetPage: true);
              },
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
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
                          const Text('Greška pri učitavanju rezervacija.'),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            onPressed: () => _refresh(),
                            child: const Text('Pokušaj ponovo'),
                          ),
                        ],
                      ),
                    );
                  }

                  final result = snapshot.data!;

                  return Column(
                    children: [
                      _buildHeaderRow(),
                      const Divider(height: 1),
                      Expanded(
                        child: result.items.isEmpty
                            ? const Center(
                                child: Text(
                                  'Nema rezervacija.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                itemCount: result.items.length,
                                separatorBuilder: (_, _) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, index) =>
                                    _buildRow(result.items[index]),
                              ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              'Stranica $_page od ${result.totalPages}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _page > 1
                                  ? () {
                                      _page--;
                                      _refresh();
                                    }
                                  : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _page < result.totalPages
                                  ? () {
                                      _page++;
                                      _refresh();
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow() {
    const style = TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: 12,
      color: AppColors.textSecondary,
    );
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('AKTIVNOST', style: style)),
          Expanded(flex: 2, child: Text('KORISNIK', style: style)),
          Expanded(flex: 2, child: Text('DATUM REZERVACIJE', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          SizedBox(width: 130, child: Text('AKCIJE', style: style)),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reservation.activityName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat(
                    'dd.MM.yyyy. HH:mm',
                  ).format(reservation.activityDateTime),
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
            child: Text(
              reservation.userName,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd.MM.yyyy.').format(reservation.createdAt),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
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
