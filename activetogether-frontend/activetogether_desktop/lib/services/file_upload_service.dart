import 'package:dio/dio.dart';
import 'api_client.dart';

/// Servis za otpremanje slika (profil ili aktivnost) na backend.
/// Vraća relativni URL slike (npr. "/uploads/activities/xxx.jpg") koji se
/// zatim šalje kao imageUrl uz odgovarajući zahtjev.
class FileUploadService {
  final ApiClient _apiClient;

  FileUploadService(this._apiClient);

  Future<String> uploadImage({
    required String filePath,
    required String type, // 'profile' ili 'activity'
  }) async {
    final fileName = filePath.split(RegExp(r'[\\/]')).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });

    final response = await _apiClient.dio.post(
      '/api/Files/upload',
      data: formData,
      queryParameters: {'type': type},
    );

    return response.data['url'] as String;
  }
}
