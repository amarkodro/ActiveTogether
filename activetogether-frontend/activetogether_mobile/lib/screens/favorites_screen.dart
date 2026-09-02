import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/activity.dart';
import '../services/api_client.dart';
import '../services/favorite_service.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  late Future<List<Activity>> _favoritesFuture;

  @override
  void initState() {
    super.initState();
    _favoritesFuture = _load();
  }

  Future<List<Activity>> _load() async {
    final apiClient = context.read<ApiClient>();
    final result = await FavoriteService(apiClient).getMy(pageSize: 100);
    return result.items;
  }

  Future<void> _refresh() async {
    setState(() {
      _favoritesFuture = _load();
    });
    await _favoritesFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Omiljene aktivnosti'),
        backgroundColor: const Color(0xFFF4F6F8),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SafeArea(
        child: FutureBuilder<List<Activity>>(
          future: _favoritesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Greška: ${snapshot.error}'));
            }

            final favorites = snapshot.data ?? [];
            if (favorites.isEmpty) {
              return const Center(
                child: Text('Nemaš omiljenih aktivnosti.'),
              );
            }

            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: favorites.length,
                itemBuilder: (context, index) {
                  final activity = favorites[index];
                  return ActivityCard(
                    activity: activity,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              ActivityDetailScreen(activityId: activity.id),
                        ),
                      );
                      if (mounted) _refresh();
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
