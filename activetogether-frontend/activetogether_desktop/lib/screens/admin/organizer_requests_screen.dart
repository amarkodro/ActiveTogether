import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/organizer_request_item.dart';
import '../../models/paged_result.dart';
import '../../services/api_client.dart';
import '../../services/organizer_request_service.dart';
import '../../theme/app_colors.dart';

class OrganizerRequestsScreen extends StatefulWidget {
  const OrganizerRequestsScreen({super.key});

  @override
  State<OrganizerRequestsScreen> createState() =>
      _OrganizerRequestsScreenState();
}

class _OrganizerRequestsScreenState extends State<OrganizerRequestsScreen> {
  String? _selectedStatus = 'Pending';
  int _page = 1;
  final int _pageSize = 10;

  late Future<PagedResult<OrganizerRequestItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<PagedResult<OrganizerRequestItem>> _load() {
    final apiClient = context.read<ApiClient>();
    return OrganizerRequestService(
      apiClient,
    ).getAll(status: _selectedStatus, page: _page, pageSize: _pageSize);
  }

  void _refresh({bool resetPage = false}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

  Future<void> _approve(OrganizerRequestItem request) async {
    final apiClient = context.read<ApiClient>();
    try {
      await OrganizerRequestService(apiClient).approve(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zahtjev korisnika ${request.userFullName} je odobren.',
            ),
          ),
        );
      }
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

  Future<void> _reject(OrganizerRequestItem request) async {
    final reasonController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Odbijanje zahtjeva'),
        content: SizedBox(
          width: 400,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Odbijate zahtjev korisnika ${request.userFullName}.'),
                const SizedBox(height: 16),
                const Text(
                  'Razlog odbijanja',
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
                      ? 'Razlog odbijanja je obavezan.'
                      : null,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
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
            child: const Text('Odbij zahtjev'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final apiClient = context.read<ApiClient>();
    try {
      await OrganizerRequestService(
        apiClient,
      ).reject(request.id, reasonController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Zahtjev korisnika ${request.userFullName} je odbijen.',
            ),
          ),
        );
      }
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return AppColors.success;
      case 'Rejected':
        return AppColors.danger;
      default:
        return AppColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Approved':
        return 'Odobreno';
      case 'Rejected':
        return 'Odbijeno';
      default:
        return 'Na čekanju';
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
            'Zahtjevi za ulogu Organizatora',
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
              items: const [
                DropdownMenuItem<String?>(
                  value: 'Pending',
                  child: Text('Na čekanju'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Approved',
                  child: Text('Odobreno'),
                ),
                DropdownMenuItem<String?>(
                  value: 'Rejected',
                  child: Text('Odbijeno'),
                ),
                DropdownMenuItem<String?>(value: null, child: Text('Svi')),
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
              child: FutureBuilder<PagedResult<OrganizerRequestItem>>(
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
                          const Text('Greška pri učitavanju zahtjeva.'),
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

                  if (result.items.isEmpty) {
                    return const Center(
                      child: Text(
                        'Nema zahtjeva.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: result.items.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
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

  Widget _buildRow(OrganizerRequestItem request) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.roleUser,
            child: Text(
              request.initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.userFullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  request.userEmail,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zahtjev poslan: ${DateFormat('dd.MM.yyyy.').format(request.createdAt)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (request.status == 'Rejected' &&
                    request.rejectionReason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Razlog: ${request.rejectionReason}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(request.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _statusLabel(request.status),
              style: TextStyle(
                color: _statusColor(request.status),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (request.status == 'Pending')
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _approve(request),
                  child: const Text('Odobri'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                  ),
                  onPressed: () => _reject(request),
                  child: const Text('Odbij'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
