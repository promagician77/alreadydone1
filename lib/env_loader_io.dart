import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    dotenv.loadFromString(fileInput: content);
  } catch (e) {
    throw Exception('Failed to parse .env: $e');
  }
}
