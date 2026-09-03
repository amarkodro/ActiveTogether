import '../models/category_option.dart';
import 'api_client.dart';

class CategoryService {
  final ApiClient _apiClient;

  CategoryService(this._apiClient);

  Future<List<CategoryOption>> getAll() async {
    final response = await _apiClient.dio.get('/api/Categories/lookup');
    return (response.data as List)
        .map((e) => CategoryOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
