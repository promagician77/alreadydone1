import 'package:http/http.dart' as http;

class BackendClient {
  BackendClient._();

  static String _baseUrl = _defaultBaseUrl;

  static const String _defaultBaseUrl = 'http://10.0.2.2:8000';

  static void initialize({String? baseUrl}) {
    _baseUrl = (baseUrl ?? _defaultBaseUrl).replaceAll(RegExp(r'/$'), '');
  }

  static String get baseUrl => _baseUrl;

  static http.Client get client => http.Client();

  static Uri resolve(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_baseUrl$p');
  }

  static Future<bool> checkConnection() async {
    try {
      final response = await client.get(resolve('/health')).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw Exception('timeout'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
