import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
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
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        },
      ),
    );
  }
}
