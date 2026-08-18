import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AdminNavItem {
  final String key;
  final IconData icon;
  final String label;

  const AdminNavItem({
    required this.key,
    required this.icon,
    required this.label,
  });
}

class AdminNavSection {
  final String title;
  final List<AdminNavItem> items;

  const AdminNavSection({required this.title, required this.items});
}

class AdminSidebar extends StatelessWidget {
  final String selectedKey;
  final ValueChanged<String> onSelect;

  const AdminSidebar({
    super.key,
    required this.selectedKey,
    required this.onSelect,
  });

  static const sections = [
    AdminNavSection(
      title: 'PREGLED',
      items: [
        AdminNavItem(
          key: 'dashboard',
          icon: Icons.dashboard_outlined,
          label: 'Dashboard',
        ),
      ],
    ),
    AdminNavSection(
      title: 'UPRAVLJANJE',
      items: [
        AdminNavItem(
          key: 'users',
          icon: Icons.people_outline,
          label: 'Korisnici',
        ),
        AdminNavItem(
          key: 'organizer_requests',
          icon: Icons.how_to_reg_outlined,
          label: 'Zahtjevi za organizatore',
        ),
        AdminNavItem(
          key: 'activities',
          icon: Icons.event_outlined,
          label: 'Aktivnosti',
        ),
        AdminNavItem(
          key: 'reservations',
          icon: Icons.bookmark_outline,
          label: 'Rezervacije',
        ),
      ],
    ),
    AdminNavSection(
      title: 'POSTAVKE',
      items: [
        AdminNavItem(
          key: 'reference_data',
          icon: Icons.settings_outlined,
          label: 'Referentni podaci',
        ),
      ],
    ),
    AdminNavSection(
      title: 'ANALITIKA',
      items: [
        AdminNavItem(
          key: 'reports',
          icon: Icons.picture_as_pdf_outlined,
          label: 'Izvještaji',
        ),
      ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Image.asset(
                'assets/images/logo.png',
                width: 150,
                height: 150,
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  for (final section in sections) _buildSection(section),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(AdminNavSection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            section.title,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        for (final item in section.items) _buildItem(item),
      ],
    );
  }

  Widget _buildItem(AdminNavItem item) {
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
