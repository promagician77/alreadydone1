import 'dart:async';
import 'dart:convert';
import 'dart:io' show File, FileMode, HttpClient, Platform;

import 'package:flutter/foundation.dart';

const _sessionId = '146b1c';
const _logPath =
    '/home/sebastian/Documents/Already Done/.cursor/debug-146b1c.log';
const _endpoint =
    'http://127.0.0.1:7592/ingest/4164bd9e-bdbd-463f-958c-2eb0330e149c';

void agentDebugLog({
  required String location,
  required String message,
  required String hypothesisId,
  Map<String, dynamic>? data,
  String runId = 'pre-fix',
}) {
  final payload = <String, dynamic>{
    'sessionId': _sessionId,
    'id': 'log_${DateTime.now().millisecondsSinceEpoch}',
    'timestamp': DateTime.now().millisecondsSinceEpoch,
    'location': location,
    'message': message,
    'hypothesisId': hypothesisId,
    'runId': runId,
    if (data != null) 'data': data,
  };
  final line = jsonEncode(payload);
  debugPrint('[DEBUG-146b1c] $line');

  // #region agent log
  if (!kIsWeb) {
    try {
      if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
        File(_logPath).writeAsStringSync('$line\n', mode: FileMode.append);
      }
    } catch (_) {}

    unawaited(() async {
      try {
        final client = HttpClient();
        final request = await client.postUrl(Uri.parse(_endpoint));
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('X-Debug-Session-Id', _sessionId);
        request.write(line);
        final response = await request.close();
        await response.drain();
        client.close();
      } catch (_) {}
    }());
  }
  // #endregion
}
