import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1E3A8A);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFCA8A04);
  static const danger = Color(0xFFDC2626);
  static const neutral = Color(0xFF6B7280);

  static const categorySport = Color(0xFF2563EB);
  static const categoryFitness = Color(0xFF16A34A);
  static const categoryOutdoor = Color(0xFFF97316);
  static const categoryOther = Color(0xFF6B7280);

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

  static String categoryEmoji(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'sport':
        return '⚽';
      case 'fitness':
        return '💪';
      case 'outdoor':
        return '🏕️';
      default:
        return '🎯';
    }
  }

  static Color capacityColor(double fillRatio) {
    if (fillRatio > 0.9) return danger;
    if (fillRatio >= 0.7) return warning;
    return success;
  }

  static Color reservationStatusColor(String status) {
    switch (status) {
      case 'Confirmed':
        return success;
      case 'Pending':
        return warning;
      case 'Cancelled':
        return danger;
      case 'Completed':
        return primary;
      default:
        return neutral;
    }
  }

  static String reservationStatusLabel(String status) {
    switch (status) {
      case 'Confirmed':
        return 'Potvrđeno';
      case 'Pending':
        return 'Na čekanju';
      case 'Cancelled':
        return 'Otkazano';
      case 'Completed':
        return 'Završeno';
      default:
        return status;
    }
  }
}
