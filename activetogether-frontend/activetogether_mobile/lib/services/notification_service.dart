import '../models/app_notification.dart';
import 'api_client.dart';

class NotificationService {
  final ApiClient _apiClient;

  NotificationService(this._apiClient);

  Future<List<AppNotification>> getMy() async {
    final response = await _apiClient.dio.get(
      '/api/Notifications/my',
      queryParameters: {'pageSize': 100},
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> getUnreadCount() async {
    final response = await _apiClient.dio.get(
      '/api/Notifications/unread-count',
    );
    return response.data as int;
  }

  Future<void> markAsRead(int id) async {
    await _apiClient.dio.put('/api/Notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _apiClient.dio.put('/api/Notifications/read-all');
  }
}
