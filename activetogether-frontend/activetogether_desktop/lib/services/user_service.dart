import '../models/paged_result.dart';
import '../models/user_list_item.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _apiClient;

  UserService(this._apiClient);

  Future<PagedResult<UserListItem>> getAll({
    String? name,
    String? role,
    bool? isActive,
    int page = 1,
    int pageSize = 10,
  }) async {
    final response = await _apiClient.dio.get(
      '/api/Users',
      queryParameters: {
        if (name != null && name.isNotEmpty) 'name': name,
        if (role != null) 'role': role,
        if (isActive != null) 'isActive': isActive,
        'page': page,
        'pageSize': pageSize,
      },
    );

    return PagedResult.fromJson(
      response.data as Map<String, dynamic>,
      (json) => UserListItem.fromJson(json),
    );
  }

  Future<void> update(
    int id, {
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    int? cityId,
  }) async {
    await _apiClient.dio.put(
      '/api/Users/$id',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phoneNumber': phoneNumber,
        'cityId': cityId,
      },
    );
  }

  Future<void> setActive(int id, bool isActive) async {
    final action = isActive ? 'activate' : 'block';
    await _apiClient.dio.put('/api/Users/$id/$action');
  }
}
