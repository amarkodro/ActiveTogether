import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/activity.dart';
import '../../services/activity_service.dart';
import '../../services/api_client.dart';
import '../../theme/app_colors.dart';
import 'participants_screen.dart';

class ParticipantsActivityListScreen extends StatefulWidget {
  const ParticipantsActivityListScreen({super.key});

  @override
  State<ParticipantsActivityListScreen> createState() =>
      _ParticipantsActivityListScreenState();
}

class _ParticipantsActivityListScreenState
    extends State<ParticipantsActivityListScreen> {
  late Future<List<Activity>> _activitiesFuture;

  @override
  void initState() {
    super.initState();
    _activitiesFuture = _load();
  }

  Future<List<Activity>> _load() {
    final apiClient = context.read<ApiClient>();
    return ActivityService(apiClient).getMy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Učesnici'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
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

            final activities = snapshot.data ?? [];
            if (activities.isEmpty) {
              return const Center(child: Text('Nemaš aktivnosti.'));
            }

            return ListView.builder(
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
                    leading: Text(
                      AppColors.categoryEmoji(activity.categoryName),
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(
                      activity.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '$dateLabel\n${activity.reservedCount}/${activity.capacity} prijavljenih',
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ParticipantsScreen(
                            activityId: activity.id,
                            activityName: activity.name,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
