import '../models/activity_list_item.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class ActivityService {
  final ApiClient _apiClient;

  ActivityService(this._apiClient);

  Future<PagedResult<ActivityListItem>> getAll({
    String? name,
    int? categoryId,
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Activities',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (categoryId != null) 'categoryId': categoryId,
        if (status != null) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ActivityListItem.fromJson(json),
    );
  }

  Future<void> update(
    int id, {
    required String name,
    required String description,
    required int categoryId,
    required int activityTypeId,
    required int locationId,
    required DateTime dateTime,
    required int capacity,
    required bool isFree,
    double? price,
    String? imageUrl,
  }) async {
    await _apiClient.dio.put(
      '/api/Activities/$id',
      data: {
        'name': name,
        'description': description,
        'categoryId': categoryId,
        'activityTypeId': activityTypeId,
        'locationId': locationId,
        'dateTime': dateTime.toIso8601String(),
        'capacity': capacity,
        'isFree': isFree,
        'price': price,
        'imageUrl': imageUrl,
      },
    );
  }

  Future<void> cancel(int id) async {
    await _apiClient.dio.put('/api/Activities/$id/cancel');
  }
}
