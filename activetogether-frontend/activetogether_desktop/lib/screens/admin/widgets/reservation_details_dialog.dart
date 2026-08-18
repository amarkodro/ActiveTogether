import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/reservation_item.dart';
import '../../../theme/app_colors.dart';

class ReservationDetailsDialog extends StatelessWidget {
  final ReservationItem reservation;

  const ReservationDetailsDialog({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy. HH:mm');

    return AlertDialog(
      title: const Text('Detalji rezervacije'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Aktivnost', reservation.activityName),
            _row(
              'Termin aktivnosti',
              dateFormat.format(reservation.activityDateTime),
            ),
            _row('Korisnik', reservation.userName),
            _row('Status', AppColors.statusLabel(reservation.status)),
            _row(
              'Rezervacija kreirana',
              dateFormat.format(reservation.createdAt),
            ),
            if (reservation.confirmedAt != null)
              _row('Potvrđena', dateFormat.format(reservation.confirmedAt!)),
            if (reservation.completedAt != null)
              _row('Završena', dateFormat.format(reservation.completedAt!)),
            if (reservation.cancelledAt != null)
              _row('Otkazana', dateFormat.format(reservation.cancelledAt!)),
            if (reservation.cancellationReason != null)
              _row('Razlog otkazivanja', reservation.cancellationReason!),
            if (reservation.payment != null) ...[
              const Divider(height: 24),
              const Text(
                'Plaćanje',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              _row(
                'Iznos',
                '${reservation.payment!.amount.toStringAsFixed(2)} KM',
              ),
              _row('Status plaćanja', reservation.payment!.status),
              if (reservation.payment!.paidAt != null)
                _row(
                  'Plaćeno',
                  dateFormat.format(reservation.payment!.paidAt!),
                ),
              if (reservation.payment!.refundedAt != null)
                _row(
                  'Refundirano',
                  dateFormat.format(reservation.payment!.refundedAt!),
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Zatvori'),
        ),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
