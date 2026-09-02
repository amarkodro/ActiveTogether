import '../models/activity.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class FavoriteService {
  final ApiClient _apiClient;

  FavoriteService(this._apiClient);

  Future<PagedResult<Activity>> getMy({int page = 1, int pageSize = 20}) async {
    final response = await _apiClient.dio.get(
      '/api/Favorites/my',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => Activity.fromJson(json),
    );
  }

  Future<bool> getStatus(int activityId) async {
    final response = await _apiClient.dio.get(
      '/api/Favorites/$activityId/status',
    );
    return response.data as bool;
  }

  Future<void> add(int activityId) async {
    await _apiClient.dio.post('/api/Favorites/$activityId');
  }

  Future<void> remove(int activityId) async {
    await _apiClient.dio.delete('/api/Favorites/$activityId');
  }
}
