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
}
