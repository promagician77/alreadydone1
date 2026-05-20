import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/pages/subscription/subscription_widget.dart';
import '/widgets/pressable.dart';
import '/services/app_toast.dart';
import '/services/ai_consent_service.dart';
import '/services/backend_client.dart';
import '/services/revenuecat_service.dart';
import '/services/sleep_mode_notifier.dart';
import '/services/profile_day_streak.dart';
import '/services/supabase_service.dart';
import '/pages/onboarding/onboarding_desire_widget.dart';
import '/pages/home_dashboard/coachmark/home_new_manifestation_coachmark.dart';
import '/pages/home_dashboard/coachmark/new_manifestation_coachmark_nav.dart';
import 'home_dashboard_model.dart';
export 'home_dashboard_model.dart';

class _AppColors {
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkMid = Color(0xFF44403C);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const gold = Color(0xFFB8861E);
  static const goldLight = Color(0xFFD4A574);
  static const goldDark = Color(0xFF8B6914);
  static const goldPale = Color(0xFFFBF4E6);
  static const blush = Color(0xFFD98B80);
  static const blushLight = Color(0xFFFDF0EE);
  static const sage = Color(0xFF7FA882);
  static const sageLight = Color(0xFFEEF4EE);
  static const teal = Color(0xFF4E8F9C);
  static const tealLight = Color(0xFFEAF4F6);
}

class HomeDashboardWidget extends StatefulWidget {
  const HomeDashboardWidget({super.key});

  static String routeName = 'HomeDashboard';
  static String routePath = '/homeDashboard';

  @override
  State<HomeDashboardWidget> createState() => _HomeDashboardWidgetState();
}

