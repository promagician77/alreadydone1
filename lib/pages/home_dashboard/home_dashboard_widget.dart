import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import '/pages/onboarding/onboarding_desire_widget.dart';
import '/pages/subscription/subscription_widget.dart';
import '/pages/home_dashboard/coachmark/home_new_manifestation_coachmark.dart';
import '/pages/home_dashboard/coachmark/new_manifestation_coachmark_nav.dart';
import '/pages/home_dashboard/home_dashboard_story_utils.dart';
import '/pages/home_dashboard/widgets/home_dashboard_body.dart';
import '/pages/home_dashboard/widgets/home_dashboard_hero.dart';
import '/services/ai_consent_service.dart';
import '/services/app_toast.dart';
import '/services/backend_client.dart';
import '/services/profile_day_streak.dart';
import '/services/revenuecat_service.dart';
import '/services/sleep_mode_notifier.dart';
import '/services/supabase_service.dart';
import 'home_dashboard_colors.dart';
import 'home_dashboard_model.dart';
export 'home_dashboard_model.dart';

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
      if (mounted) {
        safeSetState(() {
          _model.isPlaying = false;
          _model.playingStoryId = null;
          _model.playbackPosition = Duration.zero;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((d) {
      final sid = _model.playingStoryId;
      if (sid != null && mounted) {
        final expectedSeconds =
            HomeDashboardStoryUtils.storyDurationSecondsById(
                  sid,
                  _model.stories,
                ) ??
                0;
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
    await Future.wait([
      _loadStories(),
      _loadUserProfile(),
      _loadDesires(),
      _loadSubscriptionStatus(),
    ]);
    if (!mounted) return;
    await _prefetchVoiceUrls();
    if (!mounted) return;
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
      if (mounted) {
        safeSetState(() {
          _model.isSubscribed = status.isSubscribed;
          _model.subscriptionStatusLoaded = true;
        });
      }
    } catch (e, st) {
      RevenueCatService.logFlow(
        'HomeDashboard',
        '_loadSubscriptionStatus FAILED: $e',
      );
      debugPrint('$st');
      if (mounted) {
        safeSetState(() {
          _model.isSubscribed = false;
          _model.subscriptionStatusLoaded = true;
        });
      }
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
      if (mounted) {
        safeSetState(() {
          _model.desires = [];
          _model.desiresLoading = false;
        });
      }
    }
  }

  Future<void> _prefetchVoiceUrls() async {
    final voiceId = _model.voiceId;
    if (voiceId == null || voiceId.isEmpty) return;
    final storiesToPrefetch = _model.stories.isEmpty
        ? <Map<String, dynamic>>[]
        : _model.stories.take(3).toList();
    for (final story in storiesToPrefetch) {
      final storyId = HomeDashboardStoryUtils.storyIdFromMap(story);
      if (storyId == null || _model.voicePlayUrlCache.containsKey(storyId)) {
        continue;
      }
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
      final voiceId =
          profile['voice_id']?.toString() ?? profile['voice_Id']?.toString() ?? '';
      final dayStreak = parseDayStreak(profile['day_streak']);
      final rcStatus =
          (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
              ?.toString()
              .trim()
              .toLowerCase();
      final rcPlan = profile['rc_subscription_plan']?.toString().trim();
      safeSetState(() {
        _model.userName = name.isNotEmpty ? name : null;
        _model.voiceId = voiceId.isNotEmpty ? voiceId : null;
        _model.dayStreak = dayStreak;
        _model.rcSubscriptionStatus =
            rcStatus?.isNotEmpty == true ? rcStatus : null;
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
      if (mounted) {
        safeSetState(() {
          _model.stories = [];
          _model.storiesLoading = false;
        });
      }
      return;
    }
    try {
      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?)
              ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList() ??
          [];
      list.sort((a, b) {
        final aAt =
            a['last_played'] ?? a['last_played_at'] ?? a['created_at'] ?? a['id'] ?? 0;
        final bAt =
            b['last_played'] ?? b['last_played_at'] ?? b['created_at'] ?? b['id'] ?? 0;
        if (aAt == bAt) return 0;
        if (aAt is int && bAt is int) return bAt.compareTo(aAt);
        return bAt.toString().compareTo(aAt.toString());
      });
      if (mounted) {
        safeSetState(() {
          _model.stories = list;
          _model.storiesLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        safeSetState(() {
          _model.stories = [];
          _model.storiesLoading = false;
        });
      }
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
    final storyId = HomeDashboardStoryUtils.storyIdFromMap(story);
    if (storyId == null) return null;

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
    final storyId = HomeDashboardStoryUtils.storyIdFromMap(story);
    if (storyId == null) return;
    if (_model.playingStoryId == storyId && _model.isPlaying) {
      await _audioPlayer.pause();
      if (mounted) safeSetState(() => _model.isPlaying = false);
      return;
    }
    if (_model.playingStoryId == storyId) {
      await _audioPlayer.resume();
      if (mounted) safeSetState(() => _model.isPlaying = true);
      return;
    }
    final playUrl = await _getPlayUrlForStory(story);
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
    final expectedSeconds =
        HomeDashboardStoryUtils.storyDurationSeconds(story) ?? 0;
    safeSetState(() {
      _model.playingStoryId = storyId;
      _model.isPlaying = false;
      _model.playbackPosition = Duration.zero;
      _model.playbackDuration = Duration(seconds: expectedSeconds);
    });
    final urlToPlay = HomeDashboardStoryUtils.cacheBustUrlIfSafe(playUrl);
    await _audioPlayer.play(
      UrlSource(urlToPlay),
      mode: PlayerMode.mediaPlayer,
    );
    if (mounted) safeSetState(() => _model.isPlaying = true);
  }

  Future<void> _navigateToPlayerWithVoice(Map<String, dynamic> story) async {
    final storyId = HomeDashboardStoryUtils.storyIdFromMap(story);
    if (storyId == null) return;

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in')),
        );
      }
      return;
    }

    try {
      String voiceId =
          (story['voice_id'] ?? story['voice_Id'])?.toString().trim() ?? '';
      if (voiceId.isEmpty) {
        final profile = await BackendClient.getUserProfile(userId);
        voiceId = profile['voice_id']?.toString() ??
            profile['voice_Id']?.toString() ??
            '';
      }
      if (voiceId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice not available')),
          );
        }
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not load audio')),
          );
        }
        return;
      }

      if (mounted) {
        final storyText =
            (story['story'] ?? story['content'])?.toString().trim();
        context.pushReplacementNamed(PlayerWidget.routeName, extra: {
          'storyId': storyId,
          'categoryLabel':
              (story['desire_name'] ?? story['category'] ?? 'Story').toString(),
          'title': (story['theme'] ??
                  story['title'] ??
                  story['desire_name'] ??
                  'Story')
              .toString(),
          'subtitle': '',
          'durationLabel': HomeDashboardStoryUtils.durationFromStory(
            story,
            _model.durationCache,
          ),
          'playUrl': playUrl,
          if (storyText != null && storyText.isNotEmpty)
            'storyPreview': storyText,
          'voiceId': voiceId,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _handleUnlockSleepMode() async {
    if (!mounted) return;
    try {
      RevenueCatService.logFlow(
        'HomeDashboard',
        '_handleUnlockSleepMode: isSubscribed check',
      );
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
      RevenueCatService.logFlow(
        'HomeDashboard',
        '_handleUnlockSleepMode FAILED: $e',
      );
      debugPrint('$st');
      if (mounted) {
        AppToast.info(context, 'Subscribe to unlock Sleep Mode');
        context.go(SubscriptionWidget.routePath);
      }
    }
  }

  bool _isStoryPlaying(Map<String, dynamic>? story) {
    if (story == null) return false;
    final id = HomeDashboardStoryUtils.storyIdFromMap(story);
    return id != null && _model.playingStoryId == id;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = HomeDashboardStoryUtils.filteredStories(
      stories: _model.stories,
      selectedDesireFilter: _model.selectedDesireFilter,
    );
    final lastPlayed = _model.stories.isEmpty ? null : _model.stories.first;
    final recentStories = filtered.isEmpty
        ? <Map<String, dynamic>>[]
        : filtered.sublist(0, filtered.length > 3 ? 3 : filtered.length);

    final lastPlayedIsPlayingStory = _isStoryPlaying(lastPlayed);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: HomeDashboardColors.surface,
        body: Stack(
          key: _homeBodyStackKey,
          clipBehavior: Clip.none,
          children: [
            SafeArea(
              top: true,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  HomeDashboardHero(
                    userName: _model.userName,
                    dayStreak: _model.dayStreak,
                  ),
                  Flexible(
                    child: HomeDashboardBody(
                      storiesLoading: _model.storiesLoading,
                      lastPlayedStory: lastPlayed,
                      lastPlayedCategoryLabel: lastPlayed != null
                          ? '${(lastPlayed['desire_name'] ?? lastPlayed['category'] ?? 'Story')} · Today\'s Story'
                          : "Today's Story",
                      lastPlayedTitle: lastPlayed != null
                          ? (lastPlayed['theme'] ??
                                  lastPlayed['title'] ??
                                  lastPlayed['desire_name'] ??
                                  'Your Story')
                              .toString()
                          : 'No story yet',
                      lastPlayedDurationLabel: lastPlayed != null
                          ? HomeDashboardStoryUtils.durationFromStory(
                              lastPlayed,
                              _model.durationCache,
                            )
                          : '--:--',
                      lastPlayedIsPlaying: lastPlayedIsPlayingStory &&
                          _model.isPlaying,
                      lastPlayedIsPlayingStory: lastPlayedIsPlayingStory,
                      onLastPlayedTap: lastPlayed != null
                          ? () => _toggleStoryPlayPause(lastPlayed)
                          : () {},
                      profileSubscriptionReady: _model.profileSubscriptionReady,
                      subscriptionStatusLoaded: _model.subscriptionStatusLoaded,
                      isSubscribed: _model.isSubscribed,
                      rcSubscriptionStatus: _model.rcSubscriptionStatus,
                      onUnlockSleepMode: _handleUnlockSleepMode,
                      desires: _model.desires,
                      stories: _model.stories,
                      selectedDesireFilter: _model.selectedDesireFilter,
                      onDesireFilterChanged: (filter) {
                        safeSetState(() => _model.selectedDesireFilter = filter);
                      },
                      addManifestationButtonKey: _addManifestationButtonKey,
                      onAddManifestation: _handleAddNewManifestation,
                      showNewManifestationCoachmark:
                          _showNewManifestationCoachmark,
                      manifestCoachPulseController:
                          _manifestCoachPulseController,
                      recentStories: recentStories,
                      onRecentStoryTap: _navigateToPlayerWithVoice,
                      durationCache: _model.durationCache,
                      playbackPosition: _model.playbackPosition,
                      playbackDuration: _model.playbackDuration,
                      idleWaveController: _idleWaveController,
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
}
