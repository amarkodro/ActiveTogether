import '../models/paged_result.dart';
import '../models/reservation_item.dart';
import 'api_client.dart';

class ReservationService {
  final ApiClient _apiClient;

  ReservationService(this._apiClient);

  Future<PagedResult<ReservationItem>> getAll({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Reservations',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ReservationItem.fromJson(json),
    );
  }

  Future<void> confirm(int id) async {
    await _apiClient.dio.put('/api/Reservations/$id/confirm');
  }

  Future<void> cancel(int id, String? reason) async {
    await _apiClient.dio.put(
      '/api/Reservations/$id/cancel',
      data: {'reason': reason},
    );
  }

  Future<PagedResult<ReservationItem>> getForOrganizer({
    int? activityId,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Reservations/my-activities',
      queryParameters: {
        if (activityId != null) 'activityId': activityId,
        if (status != null) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ReservationItem.fromJson(json),
    );
  }
}