class _HomeDashboardWidgetState extends State<HomeDashboardWidget>
    with TickerProviderStateMixin {
  late HomeDashboardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _homeBodyStackKey = GlobalKey();
  final GlobalKey _addManifestationButtonKey = GlobalKey();
  final AudioPlayer _audioPlayer = AudioPlayer();
  late final AnimationController _idleWaveController;
  late final AnimationController _manifestCoachPulseController;
  bool _showNewManifestationCoachmark = false;
  int _playNonce = 0;

  String _cacheBustUrlIfSafe(String url) {
    final u = url.trim();
    if (u.isEmpty) return u;
    final lower = u.toLowerCase();
    if (lower.contains('x-amz-signature') ||
        lower.contains('x-amz-credential') ||
        lower.contains('x-amz-algorithm') ||
        lower.contains('x-amz-date') ||
        lower.contains('x-amz-security-token') ||
        lower.contains('signature=') ||
        lower.contains('token=')) {
      return u;
    }
    final uri = Uri.tryParse(u);
    if (uri == null) return u;
    final qp = <String, String>{...uri.queryParameters};
    qp['_cb'] = DateTime.now().millisecondsSinceEpoch.toString();
    return uri.replace(queryParameters: qp).toString();
  }

  int? _parseDurationSeconds(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    final text = raw.toString().trim();
    if (text.isEmpty) return null;
    final clock = RegExp(r'^(\d+):(\d{2})$').firstMatch(text);
    if (clock != null) {
      final minutes = int.tryParse(clock.group(1)!);
      final seconds = int.tryParse(clock.group(2)!);
      if (minutes != null && seconds != null) {
        return minutes * 60 + seconds;
      }
    }
    return num.tryParse(text)?.round();
  }

  int? _storyDurationSeconds(Map<String, dynamic>? story) {
    if (story == null) return null;
    return _parseDurationSeconds(
      story['play_length'] ?? story['playLength'] ?? story['duration'],
    );
  }

  int? _storyDurationSecondsById(int? storyId) {
    if (storyId == null) return null;
    final story = _model.stories.where((s) {
      final id = s['id'] is int ? s['id'] as int : int.tryParse(s['id']?.toString() ?? '');
      return id == storyId;
    }).cast<Map<String, dynamic>?>().firstWhere(
          (_) => true,
          orElse: () => null,
        );
    return _storyDurationSeconds(story);
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomeDashboardModel());
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _idleWaveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _manifestCoachPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    newManifestationCoachmarkVisible.addListener(_syncManifestCoachPulse);
    newManifestationCoachmarkOnHomeTabDuringCoachmark =
        _onHomeTabDuringCoachmark;
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) safeSetState(() {
        _model.isPlaying = false;
        _model.playingStoryId = null;
        _model.playbackPosition = Duration.zero;
      });
    });
    _audioPlayer.onDurationChanged.listen((d) {
      final sid = _model.playingStoryId;
      debugPrint('duration changed: $d');
      debugPrint('duration in seconds: ${d.inSeconds}'); 
      debugPrint('sid: $sid');
      debugPrint('mounted: $mounted');
      debugPrint('durationCache: ${_model.durationCache}');
      debugPrint('playbackDuration: ${_model.playbackDuration}');
      debugPrint('playbackPosition: ${_model.playbackPosition}');
      debugPrint('isPlaying: ${_model.isPlaying}');
      debugPrint('playingStoryId: ${_model.playingStoryId}');
      debugPrint('durationCache: ${_model.durationCache}');
      if (sid != null && mounted) {
        final expectedSeconds = _storyDurationSecondsById(sid) ?? 0;
        final resolvedSeconds = d.inSeconds > expectedSeconds
            ? d.inSeconds
            : expectedSeconds;
        safeSetState(() {
          _model.durationCache[sid] = resolvedSeconds;
          _model.playbackDuration = Duration(seconds: resolvedSeconds);
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) safeSetState(() => _model.playbackPosition = p);
    });
    _loadData().then((_) {
      if (mounted) unawaited(_maybeShowNewManifestationCoachmark());
    });
  }

  void _syncManifestCoachPulse() {
    if (newManifestationCoachmarkVisible.value) {
      _manifestCoachPulseController.repeat(reverse: true);
    } else {
      _manifestCoachPulseController
        ..stop()
        ..reset();
    }
  }

  Future<void> _maybeShowNewManifestationCoachmark() async {
    if (!mounted) return;
    await SupabaseService.waitForCurrentUserId();
    if (!mounted) return;
    final show = await NewManifestationCoachmarkPrefs.takePendingShowCoachmark();
    if (!show || !mounted) return;
    setState(() => _showNewManifestationCoachmark = true);
    newManifestationCoachmarkVisible.value = true;
  }

  Future<void> _dismissNewManifestationCoachmark() async {
    if (!_showNewManifestationCoachmark) return;
    setState(() => _showNewManifestationCoachmark = false);
    newManifestationCoachmarkVisible.value = false;
    await NewManifestationCoachmarkPrefs.markSeen();
  }

  Future<void> _onHomeTabDuringCoachmark() async {
    if (!_showNewManifestationCoachmark) return;
    await _dismissNewManifestationCoachmark();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStories(), _loadUserProfile(), _loadDesires(), _loadSubscriptionStatus()]);
    if (!mounted) return;
    await _prefetchVoiceUrls();
    if (!mounted) return;
    // Reload stories so we get play_length that was written when voice URLs were generated
    await _loadStories();
  }

  Future<void> _loadSubscriptionStatus() async {
    if (!mounted) return;
    try {
      RevenueCatService.logFlow('HomeDashboard', '_loadSubscriptionStatus');
      final status = await RevenueCatService.instance.getSubscriptionStatus();
      RevenueCatService.logFlow(
        'HomeDashboard',
        '_loadSubscriptionStatus: isSubscribed=${status.isSubscribed}',
      );
      if (mounted) safeSetState(() {
        _model.isSubscribed = status.isSubscribed;
        _model.subscriptionStatusLoaded = true;
      });
    } catch (e, st) {
      RevenueCatService.logFlow('HomeDashboard', '_loadSubscriptionStatus FAILED: $e');
      debugPrint('$st');
      if (mounted) safeSetState(() {
        _model.isSubscribed = false;
        _model.subscriptionStatusLoaded = true;
      });
    }
  }

  Future<void> _loadDesires() async {
    if (!mounted) return;
    try {
      final list = await BackendClient.getDesires();
      if (!mounted) return;
      safeSetState(() {
        _model.desires = list;
        _model.desiresLoading = false;
      });
    } catch (_) {
      if (mounted) safeSetState(() { _model.desires = []; _model.desiresLoading = false; });
    }
  }

  Future<void> _prefetchVoiceUrls() async {
    final voiceId = _model.voiceId;
    if (voiceId == null || voiceId.isEmpty) return;
    final storiesToPrefetch = _model.stories.isEmpty
        ? <Map<String, dynamic>>[]
        : _model.stories.take(3).toList();
    for (final story in storiesToPrefetch) {
      final storyId = story['id'] is int
          ? story['id'] as int
          : int.tryParse(story['id']?.toString() ?? '');
      if (storyId == null || _model.voicePlayUrlCache.containsKey(storyId)) continue;
      try {
        final res = await BackendClient.getStoryPlayUrl(storyId);
        final url = res['playUrl']?.toString();
        if (url != null && url.isNotEmpty && mounted) {
          safeSetState(() => _model.voicePlayUrlCache[storyId] = url);
        }
      } catch (_) {
        try {
          final res = await BackendClient.voiceGenerateAudio(
            voiceId: voiceId,
            storyId: storyId,
          );
          final url = res['url']?.toString();
          if (url != null && url.isNotEmpty && mounted) {
            safeSetState(() => _model.voicePlayUrlCache[storyId] = url);
          }
        } catch (_) {
          // ignore; will fetch on tap
        }
      }
    }
  }

  Future<void> _loadUserProfile() async {
    if (!mounted) return;
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      if (mounted) safeSetState(() => _model.profileSubscriptionReady = true);
      return;
    }
    try {
      final profile = await BackendClient.getUserProfile(userId);
      if (!mounted) return;
      final name = (profile['name'] as String? ?? '').toString().trim();
      final voiceId = profile['voice_id']?.toString() ?? profile['voice_Id']?.toString() ?? '';
      final dayStreak = parseDayStreak(profile['day_streak']);
      final rcStatus = (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
          ?.toString()
          .trim()
          .toLowerCase();
      final rcPlan = profile['rc_subscription_plan']?.toString().trim();
      safeSetState(() {
        _model.userName = name.isNotEmpty ? name : null;
        _model.voiceId = voiceId.isNotEmpty ? voiceId : null;
        _model.dayStreak = dayStreak;
        _model.rcSubscriptionStatus = rcStatus?.isNotEmpty == true ? rcStatus : null;
        _model.rcSubscriptionPlan = rcPlan?.isNotEmpty == true ? rcPlan : null;
        _model.profileSubscriptionReady = true;
      });
    } catch (_) {
      if (mounted) safeSetState(() => _model.profileSubscriptionReady = true);
    }
  }

  Future<void> _loadStories() async {
    if (!mounted) return;
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      if (mounted) safeSetState(() { _model.stories = []; _model.storiesLoading = false; });
      return;
    }
    try {
      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?)
          ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList() ?? [];
      list.sort((a, b) {
        final aAt = a['last_played'] ?? a['last_played_at'] ?? a['created_at'] ?? a['id'] ?? 0;
        final bAt = b['last_played'] ?? b['last_played_at'] ?? b['created_at'] ?? b['id'] ?? 0;
        if (aAt == bAt) return 0;
        if (aAt is int && bAt is int) return bAt.compareTo(aAt);
        return bAt.toString().compareTo(aAt.toString());
      });
      if (mounted) safeSetState(() { _model.stories = list; _model.storiesLoading = false; });
    } catch (_) {
      if (mounted) safeSetState(() { _model.stories = []; _model.storiesLoading = false; });
    }
  }

  Future<void> _handleAddNewManifestation() async {
    if (_showNewManifestationCoachmark) {
      await _dismissNewManifestationCoachmark();
    }
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

    context.push(OnboardingDesireWidget.routePath);
  }

  Widget _buildAddNewManifestationButton() {
    final button = Pressable(
      onTap: _handleAddNewManifestation,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _AppColors.gold,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: _AppColors.surface, size: 18),
            const SizedBox(width: 8),
            Text(
              'Add New Manifestation',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _AppColors.surface,
              ),
            ),
          ],
        ),
      ),
    );

    return KeyedSubtree(
      key: _addManifestationButtonKey,
      child: AnimatedBuilder(
        animation: _manifestCoachPulseController,
        builder: (context, child) {
          if (!_showNewManifestationCoachmark) return child!;
          final t = (math.sin(_manifestCoachPulseController.value * math.pi * 2) +
                  1) /
              2;
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.65 + 0.25 * t),
                  blurRadius: 30 + 18 * t,
                  spreadRadius: 1 + 2 * t,
                ),
                BoxShadow(
                  color: _AppColors.gold.withValues(alpha: 0.35 + 0.2 * t),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: button,
      ),
    );
  }

  @override
  void dispose() {
    newManifestationCoachmarkVisible.removeListener(_syncManifestCoachPulse);
    newManifestationCoachmarkOnHomeTabDuringCoachmark = null;
    newManifestationCoachmarkVisible.value = false;
    _manifestCoachPulseController.dispose();
    _idleWaveController.dispose();
    _audioPlayer.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<String?> _getPlayUrlForStory(Map<String, dynamic> story) async {
    final storyId = story['id'] is int
        ? story['id'] as int
        : int.tryParse(story['id']?.toString() ?? '');
    if (storyId == null) return null;

    // Prefer voice/speak URL (user's cloned voice); check cache first
    final cached = _model.voicePlayUrlCache[storyId];
    if (cached != null && cached.isNotEmpty) return cached;

    final voiceId = _model.voiceId;
    if (voiceId != null && voiceId.isNotEmpty) {
      try {
        final res = await BackendClient.getStoryPlayUrl(storyId);
        final url = res['playUrl']?.toString();
        if (url != null && url.isNotEmpty) {
          safeSetState(() => _model.voicePlayUrlCache[storyId] = url);
          return url;
        }
      } catch (_) {
        try {
          final res = await BackendClient.voiceGenerateAudio(
            voiceId: voiceId,
            storyId: storyId,
          );
          final url = res['url']?.toString();
          if (url != null && url.isNotEmpty) {
            safeSetState(() => _model.voicePlayUrlCache[storyId] = url);
            return url;
          }
        } catch (_) {
          // fall through to fallback
        }
      }
    }

    // Fallback: story playUrl from API or Supabase
    final url = story['playUrl']?.toString() ?? story['play_url']?.toString();
    if (url != null && url.isNotEmpty) return url;
    try {
      final res = await SupabaseService.client
          .from('Stories')
          .select('playUrl, play_url')
          .eq('id', storyId)
          .maybeSingle();
      if (res == null) return null;
      final data = res as Map<String, dynamic>;
      return data['playUrl']?.toString() ?? data['play_url']?.toString();
    } catch (_) {
      return null;
    }
  }

  Future<void> _toggleStoryPlayPause(Map<String, dynamic> story) async {
    final storyId = story['id'] is int ? story['id'] as int : int.tryParse(story['id']?.toString() ?? '');
    if (storyId == null) return;
    if (_model.playingStoryId == storyId && _model.isPlaying) {
      await _audioPlayer.pause();
      if (mounted) safeSetState(() { _model.isPlaying = false; });
      return;
    }
    if (_model.playingStoryId == storyId) {
      await _audioPlayer.resume();
      if (mounted) safeSetState(() { _model.isPlaying = true; });
      return;
    }
    final playUrl = await _getPlayUrlForStory(story);

    debugPrint('playUrl: $playUrl');
    if (playUrl == null || playUrl.isEmpty) {
      if (mounted) {
        AppToast.info(context, 'No audio available for this story');
      }
      return;
    }
    final nonce = ++_playNonce;
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
    } catch (_) {
      // best-effort
    }
    if (!mounted || nonce != _playNonce) return;
    final expectedSeconds = _storyDurationSeconds(story) ?? 0;
    safeSetState(() {
      _model.playingStoryId = storyId;
      _model.isPlaying = false;
      _model.playbackPosition = Duration.zero;
      _model.playbackDuration = Duration(seconds: expectedSeconds);
    });
    debugPrint('playing story: $storyId');
    debugPrint('playUrl - 1: $playUrl');
    debugPrint('mode: PlayerMode.mediaPlayer');
    final urlToPlay = _cacheBustUrlIfSafe(playUrl);
    await _audioPlayer.play(UrlSource(urlToPlay), mode: PlayerMode.mediaPlayer);
    if (mounted) safeSetState(() => _model.isPlaying = true);
  }

  Future<void> _navigateToPlayerWithVoice(Map<String, dynamic> story) async {
    final storyId = story['id'] is int ? story['id'] as int : int.tryParse(story['id']?.toString() ?? '');
    if (storyId == null) return;

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in')));
      return;
    }

    try {
      String voiceId = (story['voice_id'] ?? story['voice_Id'])?.toString().trim() ?? '';
      if (voiceId.isEmpty) {
        final profile = await BackendClient.getUserProfile(userId);
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
        final storyText = (story['story'] ?? story['content'])?.toString().trim();
        context.pushReplacementNamed(PlayerWidget.routeName, extra: {
          'storyId': storyId,
          'categoryLabel': (story['desire_name'] ?? story['category'] ?? 'Story').toString(),
          'title': (story['theme'] ?? story['title'] ?? story['desire_name'] ?? 'Story').toString(),
          'subtitle': '',
          'durationLabel': _durationFromStory(story),
          'playUrl': playUrl,
          if (storyText != null && storyText.isNotEmpty) 'storyPreview': storyText,
          'voiceId': voiceId,
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  String _durationFromStory(Map<String, dynamic> story) {
    final storyId = story['id'] is int ? story['id'] as int : int.tryParse(story['id']?.toString() ?? '');
    debugPrint('storyId: $storyId');
    final cached = storyId != null ? _model.durationCache[storyId] : null;
    final storySeconds = _storyDurationSeconds(story);
    final d = cached != null && storySeconds != null
        ? (cached > storySeconds ? cached : storySeconds)
        : (cached ?? storySeconds);
    if (d == null) return '--:--';
    debugPrint('d: $d');
    final secs = d is int ? d : (d is num ? d.round() : (_parseDurationSeconds(d) ?? 0));
    final m = secs ~/ 60;
    final s = secs % 60;
    debugPrint('${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}');
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  List<Map<String, dynamic>> _getFilteredStories() {
    final selected = _model.selectedDesireFilter;
    if (selected == null || selected.isEmpty) return _model.stories;
    return _model.stories
        .where((s) => (s['desire_name'] ?? s['category'] ?? '').toString() == selected)
        .toList();
  }

  int _countByDesire(String? desireName) {
    if (desireName == null || desireName.isEmpty) return _model.stories.length;
    return _model.stories
        .where((s) => (s['desire_name'] ?? s['category'] ?? '').toString() == desireName)
        .length;
  }

  Future<void> _handleUnlockSleepMode() async {
    if (!mounted) return;
    try {
      RevenueCatService.logFlow('HomeDashboard', '_handleUnlockSleepMode: isSubscribed check');
      final isSubscribed = await RevenueCatService.instance.isSubscribed();
      RevenueCatService.logFlow(
        'HomeDashboard',
        '_handleUnlockSleepMode: result=$isSubscribed',
      );
      if (!mounted) return;
      if (isSubscribed) {
        sleepModeNotifier.value = true;
        context.go('/player');
      } else {
        AppToast.info(context, 'Subscribe to unlock Sleep Mode');
        context.go(SubscriptionWidget.routePath);
      }
    } catch (e, st) {
      RevenueCatService.logFlow('HomeDashboard', '_handleUnlockSleepMode FAILED: $e');
      debugPrint('$st');
      if (mounted) {
        AppToast.info(context, 'Subscribe to unlock Sleep Mode');
        context.go(SubscriptionWidget.routePath);
      }
    }
  }

  Future<void> _openRatingDebugPanel() async {
    if (!kDebugMode || !mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        Future<void> triggerWithDay(int day) async {
          RatingPromptController.setDebugForcedDaysSinceStart(day);
          await RatingPromptPrefs.resetForTesting();
          await RatingPromptController.evaluateAfterPlaybackComplete();
          if (ctx.mounted) {
            AppToast.info(ctx, 'Forced day $day and triggered rating check.');
          }
        }

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Rating Prompt Debug',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _AppColors.ink,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => unawaited(triggerWithDay(7)),
                  child: const Text('Force Day 7 + Trigger'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => unawaited(triggerWithDay(30)),
                  child: const Text('Force Day 30 + Trigger'),
                ),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: () => unawaited(triggerWithDay(90)),
                  child: const Text('Force Day 90 + Trigger'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    RatingPromptController.setDebugForcedDaysSinceStart(null);
                    await RatingPromptPrefs.resetForTesting();
                    if (ctx.mounted) {
                      AppToast.info(ctx, 'Rating state reset.');
                    }
                  },
                  child: const Text('Reset Rating State'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await RatingPromptController.evaluateAfterPlaybackComplete();
                    if (ctx.mounted) {
                      AppToast.info(ctx, 'Triggered rating check.');
                    }
                  },
                  child: const Text('Trigger Rating Check Now'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredStories();
    final lastPlayed = _model.stories.isEmpty ? null : _model.stories.first;
    final recentStories = filtered.isEmpty
        ? <Map<String, dynamic>>[]
        : filtered.sublist(0, filtered.length > 3 ? 3 : filtered.length);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _AppColors.surface,
        floatingActionButton: kDebugMode
            ? FloatingActionButton.small(
                heroTag: 'rating_debug_fab',
                onPressed: () => unawaited(_openRatingDebugPanel()),
                backgroundColor: _AppColors.gold,
                child: const Icon(Icons.bug_report),
              )
            : null,
        body: Stack(
          key: _homeBodyStackKey,
          clipBehavior: Clip.none,
          children: [
            SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
              // Hero section (full width, outside padded area)
              _buildHero(),
              // Scrollable content with horizontal padding
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 24, 20, 80),
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      // Story card (last played from API) — play in-page, no navigation
                      _model.storiesLoading
                          ? _buildStoryCardLoading()
                          : _buildStoryCard(
                              context: context,
                              story: lastPlayed,
                              categoryLabel: lastPlayed != null
                                  ? (lastPlayed['desire_name'] ?? lastPlayed['category'] ?? 'Story').toString() + " · Today's Story"
                                  : "Today's Story",
                              title: lastPlayed != null
                                  ? (lastPlayed['theme'] ?? lastPlayed['title'] ?? lastPlayed['desire_name'] ?? 'Your Story').toString()
                                  : 'No story yet',
                              durationLabel: lastPlayed != null ? _durationFromStory(lastPlayed) : '--:--',
                              isPlaying: lastPlayed != null && _model.playingStoryId == (lastPlayed['id'] is int ? lastPlayed['id'] : int.tryParse(lastPlayed['id']?.toString() ?? '')) && _model.isPlaying,
                              onTap: lastPlayed != null ? () => _toggleStoryPlayPause(lastPlayed) : () {},
                              isPlayingStory: lastPlayed != null && _model.playingStoryId == (lastPlayed['id'] is int ? lastPlayed['id'] : int.tryParse(lastPlayed['id']?.toString() ?? '')),
                            ),
                      const SizedBox(height: 16),

                      // Sleep Mode premium card — show loading until both profile and subscription
                      // status are loaded to avoid flashing wrong state.
                      if (!_model.profileSubscriptionReady || !_model.subscriptionStatusLoaded)
                        _buildSleepCardLoadingPlaceholder()
                      else if (_model.subscriptionStatusLoaded &&
                          !_model.isSubscribed &&
                          _model.rcSubscriptionStatus != 'active' &&
                          _model.rcSubscriptionStatus != 'trial') ...[
                        _buildSleepCard(context),
                        const SizedBox(height: 20),
                      ],

                      // Your Manifestations
                              Text(
                        'Your Manifestations',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                                        fontWeight: FontWeight.w600,
                          color: _AppColors.inkMid,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildDesireChips(),
                      const SizedBox(height: 20),
                      _buildAddNewManifestationButton(),
                      const SizedBox(height: 20),

                      // Recent Stories (last two from API)
                      Text(
                        'Recent Stories',
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _AppColors.inkMid,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildRecentStories(context, recentStories),
                    ],
                  ),
                ),
              ),
            ],
              ),
            ),
            if (_showNewManifestationCoachmark)
              Positioned.fill(
                child: HomeNewManifestationCoachmarkOverlay(
                  stackKey: _homeBodyStackKey,
                  addButtonTargetKey: _addManifestationButtonKey,
                  onGotIt: () => unawaited(_dismissNewManifestationCoachmark()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryCardLoading() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: _AppColors.surface,
        border: Border.all(color: _AppColors.stone),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(child: CircularProgressIndicator(color: _AppColors.gold)),
    );
  }

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsetsDirectional.fromSTEB(20, 28, 20, 28),
      decoration: const BoxDecoration(color: _AppColors.ink),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
          Text(
            () {
              final hour = DateTime.now().hour;
              if (hour < 12) return 'GOOD MORNING';
              if (hour < 17) return 'GOOD AFTERNOON';
              return 'GOOD EVENING';
            }(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w500,
              color: _AppColors.stone,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            (_model.userName ?? '').trim().isNotEmpty ? (_model.userName ?? '').trim() : 'there',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 32,
              fontWeight: FontWeight.w300,
              color: _AppColors.warmWhite,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
                            child: Row(
              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                  '✓',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                                          fontWeight: FontWeight.w600,
                    color: _AppColors.goldLight,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_model.dayStreak}-day streak',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.goldLight,
                  ),
                ),
                              ],
                            ),
                          ),
        ],
      ),
    );
  }

  static const List<double> _staticWaveHeights = [8.0, 16.0, 24.0, 14.0, 28.0, 20.0, 12.0, 22.0, 18.0, 10.0];
  static const int _totalWaveBars = 56;

  /// Waveform with water-flow animation: bar heights vary over time. Progress = first [visibleCount] bars in gold.
  Widget _buildProgressWaveform(int visibleCount, int totalBars, {bool isAnimated = false}) {
    const heights = [8.0, 20.0, 32.0, 16.0, 36.0, 12.0, 28.0, 24.0, 14.0, 30.0];
    return AnimatedBuilder(
      animation: _idleWaveController,
      builder: (context, _) {
        final t = _idleWaveController.value * 2 * math.pi;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(totalBars, (i) {
            final isPlayed = i < visibleCount;
            final s1 = (math.sin(t + i * 0.4) + 1) / 2;
            final s2 = (math.sin(t * 1.3 + i * 0.6) + 1) / 2;
            final baseH = heights[i % heights.length];
            final h = baseH * 0.6 + baseH * 0.4 * s1 + 4.0 * s2;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0.5),
                child: Container(
                  width: double.infinity,
                  height: h.clamp(6.0, 34.0),
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _AppColors.goldLight,
                              _AppColors.gold,
                              _AppColors.goldDark,
                            ],
                            stops: [0.0, 0.55, 1.0],
                          )
                        : null,
                    color: isPlayed
                        ? null
                        : (isAnimated && visibleCount == 0
                            ? _AppColors.stone.withValues(alpha: 0.9)
                            : _AppColors.stone),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: _AppColors.gold.withValues(alpha: 0.22),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildStoryCard({
    required BuildContext context,
    Map<String, dynamic>? story,
    required String categoryLabel,
    required String title,
    required String durationLabel,
    required bool isPlaying,
    required VoidCallback onTap,
    bool isPlayingStory = false,
  }) {
    final pos = _model.playbackPosition.inMilliseconds;
    final dur = _model.playbackDuration.inMilliseconds;
    final visibleBars = (dur > 0 && isPlayingStory)
        ? ((pos / dur) * _totalWaveBars).round().clamp(0, _totalWaveBars)
        : 0;
    return Container(
      decoration: BoxDecoration(
        color: _AppColors.surface,
        border: Border.all(color: _AppColors.stone),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _AppColors.ink.withOpacity(0.06),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryLabel.toUpperCase(),
              style: GoogleFonts.outfit(
                fontSize: 10,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                color: _AppColors.blush,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.cormorantGaramond(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: _AppColors.ink,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 12),
            // Waveform: left-to-right by time flow (played=gold, unplayed=gray); animated when idle
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: _AppColors.warmWhite,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildProgressWaveform(
                      visibleBars,
                      _totalWaveBars,
                      isAnimated: !isPlayingStory,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Pressable(
              onTap: story != null ? onTap : null,
              borderRadius: BorderRadius.circular(10),
              splashColor: Colors.white.withValues(alpha: 0.3),
              highlightColor: Colors.white.withValues(alpha: 0.15),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _AppColors.gold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPlaying ? Icons.pause : Icons.play_arrow,
                      color: _AppColors.surface,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPlaying ? 'Pause' : 'Play Story · $durationLabel',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Shown until profile and subscription status are loaded to avoid flashing sleep card.
  Widget _buildSleepCardLoadingPlaceholder() {
    return SizedBox(
      height: 200,
      child: Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: _AppColors.gold,
          ),
        ),
      ),
    );
  }

  Widget _buildSleepCard(BuildContext context) {
    return Container(
                              decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4E5F9C), Color(0xFF2A3B5F)],
        ),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 18,
            right: 18,
            child: Text(
              '✓',
              style: GoogleFonts.outfit(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                  'PREMIUM FEATURE',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sleep Mode',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 20,
                    fontWeight: FontWeight.w400,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Slower pacing, theta waves, fade to silence',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 14),
                Pressable(
                  onTap: _handleUnlockSleepMode,
                  borderRadius: BorderRadius.circular(10),
                  splashColor: Colors.white.withValues(alpha: 0.2),
                  highlightColor: Colors.white.withValues(alpha: 0.1),
                  child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          'Unlock Sleep Mode',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesireChips() {
    final selected = _model.selectedDesireFilter;
    final chips = <(String, String?)>[
      ('All Stories', null),
      ..._model.desires.map((d) {
        final name = (d['desireCategory'] ?? d['name'] ?? '').toString();
        return (name, name.isEmpty ? null : name);
      }),
    ].where((c) => c.$1.isNotEmpty).toList();

    if (chips.isEmpty) {
      chips.add(('All Stories', null));
    }

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, desireName) = chips[i];
          final count = _countByDesire(desireName);
          final isSelected = selected == desireName;
          return Pressable(
            onTap: () {
              safeSetState(() => _model.selectedDesireFilter = desireName);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _AppColors.goldPale : _AppColors.surface,
                border: Border.all(
                  color: isSelected ? _AppColors.gold : _AppColors.stone,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  '$label ($count)',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? _AppColors.gold : _AppColors.inkSoft,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  static final List<Color> _recentStoryColors = [
    _AppColors.blushLight,
    _AppColors.goldPale,
    _AppColors.tealLight,
  ];

  Widget _buildRecentStories(BuildContext context, List<Map<String, dynamic>> recentStories) {
    if (recentStories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No recent stories yet.',
          style: GoogleFonts.outfit(fontSize: 13, color: _AppColors.inkSoft),
        ),
      );
    }
    return Column(
      children: List.generate(recentStories.length, (i) {
        final story = recentStories[i];
        final name = (story['theme'] ?? story['title'] ?? story['desire_name'] ?? 'Story').toString();
        final duration = _durationFromStory(story);
        final meta = '· $duration';
        final iconBg = _recentStoryColors[i % _recentStoryColors.length];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Pressable(
            onTap: () => _navigateToPlayerWithVoice(story),
            borderRadius: BorderRadius.circular(12),
            child: _buildStoryItem(name: name, meta: meta, iconBg: iconBg),
          ),
        );
      }),
    );
  }

  Widget _buildStoryItem({
    required String name,
    required String meta,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
        color: _AppColors.surface,
        border: Border.all(color: _AppColors.stone),
        borderRadius: BorderRadius.circular(12),
      ),
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
                  color: _AppColors.ink,
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
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  meta,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: _AppColors.inkSoft,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
          Container(
            width: 32,
            height: 32,
                                  decoration: BoxDecoration(
              color: _AppColors.warmWhite,
              border: Border.all(color: _AppColors.stone),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow, size: 16, color: _AppColors.ink),
          ),
        ],
      ),
    );
  }
}
