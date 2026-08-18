import 'package:dio/dio.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class ApiClient {
  final StorageService _storageService;
  late final Dio dio;
  late final Dio _refreshDio;

  bool _isRefreshing = false;

  ApiClient(this._storageService) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    _refreshDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storageService.getAccessToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException error, handler) async {
          final isRefreshCall = error.requestOptions.path.contains(
            '/api/Auth/refresh',
          );

          if (error.response?.statusCode == 401 && !isRefreshCall) {
            try {
              final newToken = await _refreshAccessToken();
              if (newToken != null) {
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newToken';
                final response = await dio.fetch(retryOptions);
                return handler.resolve(response);
              }
            } catch (_) {
              // refresh nije uspio, nastavljamo na grešku ispod
            }
            await _storageService.clearTokens();
          }

          handler.next(error);
        },
      ),
    );
  }

  Future<String?> _refreshAccessToken() async {
    if (_isRefreshing) {
      await Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 100));
        return _isRefreshing;
      });
      return _storageService.getAccessToken();
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) return null;

      final response = await _refreshDio.post(
        '/api/Auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      final newAccessToken = response.data['accessToken'] as String;
      final newRefreshToken = response.data['refreshToken'] as String;

      await _storageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );

      return newAccessToken;
    } finally {
      _isRefreshing = false;
    }
  }
}
