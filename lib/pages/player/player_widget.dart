import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/last_played_service.dart';
import 'package:flutter/material.dart';
import '/services/sleep_mode_notifier.dart';
import 'package:google_fonts/google_fonts.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/widgets/pressable.dart';
import 'player_modals/player_modals.dart';
import 'player_model.dart';
export 'player_model.dart';

/// Design tokens from HTML (Story Player)
class _PlayerColors {
  static const warmWhite = Color(0xFFF9F7F4);
  static const surface = Color(0xFFFEFDFB);
  static const ink = Color(0xFF1C1917);
  static const inkMid = Color(0xFF44403C);
  static const inkSoft = Color(0xFF78716C);
  static const stone = Color(0xFFE8E2DA);
  static const stoneMid = Color(0xFFD6D0C8);
  static const gold = Color(0xFFB8861E);
  static const goldDark = Color(0xFF8B6914);
  static const goldLight = Color(0xFFD4A574);
  static const goldPale = Color(0xFFFBF4E6);
  static const blush = Color(0xFFD98B80);
  static const lavender = Color(0xFF9B8FAA);
  static const sleepPurple = Color(0xFF4A3B5F);
  static const sleepBlue = Color(0xFF2A3B5F);
  static const sleepDark = Color(0xFF1A1F3A);
}

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({
    super.key,
    this.storyId,
    this.categoryLabel,
    this.title,
    this.subtitle,
    this.durationLabel,
    this.playUrl,
    this.storyPreview,
  });

  final int? storyId;
  final String? categoryLabel;
  final String? title;
  final String? subtitle;
  final String? durationLabel;

  /// Voice URL from api/voice/speak. When provided, used directly for playback.
  final String? playUrl;

  /// Story text for preview. When provided, used for STORY PREVIEW section.
  final String? storyPreview;

  static String routeName = 'Player';
  static String routePath = '/player';

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with SingleTickerProviderStateMixin {
  late PlayerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Background theta track player (mp3 at ~20% volume).
  final AudioPlayer _thetaTrackPlayer = AudioPlayer();

  /// Available background theta tracks (files under assets/audios/theta/).
  /// Path is relative to assets folder; audioplayers adds asset prefix automatically.
  static const List<(String name, String assetPath)> _thetaTracks = [
    ('Healing Therapy', 'audios/theta/Healing Therapy.mp3'),
    ('The City in Dreams', 'audios/theta/The City in Dreams.mp3'),
    ('Solar Drift', 'audios/theta/Solar Drift.mp3'),
    ('Boyar', 'audios/theta/Boyar.mp3'),
    ('Mantle', 'audios/theta/Mantle.mp3'),
    ('Reflection', 'audios/theta/Reflection.mp3'),
    ('Healing Spheres', 'audios/theta/Healing Spheres.mp3'),
    ('Neptune', 'audios/theta/Neptune.mp3'),
  ];

  StreamSubscription? _playerCompleteSub;
  StreamSubscription? _durationChangedSub;
  StreamSubscription? _positionChangedSub;
  bool _disposed = false;

  String? _categoryLabel;
  String? _title;
  String? _subtitle;
  String? _durationLabel;
  String? _previewContent;
  String? _fullStoryContent;
  String? _playUrl;
  bool _loading = true;
  String? _loadError;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _sleepModeActive = false;
  int? _sleepTimerMinutes = 30;
  DateTime? _sleepModeStartedAt;

  /// Single unified timer for sleep mode (countdown + volume).
  Timer? _sleepMasterTimer;

  /// Playback speed options (used for both normal and sleep mode).
  static const List<double> _speedOptions = [0.5, 0.75, 1.0];

  /// Normal (non-sleep) playback speed. Default 1.0x.
  double _normalPlaybackRate = 1.0;

  /// Sleep mode playback speed (only used when sleep mode is active).
  /// Default is 0.75x.
  double _sleepPlaybackRate = 0.75;

  /// Loop voice playback (both common and sleep mode). When true, voice repeats.
  bool _loopEnabled = false;

  /// Notifier so Playback Settings modal updates the Loop row immediately when changed.
  final ValueNotifier<bool> _loopNotifier = ValueNotifier(false);

  /// Sleep mode: target narration volume (70% per client spec).
  static const double _sleepVolumeTarget = 0.7;

  /// Sleep mode: background theta track volume (20% per client spec).
  static const double _thetaVolumeTarget = 0.2;

  /// Initial volume fade-in duration (seconds) — voice fades from 1.0 → 0.7.
  static const int _sleepVolumeFadeInSeconds = 120;

  /// Fade-to-silence duration at end of sleep timer (seconds).
  static const int _sleepFadeOutSeconds = 60;

  /// Screen brightness when sleep mode active (~40%).
  static const double _sleepBrightness = 0.4;

  late AnimationController _waveformController;
  int _selectedThetaIndex = 0;

  // ---------------------------------------------------------------------------
  // Audio context helper — builds a "mix with others" context so both players
  // can produce sound simultaneously without stealing each other's session.
  // ---------------------------------------------------------------------------
  AudioContext _buildMixAudioContext() {
    return AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
      respectSilence: false,
    ).build();
  }

  /// Re-apply the mix audio context to BOTH players. Call this before any
  /// play() to ensure the native audio session isn't reset to exclusive mode.
  Future<void> _applyMixContext() async {
    final ctx = _buildMixAudioContext();
    await _audioPlayer.setAudioContext(ctx);
    await _thetaTrackPlayer.setAudioContext(ctx);
  }

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _model = createModel(context, () => PlayerModel());
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _thetaTrackPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _thetaTrackPlayer.setReleaseMode(ReleaseMode.loop);

    // Initial audio context (will be re-applied before each play()).
    _applyMixContext();

    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!_disposed && mounted) {
        _stopThetaBackground();
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        if (_sleepModeActive) {
          _endSleepSession();
        }
      }
    });
    _durationChangedSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!_disposed && mounted) setState(() => _duration = d);
    });
    _positionChangedSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!_disposed && mounted) setState(() => _position = p);
    });
    _loadStoryData();
  }

  // ===========================================================================
  // DATA LOADING
  // ===========================================================================

  Future<void> _loadStoryData() async {
    final previewFromWidget = (widget.storyPreview ?? '').trim();
    if (previewFromWidget.isNotEmpty) {
      setState(() {
        _previewContent = previewFromWidget.length > 200
            ? '${previewFromWidget.substring(0, 200)}...'
            : previewFromWidget;
      });
    }

    if (widget.storyId == null) {
      if (widget.playUrl != null && widget.playUrl!.isNotEmpty) {
        setState(() {
          _categoryLabel = widget.categoryLabel;
          _title = widget.title;
          _subtitle = widget.subtitle;
          _durationLabel = widget.durationLabel;
          if (_previewContent == null && previewFromWidget.isEmpty) {
            _previewContent = null;
          }
          _playUrl = widget.playUrl;
          _loading = false;
        });
        _saveLastPlayed();
        return;
      }
      final lastPlayed = await LastPlayedService.loadLastPlayed();
      if (lastPlayed != null &&
          lastPlayed['playUrl']?.toString().trim().isNotEmpty == true) {
        final playUrl = lastPlayed['playUrl']!.toString().trim();
        final title = lastPlayed['title']?.toString().trim();
        final categoryLabel = lastPlayed['categoryLabel']?.toString().trim();
        final durationLabel = lastPlayed['durationLabel']?.toString().trim();
        final storyPreview = lastPlayed['storyPreview']?.toString().trim();
        if (!mounted) return;
        setState(() {
          _playUrl = playUrl;
          _title = title;
          _categoryLabel = categoryLabel ?? 'Love';
          _subtitle = widget.subtitle;
          _durationLabel = durationLabel;
          if (storyPreview != null && storyPreview.isNotEmpty) {
            _previewContent = storyPreview.length > 200
                ? '${storyPreview.substring(0, 200)}...'
                : storyPreview;
          }
          _loading = false;
          _loadError = null;
        });
        _maybeAutoPlayAndActivateSleepMode();
        return;
      }

      final fallback = await _loadLastCreatedStory();
      if (fallback != null && !mounted) return;
      if (fallback != null) {
        final playUrl = fallback['playUrl']!.toString().trim();
        setState(() {
          _playUrl = playUrl;
          _title = fallback['title'];
          _categoryLabel = fallback['categoryLabel'] ?? 'Love';
          _durationLabel = fallback['durationLabel'];
          _previewContent = fallback['storyPreview'];
          _loading = false;
          _loadError = null;
        });
        LastPlayedService.saveLastPlayed(
          storyId: fallback['storyId'] as int?,
          playUrl: playUrl,
          title: _title,
          categoryLabel: _categoryLabel,
          durationLabel: _durationLabel,
          storyPreview: _previewContent,
          storyContent: fallback['storyContent']?.toString().trim(),
        );
        _maybeAutoPlayAndActivateSleepMode();
        return;
      }

      setState(() {
        _categoryLabel = widget.categoryLabel;
        _title = widget.title;
        _subtitle = widget.subtitle;
        _durationLabel = widget.durationLabel;
        if (_previewContent == null && previewFromWidget.isEmpty) {
          _previewContent = null;
        }
        _playUrl = widget.playUrl;
        _loading = false;
      });
      if (sleepModeNotifier.value) sleepModeNotifier.value = false;
      return;
    }

    if (widget.playUrl != null && widget.playUrl!.isNotEmpty) {
      setState(() {
        _playUrl = widget.playUrl;
        _categoryLabel = widget.categoryLabel;
        _title = widget.title;
        _subtitle = widget.subtitle;
        _durationLabel = widget.durationLabel;
      });
    }

    try {
      final res = await SupabaseService.client
          .from('Stories')
          .select(
              'theme, story, title, content, desire_name, category, playUrl, storage')
          .eq('id', widget.storyId!)
          .maybeSingle();

      if (!mounted) return;
      if (res == null) {
        setState(() {
          _loadError = widget.playUrl != null ? null : 'Story not found';
          _loading = false;
          _categoryLabel = widget.categoryLabel;
          _title = widget.title;
          _subtitle = widget.subtitle;
          _durationLabel = widget.durationLabel;
          if (widget.playUrl != null) _playUrl = widget.playUrl;
        });
        return;
      }

      final data = res as Map<String, dynamic>;
      final content =
          (data['story'] ?? data['content'])?.toString().trim();
      final playUrl = widget.playUrl ??
          data['playUrl']?.toString() ??
          data['play_url']?.toString();

      final preview = (content != null && content.isNotEmpty)
          ? (content.length > 200
              ? '${content.substring(0, 200)}...'
              : content)
          : (_previewContent ?? widget.storyPreview?.trim());

      setState(() {
        _title =
            (data['theme'] ?? data['title'])?.toString() ?? widget.title;
        _categoryLabel =
            (data['desire_name'] ?? data['category'])?.toString() ??
                widget.categoryLabel ??
                'Love';
        _subtitle = widget.subtitle;
        _durationLabel = widget.durationLabel;
        _previewContent =
            (preview != null && preview.toString().trim().isNotEmpty)
                ? (preview.toString().length > 200
                    ? '${preview.toString().substring(0, 200)}...'
                    : preview.toString())
                : null;
        _fullStoryContent = content;
        _playUrl = playUrl;
        _loading = false;
        _loadError = null;
      });
      _saveLastPlayed();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
        _categoryLabel = widget.categoryLabel;
        _title = widget.title;
        _subtitle = widget.subtitle;
        _durationLabel = widget.durationLabel;
        if (widget.playUrl != null) _playUrl = widget.playUrl;
      });
    }
  }

  /// Load the last created story when no last played exists.
  Future<Map<String, dynamic>?> _loadLastCreatedStory() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return null;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      final voiceId = profile['voice_id']?.toString().trim() ??
          profile['voice_Id']?.toString().trim();
      if (voiceId == null || voiceId.isEmpty) return null;

      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?)
              ?.map((e) =>
                  e is Map<String, dynamic> ? e : <String, dynamic>{})
              .toList() ??
          [];
      if (list.isEmpty) return null;

      list.sort((a, b) {
        final aAt = a['created_at'] ?? a['id'] ?? 0;
        final bAt = b['created_at'] ?? b['id'] ?? 0;
        if (aAt == bAt) return 0;
        return bAt.toString().compareTo(aAt.toString());
      });
      final story = list.first;
      final storyId = story['id'] is int
          ? story['id'] as int
          : int.tryParse(story['id']?.toString() ?? '');
      if (storyId == null) return null;

      String? playUrl;
      try {
        final res = await BackendClient.getStoryPlayUrl(storyId);
        playUrl = res['playUrl']?.toString().trim();
      } catch (_) {
        final res = await BackendClient.voiceGenerateAudio(
          voiceId: voiceId,
          storyId: storyId,
        );
        playUrl = res['url']?.toString().trim();
      }
      if (playUrl == null || playUrl.isEmpty) return null;

      final content =
          (story['story'] ?? story['content'])?.toString().trim();
      final preview = content != null && content.isNotEmpty
          ? (content.length > 200
              ? '${content.substring(0, 200)}...'
              : content)
          : null;
      final duration = story['play_length'] ?? story['duration'];
      int secs = 0;
      if (duration != null) {
        if (duration is int) {
          secs = duration;
        } else if (duration is num) {
          secs = duration.round();
        } else {
          secs = int.tryParse(duration.toString()) ?? 0;
        }
      }
      final m = secs ~/ 60;
      final s = secs % 60;
      final durationLabel =
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      return {
        'playUrl': playUrl,
        'storyId': storyId,
        'title': (story['theme'] ??
                story['title'] ??
                story['desire_name'] ??
                'Story')
            .toString(),
        'categoryLabel':
            (story['desire_name'] ?? story['category'] ?? 'Love').toString(),
        'durationLabel': durationLabel,
        'storyPreview': preview,
        'storyContent': content,
      };
    } catch (_) {
      return null;
    }
  }

  void _saveLastPlayed() {
    final url = _playUrl?.trim();
    if (url == null || url.isEmpty) return;
    LastPlayedService.saveLastPlayed(
      storyId: widget.storyId,
      playUrl: url,
      title: _title,
      categoryLabel: _categoryLabel,
      durationLabel: _durationLabel,
      storyPreview: _previewContent,
      storyContent: _fullStoryContent,
    );
  }

  // ===========================================================================
  // AUTO-PLAY / SLEEP MODE ENTRY FROM NOTIFIER
  // ===========================================================================

  /// When opened from navbar or Unlock Sleep Mode (no story params), auto-play.
  /// If sleepModeNotifier is true (came from Unlock Sleep Mode), activate sleep.
  void _maybeAutoPlayAndActivateSleepMode() {
    final url = _playUrl?.trim();
    if (url == null || url.isEmpty || !mounted) return;
    if (sleepModeNotifier.value) {
      _startSleepSession(url);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _disposed) return;
        await _applyMixContext();
        await _audioPlayer.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
        await _audioPlayer.setReleaseMode(
            _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
        await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
        if (mounted) setState(() => _isPlaying = true);
      });
    }
  }

  // ===========================================================================
  // SLEEP SESSION — SINGLE ENTRY POINT (fixes duplication)
  // ===========================================================================

  /// Start a sleep session. This is the ONE place sleep mode is activated.
  /// All entry points (settings modal, notifier, etc.) call this method.
  Future<void> _startSleepSession(String url) async {
    if (_disposed || !mounted) return;

    // 1. Track whether voice was already playing so we can resume instead of
    //    restarting from scratch (avoids silence gap from URL re-fetch).
    final wasAlreadyPlaying = _isPlaying;

    // 2. Update state
    setState(() {
      _sleepModeActive = true;
      sleepModeNotifier.value = true;
      _sleepModeStartedAt = DateTime.now();
    });

    // 3. Configure voice player for sleep (loop follows user setting)
    await _audioPlayer.setReleaseMode(
        _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
    await _audioPlayer.setPlaybackRate(_sleepPlaybackRate);

    // 4. Dim screen
    _setSleepBrightness(true);

    // 5. Re-apply mix context BEFORE any play() calls — this is critical so
    //    neither player steals the audio session from the other.
    await _applyMixContext();

    // 6. Start theta FIRST (local asset, loads fast) and let it settle.
    await _startThetaBackground();
    await Future.delayed(const Duration(milliseconds: 300));

    if (_disposed || !mounted) return;

    // 7. Re-apply mix context AGAIN after theta started — some platforms
    //    reset the session when a new player begins.
    await _applyMixContext();

    // 8. Start or resume voice
    if (wasAlreadyPlaying) {
      // Voice is already playing — just adjust settings, no restart needed.
      await _audioPlayer.setPlaybackRate(_sleepPlaybackRate);
      await _audioPlayer.setVolume(1.0); // will be managed by master timer
    } else {
      // Voice was not playing — start from beginning.
      await _audioPlayer.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
    }

    if (_disposed || !mounted) return;

    // 9. One more context re-apply after voice starts (belt and suspenders).
    await Future.delayed(const Duration(milliseconds: 200));
    await _applyMixContext();

    // 10. Set initial volumes explicitly after players are running.
    await _audioPlayer.setVolume(1.0);
    await _thetaTrackPlayer.setVolume(_thetaVolumeTarget);

    // 11. Start the single unified volume + countdown timer.
    _startSleepMasterTimer();

    if (mounted) setState(() => _isPlaying = true);
  }

  // ===========================================================================
  // SINGLE UNIFIED SLEEP TIMER (replaces two competing timers)
  // ===========================================================================

  /// One timer to rule them all:
  ///  - Phase 1 (0..120s): fade voice volume from 1.0 → 0.7
  ///  - Phase 2 (120s..end-60s): hold voice at 0.7, theta at 0.2
  ///  - Phase 3 (last 60s): fade both to 0.0
  ///  - End: stop everything
  void _startSleepMasterTimer() {
    _sleepMasterTimer?.cancel();
    _sleepMasterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      // Guard against null (could happen if _endSleepSession races with tick)
      final started = _sleepModeStartedAt;
      if (started == null) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(started).inSeconds;
      final totalSeconds = (_sleepTimerMinutes ?? 30) * 60;
      final remaining = totalSeconds - elapsed;

      // Time's up — end the session.
      if (remaining <= 0) {
        timer.cancel();
        _sleepMasterTimer = null;
        _endSleepSession();
        return;
      }

      // --- Compute voice volume ---
      double voiceVol;
      if (elapsed < _sleepVolumeFadeInSeconds) {
        // Phase 1: fade from 1.0 → _sleepVolumeTarget over 120s
        final progress = elapsed / _sleepVolumeFadeInSeconds;
        voiceVol = 1.0 - ((1.0 - _sleepVolumeTarget) * progress);
      } else if (remaining <= _sleepFadeOutSeconds) {
        // Phase 3: fade from _sleepVolumeTarget → 0.0 over last 60s
        voiceVol = _sleepVolumeTarget * (remaining / _sleepFadeOutSeconds);
      } else {
        // Phase 2: hold at target
        voiceVol = _sleepVolumeTarget;
      }

      // --- Compute theta volume ---
      double thetaVol;
      if (remaining <= _sleepFadeOutSeconds) {
        // Phase 3: fade theta to 0
        thetaVol = _thetaVolumeTarget * (remaining / _sleepFadeOutSeconds);
      } else {
        thetaVol = _thetaVolumeTarget;
      }

      _audioPlayer.setVolume(voiceVol.clamp(0.0, 1.0));
      _thetaTrackPlayer.setVolume(thetaVol.clamp(0.0, 1.0));

      // Trigger rebuild so the UI countdown updates.
      setState(() {});
    });
  }

  // ===========================================================================
  // SLEEP SESSION — SINGLE EXIT POINT (fixes duplication)
  // ===========================================================================

  /// End sleep session. This is the ONE place sleep mode is deactivated.
  /// All exit points (timer expiry, settings toggle, player complete) call this.
  void _endSleepSession() {
    // Cancel timer first (before nulling _sleepModeStartedAt) to avoid
    // the force-unwrap crash in the timer callback.
    _sleepMasterTimer?.cancel();
    _sleepMasterTimer = null;
    _sleepModeStartedAt = null;

    // Reset audio player to normal state (speed and loop from user settings).
    _audioPlayer.setReleaseMode(
        _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
    _audioPlayer.setPlaybackRate(_normalPlaybackRate);
    _audioPlayer.setVolume(1.0);
    _audioPlayer.stop();

    // Stop theta background.
    _stopThetaBackground();

    // Restore screen brightness.
    _setSleepBrightness(false);

    if (mounted) {
      setState(() {
        _sleepModeActive = false;
        _isPlaying = false;
        _position = Duration.zero;
      });
      sleepModeNotifier.value = false;
    }
  }

  // ===========================================================================
  // THETA BACKGROUND — START / STOP
  // ===========================================================================

  Future<void> _startThetaBackground() async {
    final track = _thetaTracks[_selectedThetaIndex];

    // Stop any existing playback first.
    await _thetaTrackPlayer.stop();

    // Re-apply mix context right before playing so the session isn't exclusive.
    await _applyMixContext();

    await _thetaTrackPlayer.setReleaseMode(ReleaseMode.loop);
    await _thetaTrackPlayer.setVolume(_thetaVolumeTarget);

    try {
      await _thetaTrackPlayer.play(AssetSource(track.$2));
      // Re-set volume after play() — some platforms reset it.
      await _thetaTrackPlayer.setVolume(_thetaVolumeTarget);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Background sound could not load: ${track.$1}')),
        );
      }
    }
  }

  Future<void> _stopThetaBackground() async {
    await _thetaTrackPlayer.stop();
  }

  // ===========================================================================
  // BRIGHTNESS HELPER
  // ===========================================================================

  Future<void> _setSleepBrightness(bool dim) async {
    try {
      if (dim) {
        await ScreenBrightness.instance
            .setApplicationScreenBrightness(_sleepBrightness);
      } else {
        await ScreenBrightness.instance
            .resetApplicationScreenBrightness();
      }
    } catch (_) {}
  }

  // ===========================================================================
  // SUBSCRIPTION CHECK
  // ===========================================================================

  /// Subscription statuses that allow sleep mode (user has access).
  static const _sleepModeAllowedStatuses = [
    'trialing',
    'active',
    'past_due'
  ];

  /// Subscription plans that include sleep mode.
  static const _sleepModeAllowedPlans = ['weekly', 'annual'];

  static bool _canUseSleepMode(String? status, String? plan) {
    final s = (status ?? '').toString().toLowerCase().trim();
    final p = (plan ?? '').toString().toLowerCase().trim();
    if (!_sleepModeAllowedStatuses.contains(s)) return false;
    return _sleepModeAllowedPlans.contains(p);
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    _disposed = true;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _durationChangedSub?.cancel();
    _durationChangedSub = null;
    _positionChangedSub?.cancel();
    _positionChangedSub = null;
    _sleepMasterTimer?.cancel();
    _sleepMasterTimer = null;
    if (_sleepModeActive) {
      sleepModeNotifier.value = false;
      _setSleepBrightness(false);
    }
    _stopThetaBackground();
    _waveformController.dispose();
    _loopNotifier.dispose();
    _audioPlayer.dispose();
    _thetaTrackPlayer.dispose(); // FIX: was missing — leaked the theta player
    _model.dispose();
    super.dispose();
  }

  // ===========================================================================
  // PLAYBACK CONTROLS
  // ===========================================================================

  static const _totalWaveBars = 32;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayPause() async {
    final url = _playUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No audio available')));
      }
      return;
    }
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (_sleepModeActive) await _thetaTrackPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        // Re-apply mix context before resuming so both channels work.
        await _applyMixContext();

        if (_position == Duration.zero && _duration == Duration.zero) {
          await _audioPlayer.play(
              UrlSource(url), mode: PlayerMode.mediaPlayer);
        } else {
          await _audioPlayer.resume();
        }
        await _audioPlayer.setReleaseMode(
            _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
        if (_sleepModeActive) {
          await _audioPlayer.setPlaybackRate(_sleepPlaybackRate);
          await _audioPlayer.setVolume(_sleepVolumeTarget);
          // Resume theta if paused, otherwise start fresh.
          if (_thetaTrackPlayer.state == PlayerState.paused) {
            await _thetaTrackPlayer.resume();
          } else {
            await _startThetaBackground();
          }
          // Re-apply context one more time after both are running.
          await _applyMixContext();
        } else {
          await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
        }
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Playback failed: $e')));
        setState(() => _isPlaying = false);
      }
    }
  }

  static const _skipSeconds = 10;

  Future<void> _skipBackward() async {
    final newPos = _position.inSeconds - _skipSeconds;
    final target = Duration(seconds: newPos.clamp(0, _duration.inSeconds));
    await _audioPlayer.seek(target);
  }

  Future<void> _skipForward() async {
    final newPos = _position.inSeconds + _skipSeconds;
    final target = Duration(seconds: newPos.clamp(0, _duration.inSeconds));
    await _audioPlayer.seek(target);
  }

  // ===========================================================================
  // SETTINGS MODAL
  // ===========================================================================

  Future<void> _openSettingsModal() async {
    if (_sleepModeActive) {
      showSleepModeSettingsModal(
        context,
        selectedMinutes: _sleepTimerMinutes ?? 30,
        onTimerSelect: (m) => setState(() => _sleepTimerMinutes = m),
        sleepSpeedLabel: _sleepSpeedLabel,
        backgroundSoundName: _thetaTracks[_selectedThetaIndex].$1,
        onSleepModeChanged: (value) {
          if (!value) {
            Navigator.of(context).pop();
            _endSleepSession(); // single exit point
          }
        },
        onSleepSpeedTap: _openSleepSpeedSheet,
        onBackgroundSoundTap: _openThetaBackgroundSheet,
        onClose: () => Navigator.of(context).pop(),
      );
    } else {
      bool sleepModeAllowed = false;
      final userId = await SupabaseService.getCurrentUserTableId();
      if (userId != null) {
        try {
          final profile = await BackendClient.getUserProfile(userId);
          final status = (profile['subscription_status'] ??
                  profile['Subscription_Status'] ??
                  profile['subscription_Status'])
              ?.toString()
              .trim();
          final plan = (profile['subscription_plan'] ??
                  profile['Subscription_Plan'] ??
                  profile['subscription_Plan'])
              ?.toString()
              .trim();
          sleepModeAllowed = _canUseSleepMode(status, plan);
        } catch (_) {}
      }
      if (!mounted) return;
      _loopNotifier.value = _loopEnabled; // keep in sync so modal shows current state
      showPlaybackSettingsModal(
        context,
        sleepModeEnabled: _sleepModeActive,
        sleepModeAllowed: sleepModeAllowed,
        speedLabel: _normalSpeedLabel,
        loopEnabled: _loopEnabled,
        loopListenable: _loopNotifier,
        onSleepModeChanged: (value) {
          if (value) {
            Navigator.of(context).pop();
            showSleepTimerModal(
              context,
              selectedMinutes: _sleepTimerMinutes ?? 30,
              onSelect: (m) => setState(() => _sleepTimerMinutes = m),
              onStartSleepMode: () {
                Navigator.of(context).pop();
                // Use the single entry point!
                final playUrl = _playUrl?.trim();
                if (playUrl != null && playUrl.isNotEmpty) {
                  _startSleepSession(playUrl);
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            );
          }
        },
        onSpeedTap: _openNormalSpeedSheet,
        onLoopTap: _openLoopSheet,
      );
    }
  }

  // ===========================================================================
  // NORMAL SPEED (common player)
  // ===========================================================================

  String get _normalSpeedLabel {
    if (_normalPlaybackRate == 1.0) return 'Normal (1.0x)';
    return '${_formatSleepSpeed(_normalPlaybackRate)}x';
  }

  Future<void> _openNormalSpeedSheet() async {
    final current = _normalPlaybackRate;
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: _PlayerColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x261C1917),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _PlayerColors.stoneMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Speed',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _PlayerColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose playback speed for your story.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _PlayerColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: List<Widget>.from(
                  _speedOptions.map<Widget>((v) {
                    final isSelected = v == current;
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(v),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _PlayerColors.goldPale
                              : _PlayerColors.warmWhite,
                          border: Border.all(
                            color: isSelected
                                ? _PlayerColors.gold
                                : _PlayerColors.stone,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              v == 1.0
                                  ? 'Normal (1.0x)'
                                  : '${_formatSleepSpeed(v)}x',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _PlayerColors.ink,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(Icons.check,
                                  size: 18, color: _PlayerColors.gold),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != current) {
      setState(() {
        _normalPlaybackRate = selected;
      });
      if (!_sleepModeActive && _isPlaying) {
        await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
      }
      if (mounted) {
        final label = _normalSpeedLabel;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speed set to $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // LOOP SHEET (On / Off)
  // ===========================================================================

  Future<void> _openLoopSheet() async {
    final current = _loopEnabled;
    final selected = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: _PlayerColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x261C1917),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _PlayerColors.stoneMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Loop',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _PlayerColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Repeat the story when it ends (common and sleep mode).',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _PlayerColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              ...[false, true].map<Widget>((value) {
                final isOn = value;
                final isSelected = current == value;
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop(value),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _PlayerColors.goldPale
                          : _PlayerColors.warmWhite,
                      border: Border.all(
                        color: isSelected
                            ? _PlayerColors.gold
                            : _PlayerColors.stone,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Text(
                          isOn ? 'On' : 'Off',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _PlayerColors.ink,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check,
                              size: 18, color: _PlayerColors.gold),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != current) {
      setState(() => _loopEnabled = selected);
      _loopNotifier.value = selected; // so open Playback Settings modal updates immediately
      if (_isPlaying) {
        _audioPlayer.setReleaseMode(
            _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Loop ${_loopEnabled ? "on" : "off"}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // SLEEP SPEED SHEET
  // ===========================================================================

  String get _sleepSpeedLabel =>
      '${_formatSleepSpeed(_sleepPlaybackRate)}x';

  String _formatSleepSpeed(double value) {
    if (value % 1 == 0) {
      return value.toStringAsFixed(0);
    }
    final s = value.toStringAsFixed(2);
    return s.endsWith('0') ? s.substring(0, s.length - 1) : s;
  }

  Future<void> _openSleepSpeedSheet() async {
    final current = _sleepPlaybackRate;
    final selected = await showModalBottomSheet<double>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: _PlayerColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x261C1917),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: _PlayerColors.stoneMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Sleep Speed',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _PlayerColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how slowly your story plays in Sleep Mode.',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _PlayerColors.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: List<Widget>.from(
                  _speedOptions.map<Widget>((v) {
                    final isSelected = v == current;
                    return GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(v),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _PlayerColors.goldPale
                              : _PlayerColors.warmWhite,
                          border: Border.all(
                            color: isSelected
                                ? _PlayerColors.gold
                                : _PlayerColors.stone,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${_formatSleepSpeed(v)}x',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _PlayerColors.ink,
                              ),
                            ),
                            const Spacer(),
                            if (isSelected)
                              Icon(Icons.check,
                                  size: 18, color: _PlayerColors.gold),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && selected != current) {
      setState(() {
        _sleepPlaybackRate = selected;
      });
      if (_sleepModeActive) {
        await _audioPlayer.setPlaybackRate(_sleepPlaybackRate);
      }
      if (mounted) {
        final label = _sleepSpeedLabel;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sleep speed set to $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // THETA BACKGROUND SELECTOR SHEET
  // ===========================================================================

  Future<void> _openThetaBackgroundSheet() async {
    final currentIndex = _selectedThetaIndex;
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: _PlayerColors.surface,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Color(0x261C1917),
                blurRadius: 20,
                offset: Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: _PlayerColors.stoneMid,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    'Background Sound',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _PlayerColors.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Choose a theta wave track for Sleep Mode.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: _PlayerColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(_thetaTracks.length, (index) {
                      final track = _thetaTracks[index];
                      final isSelected = index == currentIndex;
                      return GestureDetector(
                        onTap: () => Navigator.of(ctx).pop(index),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _PlayerColors.goldPale
                                : _PlayerColors.warmWhite,
                            border: Border.all(
                              color: isSelected
                                  ? _PlayerColors.gold
                                  : _PlayerColors.stone,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '🎵',
                                style: GoogleFonts.outfit(fontSize: 16),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  track.$1,
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _PlayerColors.ink,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check,
                                    size: 18,
                                    color: _PlayerColors.gold),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (selected != null && selected != currentIndex) {
      setState(() {
        _selectedThetaIndex = selected;
      });
      if (_sleepModeActive) {
        // Re-apply context, then swap the theta track.
        await _applyMixContext();
        await _startThetaBackground();
        // Re-apply again after new theta starts.
        await Future.delayed(const Duration(milliseconds: 200));
        await _applyMixContext();
      }
      if (mounted) {
        final name = _thetaTracks[_selectedThetaIndex].$1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Background sound set to $name'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  // ===========================================================================
  // SLEEP REMAINING TIME
  // ===========================================================================

  int? get _sleepRemainingMinutes {
    final started = _sleepModeStartedAt;
    final total = _sleepTimerMinutes;
    if (started == null || total == null || total <= 0) return null;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final remaining = (total * 60) - elapsed;
    if (remaining <= 0) return 0;
    return (remaining / 60).ceil();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _sleepModeActive
            ? _PlayerColors.sleepDark
            : _PlayerColors.surface,
        body: Stack(
          children: [
            if (_sleepModeActive) ...[
              Positioned.fill(
                child: ColoredBox(color: _PlayerColors.sleepDark),
              ),
            ],
            SafeArea(
              top: true,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                          20, 0, 20, 0),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(bottom: 80),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _buildPlayerHeader(),
                            _buildWaveform(),
                            if (_sleepModeActive) _buildSleepInfo(),
                            _buildProgressSection(),
                            _buildControls(),
                            SizedBox(
                                height: _sleepModeActive ? 0 : 28),
                            if (!_sleepModeActive)
                              _buildStoryPreview(),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // UI BUILDERS
  // ===========================================================================

  Widget _buildPlayerHeader() {
    return Padding(
      padding:
          EdgeInsets.only(top: 24, bottom: _sleepModeActive ? 16 : 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: _sleepModeActive
            ? Alignment.topCenter
            : Alignment.topLeft,
        children: [
          Align(
            alignment: _sleepModeActive
                ? Alignment.topCenter
                : Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: _sleepModeActive
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                if (_sleepModeActive) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _PlayerColors.sleepPurple
                          .withValues(alpha: 0.3),
                      border: Border.all(
                          color: _PlayerColors.sleepPurple
                              .withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.nightlight_round,
                            size: 14, color: _PlayerColors.goldLight),
                        const SizedBox(width: 6),
                        Text(
                          'Sleep Mode Active',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  '${(_categoryLabel ?? 'Love').trim()} · Already Done'
                      .toUpperCase(),
                  textAlign:
                      _sleepModeActive ? TextAlign.center : null,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                    color: _sleepModeActive
                        ? Colors.white.withValues(alpha: 0.5)
                        : _PlayerColors.blush,
                  ),
                ),
                SizedBox(height: _sleepModeActive ? 8 : 12),
                Text(
                  _title ?? 'A Love That Was\nAlready Yours',
                  textAlign:
                      _sleepModeActive ? TextAlign.center : null,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: _sleepModeActive ? 20 : 32,
                    fontWeight: FontWeight.w400,
                    color: _sleepModeActive
                        ? Colors.white.withValues(alpha: 0.9)
                        : _PlayerColors.ink,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _duration.inSeconds > 0
                      ? '${_formatDuration(_duration.inSeconds)} · In your voice'
                      : (_durationLabel ??
                          _subtitle ??
                          'In your voice · Generated today'),
                  textAlign:
                      _sleepModeActive ? TextAlign.center : null,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: _sleepModeActive
                        ? Colors.white.withValues(alpha: 0.6)
                        : _PlayerColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: _openSettingsModal,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  '⚙️',
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    color: _sleepModeActive
                        ? Colors.white.withValues(alpha: 0.7)
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  int get _visibleWaveBars {
    final dur = _duration.inMilliseconds;
    if (dur <= 0) return 0;
    final pos = _position.inMilliseconds;
    final ratio = (pos / dur).clamp(0.0, 1.0);
    return (ratio * _totalWaveBars).round().clamp(0, _totalWaveBars);
  }

  static const _barHeights = [
    12.0, 24.0, 36.0, 20.0, 44.0, 32.0, 16.0, 28.0, 36.0, 24.0, 40.0,
    28.0, 16.0, 32.0, 20.0, 12.0
  ];

  /// Sleep mode: smaller bars per HTML
  static const _sleepBarHeights = [
    10.0, 18.0, 28.0, 36.0, 40.0, 36.0, 24.0, 16.0, 8.0
  ];

  Widget _buildWaveform() {
    final barCount = _sleepModeActive ? 9 : _totalWaveBars;
    final heights = _sleepModeActive ? _sleepBarHeights : _barHeights;
    final visible = _sleepModeActive
        ? (_duration.inMilliseconds > 0
            ? ((_position.inMilliseconds / _duration.inMilliseconds) *
                    barCount)
                .round()
                .clamp(0, barCount)
            : 0)
        : _visibleWaveBars;

    Widget waveRow;
    if (_sleepModeActive) {
      waveRow = AnimatedBuilder(
        animation: _waveformController,
        builder: (context, _) {
          final t = _waveformController.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final isPlayed = i < visible;
              final baseH = heights[i % heights.length];
              final h =
                  baseH * (0.55 + 0.45 * math.sin(t + i * math.pi / 4));
              return Padding(
                padding:
                    EdgeInsets.only(right: i < barCount - 1 ? 3 : 0),
                child: Container(
                  width: 6,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              _PlayerColors.goldLight,
                              _PlayerColors.gold,
                              _PlayerColors.sleepPurple,
                              _PlayerColors.sleepBlue,
                            ],
                            stops: [0.0, 0.35, 0.7, 1.0],
                          )
                        : null,
                    color: isPlayed
                        ? null
                        : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: _PlayerColors.sleepPurple
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      );
    } else {
      waveRow = AnimatedBuilder(
        animation: _waveformController,
        builder: (context, _) {
          final t = _waveformController.value * 2 * math.pi;
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(barCount, (i) {
              final isPlayed = i < visible;
              final baseH = heights[i % heights.length];
              final mult =
                  (0.55 + 0.45 * math.sin(t + i * math.pi / 4))
                      .clamp(0.2, 1.0);
              final h = baseH * mult;
              return Padding(
                padding:
                    EdgeInsets.only(right: i < barCount - 1 ? 3 : 0),
                child: Container(
                  width: 6,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              _PlayerColors.goldLight,
                              _PlayerColors.gold,
                              _PlayerColors.goldDark,
                            ],
                            stops: [0.0, 0.5, 1.0],
                          )
                        : null,
                    color: isPlayed ? null : _PlayerColors.stone,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: _PlayerColors.gold
                                  .withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          );
        },
      );
    }
    const fixedWaveHeight = 56.0;
    return Padding(
      padding: _sleepModeActive
          ? const EdgeInsets.fromLTRB(0, 24, 0, 16)
          : const EdgeInsets.fromLTRB(0, 48, 0, 48 + 24),
      child: SizedBox(
        height: fixedWaveHeight,
        child: Center(child: waveRow),
      ),
    );
  }

  /// Sleep info card
  Widget _buildSleepInfo() {
    final timerText = _sleepTimerMinutes == null
        ? 'Loop'
        : '${_sleepRemainingMinutes ?? _sleepTimerMinutes ?? 30} min';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _PlayerColors.sleepPurple.withValues(alpha: 0.2),
        border: Border.all(
            color: _PlayerColors.sleepPurple.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _sleepInfoItem('Speed', _sleepSpeedLabel, false),
          _sleepInfoItem('Loop', 'On', false),
          _sleepInfoItem('Timer', timerText, true),
        ],
      ),
    );
  }

  Widget _sleepInfoItem(String label, String value, bool valueIsGold) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w500,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: valueIsGold
                ? _PlayerColors.goldLight
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  /// Progress section: time row above 4px bar
  Widget _buildProgressSection() {
    final durMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds;
    final progress = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0;
    final textColor = _sleepModeActive
        ? Colors.white.withValues(alpha: 0.6)
        : _PlayerColors.inkSoft;
    final trackColor = _sleepModeActive
        ? Colors.white.withValues(alpha: 0.2)
        : _PlayerColors.stone;

    return Padding(
      padding: EdgeInsets.only(bottom: _sleepModeActive ? 20 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position.inSeconds),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
                Text(
                  _formatDuration(_duration.inSeconds),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontFeatures: const [
                      FontFeature.tabularFigures()
                    ],
                  ),
                ),
              ],
            ),
          ),
          LayoutBuilder(
            builder: (_, constraints) {
              final barWidth = constraints.maxWidth;
              return GestureDetector(
                onTapDown: durMs > 0 && barWidth > 0
                    ? (d) {
                        final rel = (d.localPosition.dx / barWidth)
                            .clamp(0.0, 1.0);
                        _audioPlayer.seek(Duration(
                            milliseconds: (rel * durMs).round()));
                      }
                    : null,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: _sleepModeActive
                              ? const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    _PlayerColors.goldLight,
                                    _PlayerColors.gold,
                                    _PlayerColors.sleepPurple,
                                  ],
                                  stops: [0.0, 0.5, 1.0],
                                )
                              : null,
                          color: _sleepModeActive
                              ? null
                              : _PlayerColors.gold,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  static const _iconPrev = '⏮';
  static const _iconRewind = '⏪';
  static const _iconPlay = '▶';
  static const _iconPause = '⏸';
  static const _iconForward = '⏩';
  static const _iconNext = '⏭';

  Widget _buildControls() {
    final hasUrl = _playUrl != null && _playUrl!.isNotEmpty;
    final controlsOpacity = _sleepModeActive ? 0.85 : 1.0;
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final isCompact = width < 400;
    final primarySize =
        isNarrow ? 52.0 : (isCompact ? 58.0 : 64.0);
    final secondarySize =
        isNarrow ? 38.0 : (isCompact ? 42.0 : 48.0);
    final spacing = isNarrow ? 8.0 : (isCompact ? 14.0 : 20.0);
    final sleepSpacing = isNarrow ? 20.0 : 32.0;

    final row = _sleepModeActive
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlBtn(_iconPrev, false,
                  hasUrl ? _skipBackward : null,
                  size: secondarySize),
              SizedBox(width: sleepSpacing),
              _controlBtn(
                  _isPlaying ? _iconPause : _iconPlay,
                  true,
                  hasUrl ? _togglePlayPause : null,
                  size: primarySize),
              SizedBox(width: sleepSpacing),
              _controlBtn(_iconNext, false,
                  hasUrl ? _skipForward : null,
                  size: secondarySize),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlBtn(_iconPrev, false,
                  hasUrl ? _skipBackward : null,
                  size: secondarySize),
              SizedBox(width: spacing),
              _controlBtn(_iconRewind, false,
                  hasUrl ? _skipBackward : null,
                  size: secondarySize),
              SizedBox(width: spacing),
              _controlBtn(
                  _isPlaying ? _iconPause : _iconPlay,
                  true,
                  hasUrl ? _togglePlayPause : null,
                  size: primarySize),
              SizedBox(width: spacing),
              _controlBtn(_iconForward, false,
                  hasUrl ? _skipForward : null,
                  size: secondarySize),
              SizedBox(width: spacing),
              _controlBtn(_iconNext, false,
                  hasUrl ? _skipForward : null,
                  size: secondarySize),
            ],
          );
    return Opacity(
      opacity: controlsOpacity,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width - 32),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: row,
          ),
        ),
      ),
    );
  }

  Widget _controlBtn(String symbol, bool primary, VoidCallback? onTap,
      {double? size}) {
    final btnSize = size ?? (primary ? 64.0 : 48.0);
    final fontSize = primary
        ? (btnSize * 0.4).clamp(18.0, 26.0)
        : (btnSize * 0.375).clamp(14.0, 20.0);
    final primaryColor =
        _sleepModeActive ? _PlayerColors.sleepPurple : _PlayerColors.gold;
    final secondaryColor = _sleepModeActive
        ? Colors.white.withValues(alpha: 0.5)
        : _PlayerColors.inkMid;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(btnSize / 2),
      splashColor:
          (primary ? Colors.white : primaryColor).withValues(alpha: 0.2),
      highlightColor:
          (primary ? Colors.white : primaryColor).withValues(alpha: 0.1),
      child: Container(
        width: btnSize,
        height: btnSize,
        decoration: BoxDecoration(
          color: primary ? primaryColor : Colors.transparent,
          shape: BoxShape.circle,
          boxShadow: primary
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.4),
                    blurRadius: _sleepModeActive ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            symbol,
            style: TextStyle(
              fontSize: fontSize,
              color: primary ? Colors.white : secondaryColor,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _modeBtn(String label, bool active) {
    return Pressable(
      onTap: () {
        // TODO: switch mode (Standard/Sleep/Loop)
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? _PlayerColors.goldPale
              : _PlayerColors.surface,
          border: Border.all(
            color: active ? _PlayerColors.gold : _PlayerColors.stone,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: active ? _PlayerColors.gold : _PlayerColors.inkSoft,
          ),
        ),
      ),
    );
  }

  Widget _buildStoryPreview() {
    final preview = _previewContent;

    return Container(
      margin: const EdgeInsets.only(top: 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _PlayerColors.warmWhite,
        border: Border.all(color: _PlayerColors.stone),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'STORY PREVIEW',
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: _PlayerColors.blush,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            preview ?? 'No preview available.',
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: _PlayerColors.inkMid,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}