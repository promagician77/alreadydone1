import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path_provider/path_provider.dart';

/// iOS/Android: load .env from asset bundle into a temp file, then load it.
/// Fixes TestFlight/Play Store crash where dotenv.load(fileName: ".env") cannot find the file.
Future<void> loadEnv() async {
  final content = await rootBundle.loadString('.env');
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/.env');
  await file.writeAsString(content);
  await dotenv.load(fileName: file.path);
}
