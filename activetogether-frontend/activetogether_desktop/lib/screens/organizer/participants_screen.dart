import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/api_config.dart';
import '../../models/activity_list_item.dart';
import '../../models/reservation_item.dart';
import '../../services/activity_service.dart';
import '../../services/api_client.dart';
import '../../services/reservation_service.dart';
import '../../theme/app_colors.dart';
import '../admin/widgets/reservation_details_dialog.dart';

class ParticipantsScreen extends StatefulWidget {
  const ParticipantsScreen({super.key});

  @override
  State<ParticipantsScreen> createState() => _ParticipantsScreenState();
}

class _ParticipantsScreenState extends State<ParticipantsScreen> {
  final _searchController = TextEditingController();
  List<ActivityListItem> _myActivities = [];
  int? _selectedActivityId;
  String? _selectedStatus;
  bool _loadingActivities = true;
  bool _loadingParticipants = false;
  bool _bulkConfirming = false;
  List<ReservationItem> _participants = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final apiClient = context.read<ApiClient>();
    try {
      final result = await ActivityService(
        apiClient,
      ).getMy(page: 1, pageSize: 100);
      setState(() {
        _myActivities = result.items;
        _loadingActivities = false;
      });
    } catch (_) {
      setState(() => _loadingActivities = false);
    }
  }

  Future<void> _loadParticipants() async {
    if (_selectedActivityId == null) return;

    setState(() {
      _loadingParticipants = true;
      _errorMessage = null;
    });

    final apiClient = context.read<ApiClient>();
    try {
      final result = await ReservationService(apiClient).getForOrganizer(
        activityId: _selectedActivityId,
        status: _selectedStatus,
        page: 1,
        pageSize: 200,
      );
      setState(() {
        _participants = result.items;
        _loadingParticipants = false;
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Greška pri učitavanju učesnika.';
        _loadingParticipants = false;
      });
    }
  }

  List<ReservationItem> get _filteredParticipants {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _participants;
    return _participants
        .where((p) => p.userName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _confirm(ReservationItem reservation) async {
    final apiClient = context.read<ApiClient>();
    try {
      await ReservationService(apiClient).confirm(reservation.id);
      _loadParticipants();
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

  Future<void> _confirmAll() async {
    final pending = _participants.where((p) => p.status == 'Pending').toList();
    if (pending.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Potvrdi sve'),
        content: Text(
          'Da li želite potvrditi svih ${pending.length} rezervacija na čekanju?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Potvrdi sve'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _bulkConfirming = true);
    final apiClient = context.read<ApiClient>();
    final service = ReservationService(apiClient);
    for (final p in pending) {
      try {
        await service.confirm(p.id);
      } catch (_) {}
    }
    setState(() => _bulkConfirming = false);
    _loadParticipants();
  }

  Future<void> _cancel(ReservationItem reservation) async {
    final reasonController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Otkazivanje rezervacije'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Otkazujete rezervaciju korisnika ${reservation.userName}.'),
              const SizedBox(height: 16),
              const Text(
                'Razlog (obavezno)',
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
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Nazad'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (reasonController.text.trim().isEmpty) return;
              Navigator.of(dialogContext).pop(true);
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
      _loadParticipants();
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = _participants.any((p) => p.status == 'Pending');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Učesnici',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _loadingActivities
                    ? const LinearProgressIndicator()
                    : DropdownButtonFormField<int?>(
                        initialValue: _selectedActivityId,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        hint: const Text('Odaberite aktivnost'),
                        items: [
                          for (final a in _myActivities)
                            DropdownMenuItem<int?>(
                              value: a.id,
                              child: Text(a.name),
                            ),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedActivityId = value);
                          _loadParticipants();
                        },
                      ),
              ),
              const SizedBox(width: 12),
              if (_selectedActivityId != null) ...[
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Pretraga po imenu...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
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
                      _loadParticipants();
                    },
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _selectedActivityId == null
                ? const Center(
                    child: Text(
                      'Odaberite aktivnost da vidite učesnike.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _loadingParticipants
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(_errorMessage!),
                                const SizedBox(height: 12),
                                ElevatedButton(
                                  onPressed: _loadParticipants,
                                  child: const Text('Pokušaj ponovo'),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  16,
                                  20,
                                  8,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ukupno ${_filteredParticipants.length} učesnika',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (hasPending)
                                      ElevatedButton.icon(
                                        onPressed: _bulkConfirming
                                            ? null
                                            : _confirmAll,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: _bulkConfirming
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(
                                                Icons.done_all,
                                                size: 18,
                                              ),
                                        label: const Text('Potvrdi sve'),
                                      ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),
                              Expanded(
                                child: _filteredParticipants.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Nema učesnika.',
                                          style: TextStyle(
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: _filteredParticipants.length,
                                        separatorBuilder: (_, _) =>
                                            const Divider(height: 1),
                                        itemBuilder: (context, index) =>
                                            _buildRow(
                                              _filteredParticipants[index],
                                            ),
                                      ),
                              ),
                            ],
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(ReservationItem r) {
    final paymentNotCompleted =
        r.payment != null && r.payment!.status != 'Completed';
    final canConfirm = r.status == 'Pending' && !paymentNotCompleted;
    final canCancel =
        (r.status == 'Pending' || r.status == 'Confirmed') &&
        r.activityDateTime.isAfter(DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.roleUser,
            backgroundImage:
                ApiConfig.resolveImageUrl(r.userProfileImageUrl) != null
                ? NetworkImage(
                    ApiConfig.resolveImageUrl(r.userProfileImageUrl)!,
                  )
                : null,
            child: ApiConfig.resolveImageUrl(r.userProfileImageUrl) != null
                ? null
                : Text(
                    r.userName.isNotEmpty ? r.userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.userName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Rezervisano: ${DateFormat('dd.MM.yyyy.').format(r.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.statusColor(r.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              AppColors.statusLabel(r.status),
              style: TextStyle(
                color: AppColors.statusColor(r.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            tooltip: 'Detalji',
            onPressed: () => showDialog(
              context: context,
              builder: (_) => ReservationDetailsDialog(reservation: r),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            color: canConfirm ? AppColors.success : AppColors.textSecondary,
            tooltip: paymentNotCompleted
                ? 'Ne može se potvrditi dok uplata nije završena'
                : 'Potvrdi',
            onPressed: canConfirm ? () => _confirm(r) : null,
          ),
          IconButton(
            icon: const Icon(Icons.cancel_outlined, size: 20),
            color: canCancel ? AppColors.danger : AppColors.textSecondary,
            tooltip: 'Otkaži',
            onPressed: canCancel ? () => _cancel(r) : null,
          ),
        ],
      ),
    );
  }
}
