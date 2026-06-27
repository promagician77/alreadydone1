import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Map<String, String> _parseEnvContent(String content) {
  final result = <String, String>{};
  for (final line in content.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final idx = trimmed.indexOf('=');
    if (idx <= 0) continue;
    final key = trimmed.substring(0, idx).trim();
    var value = trimmed.substring(idx + 1).trim();
    if (value.startsWith("'") && value.endsWith("'") && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    } else if (value.startsWith('"') && value.endsWith('"') && value.length >= 2) {
      value = value.substring(1, value.length - 1);
    }
    if (key.isNotEmpty) result[key] = value;
  }
  return result;
}

Future<void> loadEnv() async {
  String content;
  try {
    content = await rootBundle.loadString('.env');
  } catch (e) {
    throw Exception('Failed to load .env from assets (check pubspec.yaml has "assets: - .env"): $e');
  }
  if (content.isEmpty) {
    throw Exception('Asset .env is empty');
  }
  try {
    final parsed = _parseEnvContent(content);
    await dotenv.load(mergeWith: parsed);
  } catch (e) {
    throw Exception('Failed to parse .env: $e');
  }
}
