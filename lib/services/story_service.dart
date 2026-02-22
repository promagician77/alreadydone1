import 'dart:convert';
import 'dart:math';

import '/models/story.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';

class StoryService {
  static Future<List<Story>> fetchStories() async {
    // final userId = SupabaseService.currentUser?.id;
    final userId = "1";
    final uri = BackendClient.resolve('/api/stories')
        .replace(queryParameters: {'user_id': userId ?? ''});
    final response = await BackendClient.client.get(uri);

    print("Backend Response");
    print(response.body);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final List<dynamic> list = data['stories'] as List<dynamic>;
      return list
          .map((json) => Story.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Failed to load stories (${response.statusCode})');
    }
  }

  /// Fetches all stories and returns one picked at random.
  static Future<Story> fetchRandomStory() async {
    final stories = await fetchStories();
    if (stories.isEmpty) throw Exception('No stories available');
    return stories[Random().nextInt(stories.length)];
  }
}
