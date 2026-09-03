import '../models/location_option.dart';
import '../models/paged_result.dart';
import 'api_client.dart';

class LocationService {
  final ApiClient _apiClient;

  LocationService(this._apiClient);

  /// Kompletan (neparaginiran) spisak lokacija — za dropdown/lookup prikaze.
  Future<List<LocationOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/Locations/lookup');
    return (response.data as List)
        .map((e) => LocationOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Paginirana, pretraživa administratorska lista lokacija.
  Future<PagedResult<LocationOption>> getPaged({
    String? name,
    int? cityId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Locations',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (cityId != null) 'cityId': cityId,
        'page': page,
        'pageSize': pageSize,
      },
    );
    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => LocationOption.fromJson(json),
    );
  }

  Future<LocationOption> create({
    required String name,
    required String address,
    required int cityId,
    required double latitude,
    required double longitude,
  }) async {
    final response = await _apiClient.dio.post(
      '/api/Locations',
      data: {
        'name': name,
        'address': address,
        'cityId': cityId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
    return LocationOption.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> update(
    int id, {
    required String name,
    required String address,
    required int cityId,
    required double latitude,
    required double longitude,
  }) async {
    await _apiClient.dio.put(
      '/api/Locations/$id',
      data: {
        'name': name,
        'address': address,
        'cityId': cityId,
        'latitude': latitude,
        'longitude': longitude,
      },
    );
  }

  Future<void> delete(int id) async {
    await _apiClient.dio.delete('/api/Locations/$id');
  }
}
