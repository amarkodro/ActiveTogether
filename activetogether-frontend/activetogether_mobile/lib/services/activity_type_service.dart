import '../models/activity_type_option.dart';
import 'api_client.dart';

class ActivityTypeService {
  final ApiClient _apiClient;

  ActivityTypeService(this._apiClient);

  Future<List<ActivityTypeOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/ActivityTypes/lookup');
    return (response.data as List)
        .map((e) => ActivityTypeOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
