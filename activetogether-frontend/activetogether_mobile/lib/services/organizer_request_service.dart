import 'api_client.dart';

class OrganizerRequestService {
  final ApiClient _apiClient;

  OrganizerRequestService(this._apiClient);

  Future<void> create() async {
    await _apiClient.dio.post('/api/OrganizerRequests');
  }
}
