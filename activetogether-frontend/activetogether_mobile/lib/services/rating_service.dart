import '../models/rating.dart';
import 'api_client.dart';

class RatingService {
  final ApiClient _apiClient;

  RatingService(this._apiClient);

  Future<void> create({
    required int reservationId,
    required int score,
    String? comment,
  }) async {
    await _apiClient.dio.post(
      '/api/Ratings',
      data: {
        'reservationId': reservationId,
        'score': score,
        'comment': comment,
      },
    );
  }

  Future<List<Rating>> getForActivity(int activityId) async {
    final response = await _apiClient.dio.get(
      '/api/Ratings/activity/$activityId',
    );
    final data = response.data as List;
    return data
        .map((e) => Rating.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
