import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/admin_top_bar.dart';
import 'admin_dashboard_screen.dart';
import 'users_screen.dart';
import 'organizer_requests_screen.dart';
import 'activities_screen.dart';
import 'reservations_screen.dart';
import 'reference_data_screen.dart';
import 'reports_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  String _selectedKey = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          AdminSidebar(
            selectedKey: _selectedKey,
            onSelect: (key) => setState(() => _selectedKey = key),
          ),
          Expanded(
            child: Column(
              children: [
                AdminTopBar(
                  user: authProvider.currentUser,
                  onLogout: () => context.read<AuthProvider>().logout(),
                ),
                Expanded(child: _buildContent()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedKey) {
      case 'dashboard':
        return const AdminDashboardScreen();
      case 'users':
        return const UsersScreen();
      case 'organizer_requests':
        return const OrganizerRequestsScreen();
      case 'activities':
        return const ActivitiesScreen();
      case 'reservations':
        return const ReservationsScreen();
      case 'reference_data':
        return const ReferenceDataScreen();
      case 'reports':
        return const ReportsScreen();
      default:
        return const Center(
          child: Text(
            'Ovaj dio je u izradi.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        );
    }
  }
}
