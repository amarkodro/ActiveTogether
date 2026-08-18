import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class OrganizerNavItem {
  final String key;
  final IconData icon;
  final String label;

  const OrganizerNavItem({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class OrganizerSidebar extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelect;

  const OrganizerSidebar({
    super.key,
    required this.selectedKey,
    required this.onSelect,
  });

  static const items = [
    OrganizerNavItem(
      key: 'dashboard',
      icon: Icons.dashboard_outlined,
      label: 'Dashboard',
    ),
    OrganizerNavItem(
      key: 'my_activities',
      icon: Icons.event_outlined,
      label: 'Moje aktivnosti',
    ),
    OrganizerNavItem(
      key: 'my_reservations',
      icon: Icons.bookmark_outline,
      label: 'Moje rezervacije',
    ),
    OrganizerNavItem(
      key: 'participants',
      icon: Icons.people_outline,
      label: 'Učesnici',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: AppColors.sidebarBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Image(
                image: AssetImage('assets/images/logo.png'),
                width: 40,
                height: 40,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [for (final item in items) _buildItem(item)],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(OrganizerNavItem item) {
    final isSelected = item.key == selectedKey;
    return Material(
      color: isSelected
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onSelect(item.key),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isSelected ? AppColors.primary : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                item.label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
