import '../models/paged_result.dart';
import '../models/recommended_activity.dart';
import 'api_client.dart';

class RecommendationService {
  final ApiClient _apiClient;

  RecommendationService(this._apiClient);

  Future<PagedResult<RecommendedActivity>> getRecommendations({
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Recommendations',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );

    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => RecommendedActivity.fromJson(json),
    );
  }
}
