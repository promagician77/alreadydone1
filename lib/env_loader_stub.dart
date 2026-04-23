import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Web: load .env using default (asset path works on web).
Future<void> loadEnv() async {
  await dotenv.load(fileName: '.env');
}
