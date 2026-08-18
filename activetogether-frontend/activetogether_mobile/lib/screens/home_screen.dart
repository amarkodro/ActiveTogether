import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/recommended_activity.dart';
import '../providers/auth_provider.dart';
import '../services/api_client.dart';
import '../services/recommendation_service.dart';
import '../widgets/activity_card.dart';
import 'activity_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _categories = ['Sve', 'Sport', 'Fitness', 'Outdoor'];
  String _selectedCategory = 'Sve';

  late Future<List<RecommendedActivity>> _recommendationsFuture;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = _loadRecommendations();
  }

  Future<List<RecommendedActivity>> _loadRecommendations() async {
    final apiClient = context.read<ApiClient>();
    final result = await RecommendationService(
      apiClient,
    ).getRecommendations(pageSize: 20);
    return result.items;
  }

  Future<void> _refresh() async {
    setState(() {
      _recommendationsFuture = _loadRecommendations();
    });
    await _recommendationsFuture;
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Dobro jutro';
    if (hour < 18) return 'Dobar dan';
    return 'Dobro veče';
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ActiveTogether',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        '${_greeting()}, ${user?.firstName ?? ''}!',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      // TODO: notifikacije ekran
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Pretraži aktivnosti...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                readOnly: true,
                onTap: () {
                  // TODO: navigacija na Search ekran
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final selected = category == _selectedCategory;
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                      selectedColor: const Color(0xFF1E3A8A),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Preporučeno za tebe',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const Text(
                'Na osnovu tvojih aktivnosti',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<RecommendedActivity>>(
                future: _recommendationsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasError) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text('Greška pri učitavanju: ${snapshot.error}'),
                      ),
                    );
                  }
                  var items = snapshot.data ?? [];
                  if (_selectedCategory != 'Sve') {
                    items = items
                        .where(
                          (r) => r.activity.categoryName == _selectedCategory,
                        )
                        .toList();
                  }
                  if (items.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('Trenutno nema preporuka.')),
                    );
                  }
                  return Column(
                    children: items
                        .map(
                          (r) => ActivityCard(
                            activity: r.activity,
                            reason: r.reason,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ActivityDetailScreen(
                                    activityId: r.activity.id,
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
