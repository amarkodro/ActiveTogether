import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../providers/notification_provider.dart';
import '../../services/activity_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import '../notifications_screen.dart';
import 'activity_form_screen.dart';
import 'participants_screen.dart';

class MyActivitiesScreen extends StatefulWidget {
  const MyActivitiesScreen({super.key});

  @override
  State<MyActivitiesScreen> createState() => _MyActivitiesScreenState();
}

class _MyActivitiesScreenState extends State<MyActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<Activity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _activitiesFuture = _load();
    context.read<NotificationProvider>().init();
  }

  Future<List<Activity>> _load() {
    final apiClient = context.read<ApiClient>();
    return ActivityService(apiClient).getMy();
  }

  Future<void> _refresh() async {
    setState(() {
      _activitiesFuture = _load();
    });
    await _activitiesFuture;
  }

  String _errorText(Object e, String fallback) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    }
    return fallback;
  }

  Future<void> _completeActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Označi kao završeno'),
        content: Text(
          'Da li sigurno želiš označiti "${activity.name}" kao završenu aktivnost? '
          'Potvrđene rezervacije će postati završene, a učesnici će moći ostaviti ocjenu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Označi kao završeno'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiClient = context.read<ApiClient>();
      await ActivityService(apiClient).complete(activity.id);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _tabController.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivnost je označena kao završena.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _errorText(e, 'Označavanje kao završeno nije uspjelo.'),
          ),
        ),
      );
    }
  }

  Future<void> _cancelActivity(Activity activity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Otkazivanje aktivnosti'),
        content: Text(
          'Da li sigurno želiš otkazati aktivnost "${activity.name}"? '
          'Svi prijavljeni učesnici će biti obaviješteni, a plaćene rezervacije će biti refundirane.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Odustani'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Da, otkaži aktivnost'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final apiClient = context.read<ApiClient>();
      await ActivityService(apiClient).cancel(activity.id);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      _tabController.animateTo(2);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivnost je otkazana.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorText(e, 'Otkazivanje nije uspjelo.'))),
      );
    }
  }

  void _openParticipants(Activity activity) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ParticipantsScreen(
          activityId: activity.id,
          activityName: activity.name,
        ),
      ),
    );
  }

  Future<void> _editActivity(Activity activity) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ActivityFormScreen(activity: activity),
      ),
    );
    if (saved == true) _refresh();
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'Active':
        return 'Aktivno';
      case 'Completed':
        return 'Završeno';
      case 'Cancelled':
        return 'Otkazano';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Active':
        return const Color(0xFF1E3A8A);
      case 'Completed':
        return const Color(0xFF16A34A);
      case 'Cancelled':
        return AppColors.danger;
      default:
        return Colors.grey;
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
            Tab(text: 'Aktivne'),
            Tab(text: 'Na čekanju'),
            Tab(text: 'Završene'),
          ],
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notif, _) => IconButton(
              icon: Badge(
                label: Text('${notif.unreadCount}'),
                isLabelVisible: notif.unreadCount > 0,
                child: const Icon(Icons.notifications_none),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const NotificationsScreen(),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              final saved = await Navigator.of(context).push<bool>(
                MaterialPageRoute(builder: (_) => const ActivityFormScreen()),
              );
              if (saved == true) _refresh();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<List<Activity>>(
          future: _activitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            }

            final all = snapshot.data ?? [];
            final now = DateTime.now();

            // "Aktivne" = tekuće/nadolazeće aktivnosti koje još nisu održane.
            final active = all
                .where((a) => a.status == 'Active' && a.dateTime.isAfter(now))
                .toList();
            // "Na čekanju" = termin je prošao, a organizator još nije označio
            // aktivnost kao završenu (čeka njegovu akciju).
            final pending = all
                .where(
                  (a) => a.status == 'Active' && !a.dateTime.isAfter(now),
                )
                .toList();
            // "Završene" = konačno stanje aktivnosti (završena ili otkazana).
            final finished = all
                .where(
                  (a) => a.status == 'Completed' || a.status == 'Cancelled',
                )
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(active),
                _buildList(pending),
                _buildList(finished),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildList(List<Activity> activities) {
    if (activities.isEmpty) {
      return const Center(child: Text('Nema aktivnosti u ovoj kategoriji.'));
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities[index];
          final dateLabel = DateFormat(
            'dd.MM.yyyy. HH:mm',
          ).format(activity.dateTime);
          final canComplete =
              activity.status == 'Active' &&
              activity.dateTime.isBefore(DateTime.now());
          final canEditOrCancel = activity.status == 'Active';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppColors.categoryEmoji(activity.categoryName),
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activity.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$dateLabel • ${activity.locationName}\n'
                              '${activity.reservedCount}/${activity.capacity} prijavljenih',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
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
                          color: _statusColor(
                            activity.status,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _statusLabel(activity.status),
                          style: TextStyle(
                            color: _statusColor(activity.status),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (canComplete)
                        IconButton(
                          icon: const Icon(
                            Icons.check_circle_outline,
                            color: Color(0xFF16A34A),
                          ),
                          tooltip: 'Označi kao završeno',
                          onPressed: () => _completeActivity(activity),
                        ),
                      IconButton(
                        icon: const Icon(Icons.people_outline),
                        tooltip: 'Učesnici',
                        onPressed: () => _openParticipants(activity),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Uredi',
                        onPressed: canEditOrCancel
                            ? () => _editActivity(activity)
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel_outlined),
                        color: canEditOrCancel ? AppColors.danger : null,
                        tooltip: 'Otkaži',
                        onPressed: canEditOrCancel
                            ? () => _cancelActivity(activity)
                            : null,
                      ),
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
