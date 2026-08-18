import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final StorageService _storageService;

  AuthProvider(this._authService, this._storageService);

  AuthStatus status = AuthStatus.unknown;
  AppUser? currentUser;
  String? errorMessage;
  bool isLoading = false;

  Future<void> tryAutoLogin() async {
    final token = await _storageService.getAccessToken();
    final userJson = await _storageService.getUser();

    if (token != null && userJson != null) {
      currentUser = AppUser.fromJson(
        jsonDecode(userJson) as Map<String, dynamic>,
      );
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.login(username, password);
      currentUser = user;
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
    String? phoneNumber,
    int? cityId,
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final user = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        cityId: cityId,
      );
      currentUser = user;
      status = AuthStatus.authenticated;
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _extractErrorMessage(e);
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  String _extractErrorMessage(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        return 'Ne mogu da se povežem sa serverom. Provjerite internet konekciju.';
      }
    }
    return 'Došlo je do greške. Pokušajte ponovo.';
  }
}
