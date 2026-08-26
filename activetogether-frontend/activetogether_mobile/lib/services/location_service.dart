import '../models/location_option.dart';
import 'api_client.dart';

class LocationService {
  final ApiClient _apiClient;

  LocationService(this._apiClient);

  Future<List<LocationOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/Locations');
    return (response.data as List)
        .map((e) => LocationOption.fromJson(e as Map<String, dynamic>))
        .toList();
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
}
