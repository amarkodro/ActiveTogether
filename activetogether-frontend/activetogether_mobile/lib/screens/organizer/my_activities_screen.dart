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
      _tabController.animateTo(1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aktivnost je označena kao završena.')),
      );
    } catch (e) {
      String message = 'Označavanje kao završeno nije uspjelo.';
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
            Tab(text: 'Aktivne'),
            Tab(text: 'Završene'),
            Tab(text: 'Otkazane'),
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
            final active = all.where((a) => a.status == 'Active').toList();
            final completed = all
                .where((a) => a.status == 'Completed')
                .toList();
            final cancelled = all
                .where((a) => a.status == 'Cancelled')
                .toList();

            return TabBarView(
              controller: _tabController,
              children: [
                _buildList(active),
                _buildList(completed),
                _buildList(cancelled),
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

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              onTap: () async {
                final saved = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => ActivityFormScreen(activity: activity),
                  ),
                );
                if (saved == true) _refresh();
              },
              leading: Text(
                AppColors.categoryEmoji(activity.categoryName),
                style: const TextStyle(fontSize: 24),
              ),
              title: Text(
                activity.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '$dateLabel • ${activity.locationName}\n${activity.reservedCount}/${activity.capacity} prijavljenih',
              ),
              isThreeLine: true,
              trailing: canComplete
                  ? IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF16A34A),
                      ),
                      tooltip: 'Označi kao završeno',
                      onPressed: () => _completeActivity(activity),
                    )
                  : const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
