import '../models/organizer_request_item.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class OrganizerRequestService {
  final ApiClient _apiClient;

  OrganizerRequestService(this._apiClient);

  Future<PagedResult<OrganizerRequestItem>> getAll({
    String? status,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/OrganizerRequests',
      queryParameters: {
        if (status != null) 'status': status,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => OrganizerRequestItem.fromJson(json),
    );
  }

  Future<void> approve(int id) async {
    await _apiClient.dio.put('/api/OrganizerRequests/$id/approve');
  }

  Future<void> reject(int id, String reason) async {
    await _apiClient.dio.put(
      '/api/OrganizerRequests/$id/reject',
      data: {'reason': reason},
    );
  }
}
