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
}
