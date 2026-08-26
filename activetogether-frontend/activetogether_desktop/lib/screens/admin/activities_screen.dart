import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity_list_item.dart';
import '../../models/paged_result.dart';
import '../../models/reference_option.dart';
import '../../services/activity_service.dart';
import '../../services/api_client.dart';
import '../../services/reference_data_service.dart';
import '../../theme/app_colors.dart';
import 'widgets/edit_activity_dialog.dart';

class ActivitiesScreen extends StatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;
  int? _selectedActivityTypeId;
  String? _selectedStatus;
  int _page = 1;
  final int _pageSize = 10;

  List<ReferenceOption> _categories = [];
  List<ReferenceOption> _activityTypes = [];
  late Future<PagedResult<ActivityListItem>> _future;

  @override
  void initState() {
    super.initState();
    _loadFilterOptions();
    _future = _load();
  }

  Future<void> _loadFilterOptions() async {
    final apiClient = context.read<ApiClient>();
    final service = ReferenceDataService(apiClient);
    try {
      final results = await Future.wait([
        service.getCategories(),
        service.getActivityTypes(),
      ]);
      setState(() {
        _categories = results[0] as List<ReferenceOption>;
        _activityTypes = results[1] as List<ReferenceOption>;
      });
    } catch (_) {
      // filteri ostaju prazni ako ne uspije, ekran i dalje radi
    }
  }

  Future<PagedResult<ActivityListItem>> _load() {
    final apiClient = context.read<ApiClient>();
    return ActivityService(apiClient).getAll(
      name: _searchController.text.trim(),
      categoryId: _selectedCategoryId,
      activityTypeId: _selectedActivityTypeId,
      status: _selectedStatus,
      page: _page,
      pageSize: _pageSize,
    );
  }

  void _refresh({bool resetPage = false}) {
    setState(() {
      if (resetPage) _page = 1;
      _future = _load();
    });
  }

  Future<void> _editActivity(ActivityListItem activity) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => EditActivityDialog(activity: activity),
    );
    if (result == true) _refresh();
  }

  Future<void> _cancelActivity(ActivityListItem activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Otkazivanje aktivnosti'),
        content: Text(
          'Da li ste sigurni da želite otkazati aktivnost "${activity.name}"? '
          'Svi prijavljeni korisnici će biti obaviješteni, a plaćene rezervacije će biti refundirane.',
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
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Da, otkaži aktivnost'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final apiClient = context.read<ApiClient>();
    try {
      await ActivityService(apiClient).cancel(activity.id);
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

  Color _capacityColor(double ratio) {
    if (ratio >= 0.9) return AppColors.danger;
    if (ratio >= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aktivnosti',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Text(
            'Sve aktivnosti na platformi',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Pretraga po nazivu...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _refresh(resetPage: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Sve kategorije'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sve kategorije'),
                    ),
                    for (final c in _categories)
                      DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (value) {
                    _selectedCategoryId = value;
                    _refresh(resetPage: true);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int?>(
                  initialValue: _selectedActivityTypeId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  hint: const Text('Sve vrste'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Sve vrste'),
                    ),
                    for (final t in _activityTypes)
                      DropdownMenuItem<int?>(value: t.id, child: Text(t.name)),
                  ],
                  onChanged: (value) {
                    _selectedActivityTypeId = value;
                    _refresh(resetPage: true);
                  },
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
                      value: 'Draft',
                      child: Text('Draft'),
                    ),
                    DropdownMenuItem<String?>(
                      value: 'Active',
                      child: Text('Aktivno'),
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
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: FutureBuilder<PagedResult<ActivityListItem>>(
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
                          const Text('Greška pri učitavanju aktivnosti.'),
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
                                  'Nema aktivnosti.',
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
          Expanded(flex: 2, child: Text('KATEGORIJA', style: style)),
          Expanded(flex: 2, child: Text('DATUM', style: style)),
          Expanded(flex: 2, child: Text('KAPACITET', style: style)),
          Expanded(flex: 2, child: Text('STATUS', style: style)),
          SizedBox(width: 90, child: Text('AKCIJE', style: style)),
        ],
      ),
    );
  }

  Widget _buildRow(ActivityListItem activity) {
    final canCancel = activity.status == 'Active' || activity.status == 'Draft';

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
                  activity.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  activity.organizerName,
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
                  color: AppColors.categoryColor(activity.categoryName),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activity.categoryName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd.MM.yyyy. HH:mm').format(activity.dateTime),
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.reservedCount}/${activity.capacity}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: activity.fillRatio.clamp(0, 1),
                    minHeight: 6,
                    backgroundColor: AppColors.border,
                    color: _capacityColor(activity.fillRatio),
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
                    activity.status,
                  ).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  AppColors.statusLabel(activity.status),
                  style: TextStyle(
                    color: AppColors.statusColor(activity.status),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 90,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Uredi',
                  onPressed: () => _editActivity(activity),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: canCancel ? AppColors.danger : AppColors.textSecondary,
                  tooltip: canCancel
                      ? 'Otkaži aktivnost'
                      : 'Aktivnost je već završena/otkazana',
                  onPressed: canCancel ? () => _cancelActivity(activity) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
