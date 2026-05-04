import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/services/supabase_service.dart';
import '/services/backend_client.dart';
import '/services/app_toast.dart';
import '/services/ai_consent_service.dart';
import '/pages/onboarding/onboarding_state.dart';
import '/widgets/pressable.dart';
import 'desires_model.dart';
export 'desires_model.dart';

/// Design tokens from HTML (03 — Already Done Library + delete mode)
class _DesiresColors {
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const gold = Color(0xFFB8861E);
  static const goldDark = Color(0xFF8B6914);
  static const goldLight = Color(0xFFD4A574);
  static const goldPale = Color(0xFFFBF4E6);
  static const offWhite = Color(0xFFF2F0ED);
  static const blush = Color(0xFFD98B80);
  static const blushLight = Color(0xFFFDF0EE);
  static const sage = Color(0xFF7FA882);
  static const sageLight = Color(0xFFEEF4EE);
  static const teal = Color(0xFF4E8F9C);
  static const tealLight = Color(0xFFEAF4F6);
  // Delete mode (from HTML design)
  static const red = Color(0xFFDC2626);
  static const redDark = Color(0xFF991B1B);
  static const redPale = Color(0xFFFEE2E2);
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
  final String? voiceId; // voice used for this story (from story, not profile)

  _StoryItem({this.id, required this.name, required this.meta, this.storyContent, this.voiceId});
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
  /// Story id currently in "swipe left" delete mode (red card).
  int? _storyIdInDeleteMode;
  /// Story selected for delete confirmation modal.
  _StoryItem? _storyToDeleteForModal;
  bool _isDeleting = false;

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
                final voiceId = (s['voice_id'] ?? s['voice_Id'])?.toString().trim();
                return _StoryItem(
                  id: _intFrom(s['id']),
                  name: title,
                  meta: meta,
                  storyContent: storyContent,
                  voiceId: voiceId != null && voiceId.isNotEmpty ? voiceId : null,
                );
              }).toList(),
            ));
            idx++;
          }
        }
      }

      // When API returns no stories, show empty state — do not use mock data.
      // Mock categories are only used when the API fails (see catch block).

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
          _headerCategory = 'Your Library';
          _headerTitle = 'No manifestations yet';
          _headerCount = '0 manifestations created';
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

  Future<void> _navigateToPlayerWithVoice(int storyId, String title, String categoryLabel, String durationLabel, [String? storyPreview, String? storyVoiceId]) async {
    final userId = await SupabaseService.getCurrentUserTableId();

    debugPrint('userId: $userId');
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
      return;
    }

    try {
      // Use voice_id from the selected story first; only fall back to profile if story has none.
      String voiceId = (storyVoiceId ?? '').trim();
      if (voiceId.isEmpty) {
        final profile = await BackendClient.getUserProfile(userId);
        debugPrint('profile: $profile');
        voiceId = profile['voice_id']?.toString() ?? profile['voice_Id']?.toString() ?? '';
      }
      if (voiceId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Voice not available')));
        return;
      }

      String? playUrl;
      try {
        final res = await BackendClient.getStoryPlayUrl(storyId);
        playUrl = res['playUrl']?.toString();
      } catch (_) {
        final res = await BackendClient.voiceGenerateAudio(
          voiceId: voiceId,
          storyId: storyId,
        );
        playUrl = res['url']?.toString();
      }
      if (playUrl == null || playUrl.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not load audio')));
        return;
      }

      if (mounted) {
        // Same as home: avoid stacking two [NavBarPage]s (duplicate GlobalKeys on Home/Done).
        context.pushReplacementNamed(PlayerWidget.routeName, extra: {
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
              : Stack(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() {
                        _storyIdInDeleteMode = null;
                      }),
                      child: AnimatedOpacity(
                        opacity: _storyToDeleteForModal != null ? 0.5 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.only(bottom: 80),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 20),
                                if (_categories.isNotEmpty) _buildFilterPills(),
                                if (_categories.isNotEmpty) const SizedBox(height: 20),
                                ..._filteredCategories.map((c) => Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: _buildStoryCard(c),
                                    )),
                                if (_categories.isEmpty) ...[
                                  const SizedBox(height: 12),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 24),
                                      child: Text(
                                        'No stories yet.\nTap below to create your first manifestation.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          color: _DesiresColors.inkSoft,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                _buildAddButton(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_storyToDeleteForModal != null) _buildDeleteModal(),
                  ],
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
    // Library view: "Your Stories" / "X manifestations created" (HTML design)
    final countLabel = '$totalStories manifestations created';

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
              fontSize: 28,
              fontWeight: FontWeight.w400,
              color: _DesiresColors.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
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
          return Pressable(
            onTap: () => setState(() => _selectedFilter = i),
            borderRadius: BorderRadius.circular(20),
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
        border: Border.all(color: _DesiresColors.stone, width: 1.5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _DesiresColors.ink.withValues(alpha: 0.06),
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
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildStoryRowWithSwipe(
                story: s,
                cat: cat,
                categoryLabel: '${cat.eyebrow} · Already Done',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Wraps story row with horizontal drag: swipe left = delete mode, tap red card = modal, tap normal = play.
  Widget _buildStoryRowWithSwipe({
    required _StoryItem story,
    required _DesireCategory cat,
    required String categoryLabel,
  }) {
    final isDeleteMode = story.id != null && _storyIdInDeleteMode == story.id;
    return GestureDetector(
      onHorizontalDragEnd: (DragEndDetails d) {
        if (story.id == null) return;
        if (d.primaryVelocity != null && d.primaryVelocity! < -200) {
          setState(() => _storyIdInDeleteMode = story.id);
        } else if (d.primaryVelocity != null && d.primaryVelocity! > 100) {
          setState(() => _storyIdInDeleteMode = null);
        }
      },
      child: GestureDetector(
        onTap: () {
          if (isDeleteMode) {
            setState(() => _storyToDeleteForModal = story);
          } else if (story.id != null) {
            _navigateToPlayerWithVoice(
              story.id!,
              story.name,
              categoryLabel,
              story.meta,
              story.storyContent,
              story.voiceId,
            );
          }
        },
        child: _buildStoryItem(
          story,
          cat.iconBg,
          cat.accentColor,
          categoryLabel,
          isDeleteMode: isDeleteMode,
        ),
      ),
    );
  }

  Widget _buildStoryItem(
    _StoryItem story,
    Color iconBg,
    Color accentColor,
    String categoryLabel, {
    bool isDeleteMode = false,
  }) {
    // Delete mode: red card, trash icon, "Tap to delete", no play button (HTML screen 2)
    if (isDeleteMode) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: _DesiresColors.red,
          border: Border.all(color: _DesiresColors.redDark, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _DesiresColors.redDark,
                border: Border.all(color: _DesiresColors.redDark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(Icons.delete_outline, size: 24, color: Colors.white),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Tap to delete',
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
    // Normal library card: icon (gold gradient), title, meta, gold play button (HTML screen 1)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _DesiresColors.surface,
        border: Border.all(color: _DesiresColors.stone, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_DesiresColors.goldPale, _DesiresColors.warmWhite],
              ),
              border: Border.all(color: _DesiresColors.goldLight, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '✓',
                style: GoogleFonts.outfit(
                  fontSize: 20,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _DesiresColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _DesiresColors.gold,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _DesiresColors.ink.withValues(alpha: 0.06),
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: const Icon(Icons.play_arrow, size: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteModal() {
    final story = _storyToDeleteForModal!;
    return Material(
      color: _DesiresColors.ink.withValues(alpha: 0.6),
      child: GestureDetector(
        onTap: () {
          if (!_isDeleting) {
            setState(() {
              _storyToDeleteForModal = null;
              _storyIdInDeleteMode = null;
            });
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Center(
          child: GestureDetector(
            onTap: () {}, // prevent tap from closing when tapping modal content
            child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _DesiresColors.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _DesiresColors.ink.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _DesiresColors.redPale,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline, size: 28, color: _DesiresColors.red),
              ),
              const SizedBox(height: 16),
              Text(
                'Delete Story?',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _DesiresColors.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Are you sure you want to delete "${story.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  color: _DesiresColors.inkSoft,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isDeleting
                          ? null
                          : () => setState(() {
                                _storyToDeleteForModal = null;
                                _storyIdInDeleteMode = null;
                              }),
                      style: TextButton.styleFrom(
                        backgroundColor: _DesiresColors.warmWhite,
                        foregroundColor: _DesiresColors.ink,
                        side: const BorderSide(color: _DesiresColors.stone, width: 1.5),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextButton(
                      onPressed: _isDeleting ? null : () => _performDelete(story),
                      style: TextButton.styleFrom(
                        backgroundColor: _DesiresColors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _isDeleting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Delete',
                              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
      ),
    );
  }

  Future<void> _performDelete(_StoryItem story) async {
    final storyId = story.id;
    if (storyId == null) {
      setState(() => _storyToDeleteForModal = null);
      return;
    }
    setState(() => _isDeleting = true);
    try {
      await BackendClient.deleteStory(storyId);
      if (!mounted) return;
      // Optimistically remove the story from the list so the UI updates immediately.
      final updatedCategories = <_DesireCategory>[];
      for (final cat in _categories) {
        final kept = cat.stories.where((s) => s.id != storyId).toList();
        if (kept.isNotEmpty) {
          updatedCategories.add(_DesireCategory(
            id: cat.id,
            name: cat.name,
            eyebrow: cat.eyebrow,
            accentColor: cat.accentColor,
            iconBg: cat.iconBg,
            stories: kept,
          ));
        }
      }
      setState(() {
        _storyToDeleteForModal = null;
        _storyIdInDeleteMode = null;
        _isDeleting = false;
        _categories = updatedCategories;
        if (updatedCategories.isNotEmpty) {
          _headerCategory = '${updatedCategories.first.eyebrow} · Already Complete';
          _headerTitle = updatedCategories.first.name;
          _headerCount = '${updatedCategories.first.stories.length} stories · All complete';
        } else {
          _headerCategory = 'Love · Already Complete';
          _headerTitle = 'A Deeply Loving Relationship';
          _headerCount = '0 stories · All complete';
        }
      });
      // Refresh from server so counts and order stay correct (e.g. empty categories).
      await _loadData();
      if (mounted) AppToast.info(context, 'Story deleted');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isDeleting = false);
      AppToast.error(context, 'Could not delete story. Please try again.');
    }
  }

  /// Navigate to onboarding desire page (3rd step); prefill first name and someone you love from user profile.
  Future<void> _handleAddNewManifestation() async {
    final hasConsent = await AIConsentService.ensureConsent(context);
    if (!hasConsent) {
      if (mounted) {
        AppToast.info(
          context,
          'You need to agree to AI data sharing to add a manifestation.',
        );
      }
      return;
    }

    if (!mounted) return;
    context.push(OnboardingDesireWidget.routePath);
  }

  Widget _buildAddButton() {
    return Pressable(
      onTap: _handleAddNewManifestation,
      borderRadius: BorderRadius.circular(10),
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
