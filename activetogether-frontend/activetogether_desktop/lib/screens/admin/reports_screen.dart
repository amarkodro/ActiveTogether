import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/api_client.dart';
import '../../services/report_service.dart';
import '../../theme/app_colors.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Izvještaji',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ReportCard(
                  title: 'Popularnost aktivnosti',
                  description:
                      'Pregled aktivnosti rangiranih po broju rezervacija i popunjenosti u odabranom periodu.',
                  icon: Icons.bar_chart,
                  fileName: 'popularnost-aktivnosti.pdf',
                  onDownload: (dateFrom, dateTo) {
                    final apiClient = context.read<ApiClient>();
                    return ReportService(apiClient).downloadActivityPopularity(
                      dateFrom: dateFrom,
                      dateTo: dateTo,
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _ReportCard(
                  title: 'Aktivnost korisnika',
                  description:
                      'Pregled registracija i aktivnosti korisnika na platformi u odabranom periodu.',
                  icon: Icons.person_outline,
                  fileName: 'aktivnost-korisnika.pdf',
                  onDownload: (dateFrom, dateTo) {
                    final apiClient = context.read<ApiClient>();
                    return ReportService(
                      apiClient,
                    ).downloadUserActivity(dateFrom: dateFrom, dateTo: dateTo);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatefulWidget {
  final String title;
  final String description;
  final IconData icon;
  final String fileName;
  final Future<Uint8List> Function(DateTime? dateFrom, DateTime? dateTo)
  onDownload;

  const _ReportCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.fileName,
    required this.onDownload,
  });

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard> {
  DateTime? _dateFrom;
  DateTime? _dateTo;
  bool _downloading = false;
  String? _errorMessage;

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _dateFrom = picked;
      } else {
        _dateTo = picked;
      }
    });
  }

  Future<void> _download() async {
    setState(() {
      _downloading = true;
      _errorMessage = null;
    });

    try {
      final bytes = await widget.onDownload(_dateFrom, _dateTo);

      final location = await getSaveLocation(suggestedName: widget.fileName);
      if (location == null) {
        setState(() => _downloading = false);
        return;
      }

      final file = File(location.path);
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Izvještaj je sačuvan: ${location.path}')),
        );
      }
    } catch (e) {
      setState(
        () => _errorMessage =
            'Došlo je do greške prilikom generisanja izvještaja.',
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd.MM.yyyy.');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.icon, color: AppColors.primary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            widget.description,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Period (opciono)',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: true),
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: Text(
                    _dateFrom != null ? dateFormat.format(_dateFrom!) : 'Od',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: false),
                  icon: const Icon(Icons.calendar_today, size: 14),
                  label: Text(
                    _dateTo != null ? dateFormat.format(_dateTo!) : 'Do',
                  ),
                ),
              ),
              if (_dateFrom != null || _dateTo != null)
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  tooltip: 'Ukloni filter perioda',
                  onPressed: () => setState(() {
                    _dateFrom = null;
                    _dateTo = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _downloading ? null : _download,
              icon: _downloading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_downloading ? 'Generisanje...' : 'Preuzmi PDF'),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
