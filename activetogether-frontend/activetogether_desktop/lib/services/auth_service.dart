import 'dart:convert';
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

    final accessToken = response.data['accessToken'] as String;
    final refreshToken = response.data['refreshToken'] as String;
    final userJson = response.data['user'] as Map<String, dynamic>;

    await _storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
    await _storageService.saveUser(jsonEncode(userJson));

    return AppUser.fromJson(userJson);
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
        // i ako poziv ne uspije, lokalno ipak brišemo tokene
      }
    }
    await _storageService.clearTokens();
  }
}
