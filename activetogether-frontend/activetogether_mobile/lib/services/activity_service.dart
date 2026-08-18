import '../models/activity.dart';
import 'api_client.dart';

class ActivityService {
  final ApiClient _apiClient;

  ActivityService(this._apiClient);

  Future<Activity> getById(int id) async {
    final response = await _apiClient.dio.get('/api/Activities/$id');
    return Activity.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<Activity>> getAll({
    String? name,
    int? categoryId,
    int? cityId,
    bool? isFree,
    int pageSize = 30,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Activities',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (categoryId != null) 'categoryId': categoryId,
        if (cityId != null) 'cityId': cityId,
        if (isFree != null) 'isFree': isFree,
        'page': 1,
        'pageSize': pageSize,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['items'] as List)
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
