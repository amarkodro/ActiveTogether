import 'api_client.dart';
import 'storage_service.dart';
import '../models/user.dart';

class AuthService {
  final ApiClient _apiClient;
  final StorageService _storageService;

  AuthService(this._apiClient, this._storageService);

  Future<AppUser> login(String username, String password) async {
    final response = await _apiClient.dio.post(
      '/api/Auth/login',
      data: {'username': username, 'password': password},
    );

    final data = response.data as Map<String, dynamic>;
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    await _storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storageService.saveUser(userJson);

    return AppUser.fromJson(userJson);
  }

  Future<AppUser> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    String? phoneNumber,
    int? cityId,
  }) async {
    await _apiClient.dio.post(
      '/api/Auth/register',
      data: {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'cityId': cityId,
      },
    );

    return login(username, password);
  }

  Future<void> logout() async {
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null) {
      try {
        await _apiClient.dio.post(
          '/api/Auth/logout',
          data: {'refreshToken': refreshToken},
        );
      } catch (_) {
        // ignoriši grešku, lokalni podaci se ionako brišu
      }
    }
    await _storageService.clearTokens();
  }
}
