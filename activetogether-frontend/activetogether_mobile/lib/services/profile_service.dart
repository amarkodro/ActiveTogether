import '../models/profile.dart';
import 'api_client.dart';

class ProfileService {
  final ApiClient _apiClient;

  ProfileService(this._apiClient);

  Future<Profile> getMy() async {
    final response = await _apiClient.dio.get('/api/Profile');
    return Profile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Profile> update({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    int? cityId,
    String? profileImageUrl,
  }) async {
    final response = await _apiClient.dio.put(
      '/api/Profile',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'cityId': cityId,
        'profileImageUrl': profileImageUrl,
      },
    );
    return Profile.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _apiClient.dio.put(
      '/api/Profile/password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
