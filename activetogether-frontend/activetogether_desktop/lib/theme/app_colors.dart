import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color sidebarBackground = Color(0xFF1E293B);
  static const Color primary = Color(0xFF1E3A8A);
  static const Color background = Color(0xFFF8FAFC);
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);

  static const Color roleAdmin = Color(0xFF1E3A8A);
  static const Color roleOrganizer = Color(0xFFF59E0B);
  static const Color roleUser = Color(0xFF3B82F6);

  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color neutral = Color(0xFF6B7280);

  static const Color categorySport = Color(0xFF3B82F6);
  static const Color categoryFitness = Color(0xFF16A34A);
  static const Color categoryOutdoor = Color(0xFFF59E0B);
  static const Color categoryOther = Color(0xFF6B7280);

  static Color categoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'sport':
        return categorySport;
      case 'fitness':
        return categoryFitness;
      case 'outdoor':
        return categoryOutdoor;
      default:
        return categoryOther;
    }
  }

  static Color roleColor(String role) {
    switch (role) {
      case 'Admin':
        return roleAdmin;
      case 'Organizator':
        return roleOrganizer;
      default:
        return roleUser;
    }
  }

  static Color statusColor(String status) {
    switch (status) {
      case 'Active':
      case 'Confirmed':
      case 'Completed':
        return success;
      case 'Draft':
      case 'Pending':
        return warning;
      case 'Cancelled':
        return danger;
      default:
        return neutral;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'Active':
        return 'Aktivno';
      case 'Draft':
        return 'Draft';
      case 'Completed':
        return 'Završeno';
      case 'Cancelled':
        return 'Otkazano';
      case 'Pending':
        return 'Na čekanju';
      case 'Confirmed':
        return 'Potvrđeno';
      default:
        return status;
    }
  }
}
