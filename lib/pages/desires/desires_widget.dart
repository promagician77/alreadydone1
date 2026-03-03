import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/services/supabase_service.dart';
import '/services/backend_client.dart';
import '/pages/onboarding/onboarding_state.dart';
import 'desires_model.dart';
export 'desires_model.dart';

/// Design tokens from HTML (03 — Already Done Library)
class _DesiresColors {
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const gold = Color(0xFFB8861E);
  static const goldPale = Color(0xFFFBF4E6);
  static const blush = Color(0xFFD98B80);
  static const blushLight = Color(0xFFFDF0EE);
  static const sage = Color(0xFF7FA882);
  static const sageLight = Color(0xFFEEF4EE);
  static const teal = Color(0xFF4E8F9C);
  static const tealLight = Color(0xFFEAF4F6);
}

class _DesireCategory {
  final String id;
  final String name;
  final String eyebrow; // e.g. "Love", "Money"
  final Color accentColor;
  final Color iconBg;
  final List<_StoryItem> stories;

  _DesireCategory({
    required this.id,
    required this.name,
    required this.eyebrow,
    required this.accentColor,
    required this.iconBg,
    required this.stories,
  });
}

class _StoryItem {
  final int? id;
  final String name;
  final String meta; // e.g. "Today · 3:42"
  final String? storyContent; // story text for preview

  _StoryItem({this.id, required this.name, required this.meta, this.storyContent});
}

class DesiresWidget extends StatefulWidget {
  const DesiresWidget({super.key});

  static String routeName = 'Desires';
  static String routePath = '/desires';

  @override
  State<DesiresWidget> createState() => _DesiresWidgetState();
}

