import '../models/paged_result.dart';
import '../models/reference_option.dart';
import 'api_client.dart';

class SimpleCrudService {
  final ApiClient _apiClient;
  final String endpoint;

  SimpleCrudService(this._apiClient, this.endpoint);

  /// Kompletan (neparaginiran) spisak — za dropdown/lookup prikaze.
  Future<List<ReferenceOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/$endpoint/lookup');
    return (response.data as List)
        .map((e) => ReferenceOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Paginirana, pretraživa administratorska lista.
  Future<PagedResult<ReferenceOption>> getPaged({
    String? name,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/$endpoint',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => ReferenceOption.fromJson(json),
    );
  }

  Future<void> create(String name) async {
    await _apiClient.dio.post('/api/$endpoint', data: {'name': name});
  }

  Future<void> update(int id, String name) async {
    await _apiClient.dio.put('/api/$endpoint/$id', data: {'name': name});
  }

  Future<void> delete(int id) async {
    await _apiClient.dio.delete('/api/$endpoint/$id');
  }
}
