import '../models/city_option.dart';
import 'api_client.dart';

class CityService {
  final ApiClient _apiClient;

  CityService(this._apiClient);

  Future<List<CityOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/Cities');
    return (response.data as List)
        .map((e) => CityOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(String name, int countryId) async {
    await _apiClient.dio.post(
      '/api/Cities',
      data: {'name': name, 'countryId': countryId},
    );
  }

  Future<void> update(int id, String name, int countryId) async {
    await _apiClient.dio.put(
      '/api/Cities/$id',
      data: {'name': name, 'countryId': countryId},
    );
  }

  Future<void> delete(int id) async {
    await _apiClient.dio.delete('/api/Cities/$id');
  }
}
