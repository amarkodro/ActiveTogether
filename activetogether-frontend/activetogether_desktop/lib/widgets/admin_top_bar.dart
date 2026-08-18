import 'package:flutter/material.dart';
import '../models/user.dart';
import '../theme/app_colors.dart';

class AdminTopBar extends StatelessWidget implements PreferredSizeWidget {
  final AppUser? user;
  final VoidCallback onLogout;

  const AdminTopBar({super.key, required this.user, required this.onLogout});

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(user?.fullName ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.roleColor(user?.role ?? ''),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              user?.role ?? '',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Odjava',
            onPressed: onLogout,
          ),
        ],
      ),
    );
  }
}