class _DesiresWidgetState extends State<DesiresWidget> { 
  late DesiresModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  int _selectedFilter = 0; // 0=All, 1..n=index into _desireCategories
  List<Map<String, String>> _desireCategories = []; // from GET /api/desires [{id, name}, ...]
  List<_DesireCategory> _categories = [];
  String? _headerCategory;
  String? _headerTitle;
  String? _headerCount;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DesiresModel());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Fetch desire categories from backend first
      List<Map<String, String>> desireCategories = [];
      try {
        final list = await BackendClient.getDesires();
        print('list: $list');
        desireCategories = list
            .map((e) {
              final name = (e['desireCategory'] ?? e['name'] ?? '').toString();
              return {
                'id': (e['id'] ?? '').toString(),
                'name': name,
              };
            })
            .where((m) => (m['id'] ?? '').isNotEmpty || (m['name'] ?? '').isNotEmpty)
            .toList();
      } catch (_) {
        // fallback to static list if API fails
        desireCategories = [
          {'id': '1', 'name': 'Love'},
          {'id': '2', 'name': 'Money'},
          {'id': '3', 'name': 'Career'},
          {'id': '4', 'name': 'Health'},
        ];
      }

      final userId = await SupabaseService.getCurrentUserTableId();
      List<_DesireCategory> categories = [];

      if (userId != null) {
        final res = await BackendClient.getStories(userId);
        final rawList = res['stories'];

        print('length: ${rawList.length}');

        final list = rawList is List ? List<dynamic>.from(rawList) : <dynamic>[];
        if (list.isNotEmpty) {
          final Map<int, List<Map<String, dynamic>>> byDesire = {};
          for (final s in list) {
            final m = s is Map ? Map<String, dynamic>.from(s as Map) : <String, dynamic>{};
            final did = _intFrom(m['desire_id']);
            if (did != null) {
              byDesire.putIfAbsent(did, () => []).add(m);
            }
          }
          const accents = [
            (_DesiresColors.blush, _DesiresColors.blushLight),
            (_DesiresColors.gold, _DesiresColors.goldPale),
            (_DesiresColors.teal, _DesiresColors.tealLight),
            (_DesiresColors.sage, _DesiresColors.sageLight),
          ];
          int idx = 0;
          for (final entry in byDesire.entries) {
            final items = entry.value;
            items.sort((a, b) {
              final aAt = (a['last_played'] ?? a['last_played_at'] ?? a['created_at'])?.toString() ?? '';
              final bAt = (b['last_played'] ?? b['last_played_at'] ?? b['created_at'])?.toString() ?? '';
              if (aAt.isEmpty || bAt.isEmpty) return 0;
              try {
                return DateTime.parse(bAt).compareTo(DateTime.parse(aAt));
              } catch (_) {
                return 0;
              }
            });
            final first = items.first;
            final desireName = ((first['desire_name'] as String?) ?? '').trim();
            final eyebrow = desireName.isNotEmpty ? desireName : 'Desire';
            final firstStoryTheme = (first['theme'] ?? first['title'] ?? first['name'])?.toString().trim();
            final cardTitle = (firstStoryTheme != null && firstStoryTheme.isNotEmpty)
                ? firstStoryTheme
                : eyebrow;
            final accent = accents[idx % accents.length];
            categories.add(_DesireCategory(
              id: entry.key.toString(),
              name: cardTitle,
              eyebrow: eyebrow,
              accentColor: accent.$1,
              iconBg: accent.$2,
              stories: items.map((s) {
                final themeTitle = (s['theme'] ?? s['title'] ?? s['name'])?.toString().trim();
                final storyContent = (s['story'] ?? s['content'])?.toString().trim();
                final firstLine = storyContent != null && storyContent.isNotEmpty
                    ? storyContent.split('\n').first.trim()
                    : null;
                final title = (themeTitle?.isNotEmpty == true) ? themeTitle! : (firstLine ?? 'Story');
                final playLength = (s['play_length'] ?? s['duration'])?.toString();
                final lastPlayed = (s['last_played'] ?? s['last_played_at'])?.toString();
                final meta = _formatStoryMeta(playLength, lastPlayed);
                return _StoryItem(
                  id: _intFrom(s['id']),
                  name: title,
                  meta: meta,
                  storyContent: storyContent,
                );
              }).toList(),
            ));
            idx++;
          }
        }
      }

      if (categories.isEmpty) {
        categories = _mockCategories();
      }

      if (!mounted) return;
      setState(() {
        _desireCategories = desireCategories;
        _categories = categories;
        if (categories.isNotEmpty) {
          _headerCategory = '${categories.first.eyebrow} · Already Complete';
          _headerTitle = categories.first.name;
          _headerCount =
              '${categories.first.stories.length} stories · All complete';
        } else {
          _headerCategory = 'Love · Already Complete';
          _headerTitle = 'A Deeply Loving Relationship';
          _headerCount = '5 stories · All complete';
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _desireCategories = [
          {'id': '1', 'name': 'Love'},
          {'id': '2', 'name': 'Money'},
          {'id': '3', 'name': 'Career'},
          {'id': '4', 'name': 'Health'},
        ];
        _categories = _mockCategories();
        _headerCategory = 'Love · Already Complete';
        _headerTitle = 'A Deeply Loving Relationship';
        _headerCount = '5 stories · All complete';
        _loading = false;
      });
    }
  }

  Future<void> _navigateToPlayerWithVoice(int storyId, String title, String categoryLabel, String durationLabel, [String? storyPreview]) async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
      return;
    }

    try {
      final profile = await BackendClient.getUserProfile(userId);
      final voiceId = profile['voice_id']?.toString() ?? profile['voice_Id']?.toString() ?? '';
      if (voiceId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice not available')));
        return;
      }

      final res = await BackendClient.voiceSpeak(voiceId: voiceId, storyId: storyId);
      final playUrl = res['url']?.toString();
      if (playUrl == null || playUrl.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load audio')));
        return;
      }

      if (mounted) {
        context.pushNamed(PlayerWidget.routeName, extra: {
          'storyId': storyId,
          'categoryLabel': categoryLabel,
          'title': title,
          'subtitle': '',
          'durationLabel': durationLabel,
          'playUrl': playUrl,
          if (storyPreview != null && storyPreview.isNotEmpty) 'storyPreview': storyPreview,
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  int? _intFrom(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Converts seconds (e.g. "137.93") to MM:SS format.
  String _formatDurationSeconds(String? playLength) {
    if (playLength == null || playLength.isEmpty) return '';
    final sec = double.tryParse(playLength);
    if (sec == null || sec < 0) return playLength;
    final totalSeconds = sec.round();
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatStoryMeta(String? playLength, String? lastPlayed) {
    final parts = <String>[];
    if (lastPlayed != null && lastPlayed.isNotEmpty) {
      try {
        final dt = DateTime.parse(lastPlayed);
        final now = DateTime.now();
        final diff = now.difference(dt);
        if (diff.inDays == 0) parts.add('Today');
        else if (diff.inDays == 1) parts.add('Yesterday');
        else if (diff.inDays < 7) parts.add('${diff.inDays}d ago');
        else parts.add('${diff.inDays ~/ 7}w ago');
      } catch (_) {
        parts.add('Recently');
      }
    } else {
      parts.add('Recently');
    }
    if (playLength != null && playLength.isNotEmpty) {
      final formatted = _formatDurationSeconds(playLength);
      if (formatted.isNotEmpty) parts.add(formatted);
    }
    return parts.join(' · ');
  }

  List<_DesireCategory> _mockCategories() {
    return [
      _DesireCategory(
        id: '1',
        name: 'A Deeply Loving Relationship',
        eyebrow: 'Love',
        accentColor: _DesiresColors.blush,
        iconBg: _DesiresColors.blushLight,
        stories: [
          _StoryItem(id: 1, name: "A Love That Was Already Yours", meta: "Today · 3:42"),
          _StoryItem(id: 2, name: "The Love You'd Always Known", meta: "2 days ago · 4:01"),
        ],
      ),
      _DesireCategory(
        id: '2',
        name: 'Financial Abundance',
        eyebrow: 'Money',
        accentColor: _DesiresColors.gold,
        iconBg: _DesiresColors.goldPale,
        stories: [
          _StoryItem(id: 3, name: "The Abundance That Arrived", meta: "Yesterday · 4:15"),
        ],
      ),
    ];
  }

  List<_DesireCategory> get _filteredCategories {
    if (_selectedFilter == 0) return _categories;
    final idx = _selectedFilter - 1;
    if (idx < 0 || idx >= _desireCategories.length) return _categories;
    final selectedId = _desireCategories[idx]['id'] ?? '';
    if (selectedId.isEmpty) return _categories;
    return _categories.where((c) => c.id == selectedId).toList();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _DesiresColors.surface,
        body: SafeArea(
          top: true,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
          child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 80),
            child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                        // Desire header
                        _buildHeader(),
                        const SizedBox(height: 20),

                        // Filter pills
                        _buildFilterPills(),
                        const SizedBox(height: 20),

                        // Story cards
                        ..._filteredCategories.map((c) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _buildStoryCard(c),
                            )),

                        // Add button
                        _buildAddButton(),
                            ],
                          ),
                        ),
                            ),
                          ),
                        ),
    );
  }

  Widget _buildHeader() {
    final filtered = _filteredCategories;
    final totalStories = filtered.fold<int>(0, (n, c) => n + c.stories.length);
    final pills = ['All', ..._desireCategories.map((e) => e['name']!).where((s) => s.isNotEmpty)];
    String categoryLabel;
    String titleLabel;
    if (_selectedFilter == 0) {
      categoryLabel = filtered.isNotEmpty ? '${filtered.first.eyebrow} · Already Complete' : 'Love · Already Complete';
      titleLabel = filtered.isNotEmpty ? filtered.first.name : (_headerTitle ?? 'A Deeply Loving\nRelationship');
    } else if (_selectedFilter > 0 && _selectedFilter < pills.length) {
      final desireName = pills[_selectedFilter];
      categoryLabel = '$desireName · Already Complete';
      titleLabel = filtered.isNotEmpty ? filtered.first.name : (_headerTitle ?? desireName);
    } else {
      categoryLabel = _headerCategory ?? 'Love · Already Complete';
      titleLabel = _headerTitle ?? 'A Deeply Loving\nRelationship';
    }
    final countLabel = '$totalStories stories · All complete';

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            categoryLabel.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: _DesiresColors.blush,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            titleLabel,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w400,
              color: _DesiresColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            countLabel,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: _DesiresColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills() {
    final pills = ['All', ..._desireCategories.map((e) => e['name']!).where((s) => s.isNotEmpty)];
    if (pills.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pills.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final active = _selectedFilter == i;
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = i),
                                child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                color: active ? _DesiresColors.goldPale : _DesiresColors.surface,
                                    border: Border.all(
                  color: active ? _DesiresColors.gold : _DesiresColors.stone,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                                      child: Text(
                  pills[i],
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: active ? _DesiresColors.gold : _DesiresColors.inkSoft,
                  ),
                                            ),
                                      ),
                                    ),
          );
        },
      ),
    );
  }

  Widget _buildStoryCard(_DesireCategory cat) {
    return Container(
      padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
        color: _DesiresColors.surface,
        border: Border.all(color: _DesiresColors.stone),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesiresColors.ink.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
                            ),
                            child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
          Text(
            '${cat.eyebrow} · Already Done',
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.5,
                                                  fontWeight: FontWeight.w600,
              color: cat.accentColor,
            ),
          ),
          const SizedBox(height: 14),
          Container(height: 1, color: _DesiresColors.stone),
          const SizedBox(height: 14),
          ...cat.stories.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _buildStoryItem(s, cat.iconBg, cat.accentColor, '${cat.eyebrow} · Already Done'),
                                      ),
                                    ),
                                  ],
                                ),
    );
  }

  Widget _buildStoryItem(
      _StoryItem story, Color iconBg, Color accentColor, String categoryLabel) {
    return GestureDetector(
      onTap: () {
        if (story.id != null) {
          _navigateToPlayerWithVoice(story.id!, story.name, categoryLabel, story.meta, story.storyContent);
        }
      },
                                        child: Row(
                                          children: [
                                            Container(
            width: 42,
            height: 42,
                                              decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
                                                                  child: Text(
                '✓',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                                                                              fontWeight: FontWeight.w600,
                  color: _DesiresColors.ink,
                ),
                                                                          ),
                                                                    ),
                                                                  ),
          const SizedBox(width: 12),
          Expanded(
                            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                Text(
                  story.name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                    color: _DesiresColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  story.meta,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: _DesiresColors.inkSoft,
                                      ),
                                    ),
                                  ],
                                ),
          ),
                                      Container(
            width: 32,
            height: 32,
                                        decoration: BoxDecoration(
              color: _DesiresColors.warmWhite,
              border: Border.all(color: _DesiresColors.stone),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, size: 16, color: _DesiresColors.ink),
                                                              ),
                                                            ],
                                                          ),
    );
  }

  /// Navigate to onboarding desire page (3rd step); prefill first name and someone you love from user profile.
  Future<void> _handleAddNewManifestation() async {
    if (!mounted) return;
    context.go(OnboardingDesireWidget.routePath, extra: {'fromDesires': true});
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: _handleAddNewManifestation,
                          child: Container(
        margin: const EdgeInsets.only(top: 20),
                            width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
          color: _DesiresColors.gold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: _DesiresColors.surface, size: 18),
            const SizedBox(width: 8),
            Text(
              'Add New Manifestation',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _DesiresColors.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
