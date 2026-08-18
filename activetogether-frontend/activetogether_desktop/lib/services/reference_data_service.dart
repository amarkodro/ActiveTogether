import '../models/location_option.dart';
import '../models/reference_option.dart';
import 'api_client.dart';

class ReferenceDataService {
  final ApiClient _apiClient;

  ReferenceDataService(this._apiClient);

  Future<List<ReferenceOption>> getCategories() async {
    final response = await _apiClient.dio.get('/api/Categories');
    return (response.data as List)
        .map((e) => ReferenceOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<ReferenceOption>> getActivityTypes() async {
    final response = await _apiClient.dio.get('/api/ActivityTypes');
    return (response.data as List)
        .map((e) => ReferenceOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LocationOption>> getLocations() async {
    final response = await _apiClient.dio.get('/api/Locations');
    return (response.data as List)
        .map((e) => LocationOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
