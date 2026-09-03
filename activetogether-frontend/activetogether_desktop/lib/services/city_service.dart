import '../models/city_option.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class CityService {
  final ApiClient _apiClient;

  CityService(this._apiClient);

  /// Kompletan (neparaginiran) spisak gradova — za dropdown/lookup prikaze.
  Future<List<CityOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/Cities/lookup');
    return (response.data as List)
        .map((e) => CityOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Paginirana, pretraživa administratorska lista gradova.
  Future<PagedResult<CityOption>> getPaged({
    String? name,
    int? countryId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Cities',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (countryId != null) 'countryId': countryId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => CityOption.fromJson(json),
    );
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
