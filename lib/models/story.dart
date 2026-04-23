class Story {
  final int id;
  final String title;
  final String content;
  final String desireName;
  final String? playLength;
  final DateTime? lastPlayed;

  Story({
    required this.id,
    required this.title,
    required this.content,
    required this.desireName,
    this.playLength,
    this.lastPlayed,
  });

  factory Story.fromJson(Map<String, dynamic> json) {
    return Story(
      id: json['id'] as int,
      title: json['title'] as String,
      content: json['content'] as String,
      desireName: (json['desire_name'] as String?) ?? '',
      playLength: json['play_length'] as String?,
      lastPlayed: json['last_played'] != null
          ? DateTime.tryParse(json['last_played'] as String)
          : null,
    );
  }
}
