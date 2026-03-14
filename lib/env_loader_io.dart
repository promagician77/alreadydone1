import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// iOS/Android: load .env from asset bundle into a temp file, then load it.
/// Fixes TestFlight/Play Store crash where dotenv.load(fileName: ".env") cannot find the file.
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
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/.env');
  try {
    await file.writeAsString(content, flush: true);
  } catch (e) {
    throw Exception('Failed to write .env to temp dir: $e');
  }
  try {
    await dotenv.load(fileName: file.path);
  } catch (e) {
    throw Exception('Failed to parse .env: $e');
  }
}
