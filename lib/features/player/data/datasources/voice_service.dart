import 'dart:convert';

import '/core/network/backend_client.dart';

/// Default voice ID for TTS.
const String kDefaultVoiceId = 'Z7RrOqZFTyLpIlzCgfsp';

class VoiceService {
  VoiceService._();
  static Future<String?> speak({
    required int storyId,
    String voiceId = kDefaultVoiceId,
    String speed = 'normal',
  }) async {
    final body = <String, dynamic>{
      'voice_id': voiceId,
      'story_id': storyId,
      'narration_speed': speed,
    };

    final response = await BackendClient.client.post(
      BackendClient.resolve('/api/voice/speak'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    print('response: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception('Failed to get voice: ${response.statusCode} ${response.body}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final url = data['url'] as String?;
    return (url != null && url.isNotEmpty) ? url : null;
  }
}
