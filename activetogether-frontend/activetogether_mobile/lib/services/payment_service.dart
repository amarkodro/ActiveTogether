import 'api_client.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService(this._apiClient);

  Future<void> confirm(int reservationId) async {
    await _apiClient.dio.put('/api/Payments/$reservationId/confirm');
  }
}
