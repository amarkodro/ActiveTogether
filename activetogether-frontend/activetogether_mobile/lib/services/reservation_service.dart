import '../models/reservation.dart';
import 'api_client.dart';

class ReservationService {
  final ApiClient _apiClient;

  ReservationService(this._apiClient);

  Future<Map<String, dynamic>> create(int activityId) async {
    final response = await _apiClient.dio.post(
      '/api/Reservations',
      data: {'activityId': activityId},
    );
    return response.data as Map<String, dynamic>;
  }

  Future<List<Reservation>> getMy() async {
    final response = await _apiClient.dio.get(
      '/api/Reservations/my',
      queryParameters: {'pageSize': 100},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancel(int id, {String? reason}) async {
    await _apiClient.dio.put(
      '/api/Reservations/$id/cancel',
      data: {'reason': reason},
    );
  }

  Future<List<Reservation>> getForMyActivities() async {
    final response = await _apiClient.dio.get(
      '/api/Reservations/my-activities',
      queryParameters: {'pageSize': 100},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Reservation>> getForActivity(int activityId) async {
    final response = await _apiClient.dio.get(
      '/api/Reservations/activity/$activityId',
      queryParameters: {'pageSize': 100},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => Reservation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> confirm(int id) async {
    await _apiClient.dio.put('/api/Reservations/$id/confirm');
  }
}
