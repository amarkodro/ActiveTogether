import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin_top_bar.dart';
import '../../widgets/organizer_sidebar.dart';
import 'organizer_dashboard_screen.dart';
import 'my_activities_screen.dart';
import 'my_reservations_screen.dart';
import 'participants_screen.dart';

class OrganizerShellScreen extends StatefulWidget {
  const OrganizerShellScreen({super.key});

  @override
  State<OrganizerShellScreen> createState() => _OrganizerShellScreenState();
}

class _OrganizerShellScreenState extends State<OrganizerShellScreen> {
  String _selectedKey = 'dashboard';

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          OrganizerSidebar(
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
        return const OrganizerDashboardScreen();
      case 'my_activities':
        return const MyActivitiesScreen();
      case 'my_reservations':
        return const MyReservationsScreen();
      case 'participants':
        return const ParticipantsScreen();
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
