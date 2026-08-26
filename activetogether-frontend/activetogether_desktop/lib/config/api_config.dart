class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5027',
  );

  /// Pretvara relativni URL slike (npr. "/uploads/activities/x.jpg") koji
  /// vraća backend u punu adresu pogodnu za prikaz (Image.network).
  static String? resolveImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return '$baseUrl$url';
  }
}
