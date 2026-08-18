import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/organizer_dashboard_stats.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/dashboard_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/metric_card.dart';

class OrganizerDashboardScreen extends StatefulWidget {
  const OrganizerDashboardScreen({super.key});

  @override
  State<OrganizerDashboardScreen> createState() =>
      _OrganizerDashboardScreenState();
}

class _OrganizerDashboardScreenState extends State<OrganizerDashboardScreen> {
  late Future<OrganizerDashboardStats> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<OrganizerDashboardStats> _load() {
    final apiClient = context.read<ApiClient>();
    return DashboardService(apiClient).getOrganizerDashboard();
  }

  void _retry() => setState(() => _future = _load());

  String _formatCurrency(double amount) =>
      '${NumberFormat('#,##0.00').format(amount)} KM';

  Color _fillColor(double ratio) {
    if (ratio >= 0.9) return AppColors.danger;
    if (ratio >= 0.7) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final firstName = authProvider.currentUser?.firstName ?? '';

    return FutureBuilder<OrganizerDashboardStats>(
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
                const Text('Greška pri učitavanju statistike.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _retry,
                  child: const Text('Pokušaj ponovo'),
                ),
              ],
            ),
          );
        }

        final stats = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dobrodošli nazad, $firstName!',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  MetricCard(
                    title: 'Aktivne aktivnosti',
                    value: stats.activeActivitiesCount.toString(),
                    icon: Icons.event_outlined,
                  ),
                  MetricCard(
                    title: 'Ukupno učesnika',
                    value: stats.totalParticipants.toString(),
                    icon: Icons.people_outline,
                  ),
                  MetricCard(
                    title: 'Prihodi ovaj mjesec',
                    value: _formatCurrency(stats.monthlyRevenue),
                    icon: Icons.payments_outlined,
                  ),
                  MetricCard(
                    title: 'Prosječna ocjena',
                    value: '${stats.averageRating.toStringAsFixed(1)} / 5.0',
                    icon: Icons.star_outline,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 20,
                children: [
                  Text(
                    '+ ${stats.newActivitiesThisWeek} u tekućoj sedmici',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '+ ${stats.newParticipantsThisWeek} novih prijava',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FillRateCard(
                      data: stats.activityFillRates,
                      colorFor: _fillColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _RecentReservationsCard(
                      data: stats.recentReservations,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FillRateCard extends StatelessWidget {
  final List<ActivityFillRate> data;
  final Color Function(double ratio) colorFor;

  const _FillRateCard({required this.data, required this.colorFor});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Popunjenost po aktivnostima',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Nema aktivnih aktivnosti.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = data[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  item.activityName,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${item.reservedCount}/${item.capacity}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: item.fillRatio.clamp(0, 1),
                              minHeight: 8,
                              backgroundColor: AppColors.border,
                              color: colorFor(item.fillRatio),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _RecentReservationsCard extends StatelessWidget {
  final List<RecentReservationEntry> data;

  const _RecentReservationsCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nedavne rezervacije',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: data.isEmpty
                ? const Center(
                    child: Text(
                      'Nema rezervacija.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : ListView.separated(
                    itemCount: data.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final r = data[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            Expanded(
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
                                    DateFormat(
                                      'dd.MM.yyyy.',
                                    ).format(r.createdAt),
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
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
                                color: AppColors.statusColor(
                                  r.status,
                                ).withValues(alpha: 0.12),
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
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
