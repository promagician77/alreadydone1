import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

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

  /// PATCH api/users/{user_id} - update user profile.
  /// Body: { speed?, is_MorningTime_Reminder?, is_BedTime_Reminder?, name?, location?, energyWord?, lovedOne?, fcm_token?, ... }.
  static Future<Map<String, dynamic>> updateUserProfile(
    int userId, {
    String? speed,
    bool? isMorningReminder,
    bool? isBedtimeReminder,
    String? morningTimeReminder,
    String? bedtimeReminder,
    String? timezone,
    String? name,
    String? email,
    String? dreamPlace,
    String? location,
    String? energyWord,
    String? someoneYouLove,
    String? fcmToken,
  }) async {
    final body = <String, dynamic>{};
    if (speed != null) body['speed'] = speed;
    if (isMorningReminder != null) body['is_MorningTime_Reminder'] = isMorningReminder;
    if (isBedtimeReminder != null) body['is_BedTime_Reminder'] = isBedtimeReminder;
    if (morningTimeReminder != null) body['morningTime_Reminder'] = morningTimeReminder;
    if (bedtimeReminder != null) body['bedTime_Reminder'] = bedtimeReminder;
    if (timezone != null) body['timezone'] = timezone;
    if (name != null) body['name'] = name;
    if (email != null) body['email'] = email;
    if (dreamPlace != null) body['dream_place'] = dreamPlace;
    if (location != null) body['location'] = location;
    if (energyWord != null) body['energyWord'] = energyWord;
    if (someoneYouLove != null) body['lovedOne'] = someoneYouLove;
    if (fcmToken != null) body['fcm_token'] = fcmToken;
    if (body.isEmpty) return {'updated': true};
    final response = await client
        .patch(
          resolve('/api/users/$userId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Profile update timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception('Profile update failed: ${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'updated': true};
  }

  /// GET api/users/{user_id} - get user profile.
  /// Returns { id, name, email, voice_id, speed, is_MorningTime_Reminder, is_BedTime_Reminder, location, energyWord, lovedOne, ... }.
  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    final uri = resolve('/api/users/$userId');
    final response = await client.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Profile request timeout'),
    );
    if (response.statusCode >= 400) {
      throw Exception('Profile failed: ${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  /// GET api/stories?user_id=<int> - list stories for user.
  /// Returns { "stories": [ { id, theme, story, desire_id, user_id, last_played, play_length?, playUrl, storage, desire_name, ... } ] }
  static Future<Map<String, dynamic>> getStories(int userId) async {
    final uri = resolve('/api/stories').replace(queryParameters: {'user_id': userId.toString()});
    final response = await client.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Stories request timeout'),
    );
    if (response.statusCode >= 400) {
      throw Exception('Stories failed: ${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'stories': []};
  }

  /// DELETE api/stories/{story_id} - delete a story.
  static Future<void> deleteStory(int storyId) async {
    final response = await client
        .delete(resolve('/api/stories/$storyId'))
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Delete story timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception('Delete failed: ${response.statusCode} ${response.body}');
    }
  }

  /// GET api/desires - list desire categories. Returns [ { id, desireCategory, name }, ... ].
  /// API uses desireCategory; we also expose as name for compatibility.
  static Future<List<Map<String, dynamic>>> getDesires() async {
    final uri = resolve('/api/desires');
    final response = await client.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Desires request timeout'),
    );
    if (response.statusCode >= 400) {
      throw Exception('Desires failed: ${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    final list = decoded is List
        ? decoded
        : (decoded is Map ? decoded['desires'] : null);
    if (list is! List) return [];
    return list
        .map<Map<String, dynamic>>((e) {
          if (e is! Map) return {'id': '', 'name': '', 'desireCategory': ''};
          final cat = (e['desireCategory'] ?? e['name'] ?? '').toString();
          return {
            'id': (e['id'] ?? '').toString(),
            'desireCategory': cat,
            'name': cat,
          };
        })
        .where((m) => m['id']!.isNotEmpty || m['name']!.isNotEmpty)
        .toList();
  }

  /// POST api/stories/generate - generate story from onboarding data.
  /// Sends body: { user_id, name, location, energyWord, desireCategory,
  ///   desireDescription, lovedOne? }.
  /// Returns decoded JSON (e.g. id, content, category, title).
  static Future<Map<String, dynamic>> generateStory(
    Map<String, dynamic> body,
  ) async {
    final response = await client
        .post(
          resolve('/api/stories/generate'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception('Generation timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception('Generate failed: ${response.statusCode} ${response.body}');
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'story': decoded};
  }

  /// POST api/voice/clone - upload audio file(s) for voice cloning.
  /// Matches backend: Form fields user_id, name, gender (optional); File field "files" with audio/* Content-Type.
  /// Returns { "voice_id": "...", "requires_verification": bool }.
  static Future<Map<String, dynamic>> uploadVoiceClone({
    required int userId,
    required String name,
    required File audioFile,
    String? gender,
  }) async {
    final uri = resolve('/api/voice/clone');
    final filename = audioFile.path.split(RegExp(r'[/\\]')).last;
    final isM4a = filename.toLowerCase().endsWith('.m4a');
    final contentType = isM4a
        ? MediaType('audio', 'mp4')
        : MediaType('audio', 'mpeg');
    final request = http.MultipartRequest('POST', uri)
      ..fields['user_id'] = userId.toString()
      ..fields['name'] = name;
    if (gender != null && gender.isNotEmpty) {
      request.fields['gender'] = gender;
    }
    request.files.add(await http.MultipartFile.fromPath(
      'files',
      audioFile.path,
      filename: filename,
      contentType: contentType,
    ));

    final streamed = await request.send().timeout(
          const Duration(seconds: 120),
          onTimeout: () => throw Exception('Voice upload timeout'),
        );
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode >= 400) {
      throw Exception(
        'Voice upload failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'voice_id': null};
  }

  /// POST api/voice/speak - get public URL for story audio.
  /// Input: voice_id, story_id (int).
  /// Returns { "url": public_url }.
  static Future<Map<String, dynamic>> voiceSpeak({
    required String voiceId,
    required int storyId,
  }) async {
    final response = await client
        .post(
          resolve('/api/voice/speak'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'voice_id': voiceId, 'story_id': storyId}),
        )
        .timeout(
          const Duration(seconds: 60),
          onTimeout: () => throw Exception('Voice speak timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception(
        'Voice speak failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'url': null};
  }

  /// POST api/voice/generate_audio - generate story audio (TTS), store, return URL.
  /// Request: voice_id, story_id, model_id (default eleven_multilingual_v2), narration_speed (default normal).
  /// Returns { "url": public_url, "content_type": content_type }. Use url for playback.
  static Future<Map<String, dynamic>> voiceGenerateAudio({
    required String voiceId,
    required int storyId,
    String modelId = 'eleven_multilingual_v2',
    String narrationSpeed = 'normal',
  }) async {
    final response = await client
        .post(
          resolve('/api/voice/generate_audio'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'voice_id': voiceId,
            'story_id': storyId,
            'model_id': modelId,
            'narration_speed': narrationSpeed,
          }),
        )
        .timeout(
          const Duration(seconds: 90),
          onTimeout: () => throw Exception('Voice generate audio timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception(
        'Voice generate audio failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'url': null, 'content_type': null};
  }

  /// GET api/voice/speak/{story_id} - return existing play URL for a story (no generation).
  /// Returns { "playUrl": play_url }. Throws on 404 (story not found or no playUrl yet).
  static Future<Map<String, dynamic>> getStoryPlayUrl(int storyId) async {
    final uri = resolve('/api/voice/speak/$storyId');
    final response = await client.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Get play URL timeout'),
    );
    if (response.statusCode == 404) {
      throw Exception('Story not found or has no play URL yet');
    }
    if (response.statusCode >= 400) {
      throw Exception(
        'Get play URL failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {'playUrl': null};
  }

  /// GET api/voice/preview?voice_id=<id> - get voice preview audio (bytes).
  /// Returns (audio_bytes, content_type). Backend returns Response(content=audio_bytes, media_type=content_type).
  static Future<({Uint8List bytes, String? contentType})> voicePreview(
    String voiceId,
  ) async {
    final uri = resolve('/api/voice/preview')
        .replace(queryParameters: {'voice_id': voiceId});
    final response = await client.get(uri).timeout(
      const Duration(seconds: 30),
      onTimeout: () => throw Exception('Voice preview timeout'),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        'Voice preview failed: ${response.statusCode} ${response.body}',
      );
    }
    final contentType = response.headers['content-type'];
    return (bytes: response.bodyBytes, contentType: contentType);
  }

  /// GET api/subscription/status?user_id=<int>
  /// Returns { stripe_customer_id, stripe_subscription_id, intent_id, subscription_status, subscription_plan }.
  static Future<Map<String, dynamic>> getSubscriptionStatus(int userId) async {
    final uri = resolve('/api/subscription/status')
        .replace(queryParameters: {'user_id': userId.toString()});
    final response = await client.get(uri).timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('Subscription status timeout'),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        'Subscription status failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<Map<String, dynamic>> createSetupIntent({
    required int userId,
    required String customerEmail,
  }) async {
    final response = await client
        .post(
          resolve('/api/subscription/setup-intent'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'customer_email': customerEmail.trim(),
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Setup intent timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception(
        'Setup intent failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  static Future<Map<String, dynamic>> createSubscription({
    required int userId,
    required String plan,
    required String setupIntentId,
    String? customerEmail,
  }) async {
    final body = <String, dynamic>{
      'user_id': userId,
      'plan': plan,
      'setup_intent_id': setupIntentId.trim(),
    };
    if (customerEmail != null && customerEmail.trim().isNotEmpty) {
      body['customer_email'] = customerEmail.trim();
    }
    final response = await client
        .post(
          resolve('/api/subscription/create'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Create subscription timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception(
        'Create subscription failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  /// POST api/subscription/change-plan
  /// Body: { "user_id": int, "plan": "Annual" }. Changes existing subscription plan (e.g. monthly → annual).
  static Future<Map<String, dynamic>> changeSubscriptionPlan({
    required int userId,
    required String plan,
  }) async {
    final response = await client
        .post(
          resolve('/api/subscription/change-plan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'user_id': userId,
            'plan': plan,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Change plan timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception(
        'Change plan failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }

  /// POST /subscription/cancel
  /// Body: { "user_id": int }. Cancels subscription / trial so user is not charged.
  static Future<Map<String, dynamic>> cancelSubscription({required int userId}) async {
    final response = await client
        .post(
          resolve('/api/subscription/cancel'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'user_id': userId}),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('Cancel subscription timeout'),
        );
    if (response.statusCode >= 400) {
      throw Exception(
        'Cancel failed: ${response.statusCode} ${response.body}',
      );
    }
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : {};
  }
}
