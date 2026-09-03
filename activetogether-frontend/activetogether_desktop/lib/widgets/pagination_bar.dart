import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Jednostavna traka za paginaciju (Prethodna/Sljedeća + "Stranica X od Y").
/// Koristi se na admin CRUD listama referentnih podataka.
class PaginationBar extends StatelessWidget {
  final int page;
  final int totalCount;
  final int pageSize;
  final ValueChanged<int> onPageChanged;

  const PaginationBar({
    super.key,
    required this.page,
    required this.totalCount,
    required this.pageSize,
    required this.onPageChanged,
  });

  int get totalPages => (totalCount / pageSize).ceil().clamp(1, 999999);

  @override
  Widget build(BuildContext context) {
    if (totalCount == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Ukupno: $totalCount',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            onPressed: page > 1 ? () => onPageChanged(page - 1) : null,
          ),
          Text(
            'Stranica $page od $totalPages',
            style: const TextStyle(fontSize: 13),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            onPressed: page < totalPages ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
