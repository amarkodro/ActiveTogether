import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'api_client.dart';

class ReportService {
  final ApiClient _apiClient;

  ReportService(this._apiClient);

  Future<Uint8List> downloadActivityPopularity({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Reports/activity-popularity',
      queryParameters: {
        if (dateFrom != null) 'dateFrom': dateFrom.toUtc().toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toUtc().toIso8601String(),
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }

  Future<Uint8List> downloadUserActivity({
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Reports/user-activity',
      queryParameters: {
        if (dateFrom != null) 'dateFrom': dateFrom.toUtc().toIso8601String(),
        if (dateTo != null) 'dateTo': dateTo.toUtc().toIso8601String(),
      },
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(response.data as List<int>);
  }
}
