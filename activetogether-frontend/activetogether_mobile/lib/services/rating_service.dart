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
}
