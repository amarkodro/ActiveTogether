import '../models/reference_option.dart';
import 'api_client.dart';

class SimpleCrudService {
  final ApiClient _apiClient;
  final String endpoint;

  SimpleCrudService(this._apiClient, this.endpoint);

  Future<List<ReferenceOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/$endpoint');
    return (response.data as List)
        .map((e) => ReferenceOption.fromJson(e as Map<String, dynamic>))
        .toList();
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
