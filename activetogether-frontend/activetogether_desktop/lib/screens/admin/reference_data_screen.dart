import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'widgets/cities_tab.dart';
import 'widgets/locations_tab.dart';
import 'widgets/simple_reference_tab.dart';

class ReferenceDataScreen extends StatelessWidget {
  const ReferenceDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Referentni podaci',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const TabBar(
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Kategorije'),
                  Tab(text: 'Tipovi aktivnosti'),
                  Tab(text: 'Države'),
                  Tab(text: 'Gradovi'),
                  Tab(text: 'Lokacije'),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(color: AppColors.border),
                ),
                child: const TabBarView(
                  children: [
                    SimpleReferenceTab(
                      endpoint: 'Categories',
                      title: 'Kategorije',
                      singularLabel: 'kategorija',
                    ),
                    SimpleReferenceTab(
                      endpoint: 'ActivityTypes',
                      title: 'Tipovi aktivnosti',
                      singularLabel: 'tip aktivnosti',
                    ),
                    SimpleReferenceTab(
                      endpoint: 'Countries',
                      title: 'Države',
                      singularLabel: 'država',
                    ),
                    CitiesTab(),
                    LocationsTab(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
