import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/last_played_service.dart';
import 'package:flutter/material.dart';
import '/services/sleep_mode_notifier.dart';
import '/services/nav_lock_notifier.dart';
import '/services/backend_client.dart';
import '/services/ai_consent_service.dart';
import '/services/app_toast.dart';
import '/services/rating_prompt_controller.dart';
import '/services/supabase_service.dart';
import '/index.dart';
import 'player_modals/player_modals.dart';
import 'player_modals/player_option_sheets.dart';
import 'player_model.dart';
import 'player_colors.dart';
import 'player_constants.dart';
import 'player_story_utils.dart';
import 'player_story_loader.dart';
import 'coachmark/done_library_coachmark_nav.dart';
import 'coachmark/player_done_library_coachmark.dart';
import 'coachmark/player_settings_coachmark.dart';
import 'widgets/player_blocking_overlay.dart';
import 'widgets/player_body.dart';
import 'widgets/player_no_story_state.dart';
export 'player_model.dart';

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
    this.voiceId,
  });

  final int? storyId;
  final String? categoryLabel;
  final String? title;
  final String? subtitle;
  final String? durationLabel;

  final String? playUrl;
  final String? storyPreview;

  final String? voiceId;

  static String routeName = 'Player';
  static String routePath = '/player';

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget>
    with SingleTickerProviderStateMixin {
  String _nextResetMessage() {
    final now = DateTime.now();
    final nextMidnight =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final time = dateTimeFormat('jm', nextMidnight);
    final date = dateTimeFormat('MMM d', nextMidnight);
    return 'You can create one story or deepen per day. Try again at $time ($date).';
  }

  late PlayerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey _playerBodyStackKey = GlobalKey();
  final GlobalKey _settingsCoachmarkButtonKey = GlobalKey();
  final AudioPlayer _audioPlayer = AudioPlayer();

  final AudioPlayer _thetaTrackPlayer = AudioPlayer();

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
  String? _playContentType;
  String? _voiceId;
  bool _loading = true;
  String? _loadError;
  bool _hasNoStory = false;

  int? _currentStoryId;
  bool _isGeneratingVoice = false;

  bool _isDeepening = false;

  static final Map<String, String> _voicePlayUrlCache = {};

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool _sleepModeActive = false;
  int? _sleepTimerMinutes = 30;
  DateTime? _sleepModeStartedAt;

  Timer? _sleepMasterTimer;

  double _normalPlaybackRate = 1.0;
  bool _loopEnabled = false;

  final ValueNotifier<bool> _loopNotifier = ValueNotifier(false);
  final ValueNotifier<String> _speedLabelNotifier =
      ValueNotifier<String>('Normal (1.0x)');

  late final ValueNotifier<String> _backgroundSoundNameNotifier;

  late AnimationController _waveformController;
  int _selectedThetaIndex = 0;
  bool _backgroundSoundEnabled = true;

  String get _currentThetaTrackName =>
      PlayerConstants.thetaTracks[_selectedThetaIndex].$1;

  bool _showSettingsCoachmark = false;
  bool _showDoneLibraryCoachmark = false;

  Duration get _expectedDuration =>
      PlayerStoryUtils.expectedDuration(_durationLabel);

  Duration get _effectiveDuration => PlayerStoryUtils.effectiveDuration(
        durationLabel: _durationLabel,
        playbackDuration: _duration,
      );

  String get _categoryHeaderLine =>
      PlayerStoryUtils.categoryHeaderLine(_categoryLabel);

  String get _voiceLabel => PlayerStoryUtils.voiceLabel(_voiceId);

  String get _normalSpeedLabel =>
      PlayerStoryUtils.normalSpeedLabel(_normalPlaybackRate);

  String get _sleepSpeedLabel =>
      PlayerStoryUtils.sleepSpeedLabel(_normalPlaybackRate);

  String? _settingsCoachmarkStorageKeyOrNull() {
    final id = SupabaseService.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return '${PlayerConstants.settingsCoachmarkKeyPrefix}${id.toLowerCase()}';
  }

  String? _doneLibraryCoachmarkStorageKeyOrNull() {
    final id = SupabaseService.currentUser?.id;
    if (id == null || id.isEmpty) return null;
    return '${PlayerConstants.doneLibraryCoachmarkKeyPrefix}${id.toLowerCase()}';
  }

  Future<void> _maybeShowSettingsCoachmark() async {
    if (!mounted) return;
    if (_sleepModeActive) return;
    if (_isGeneratingVoice || _isDeepening) return;

    final key = _settingsCoachmarkStorageKeyOrNull();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getBool(key) ?? false;
    if (seen) return;
    if (!mounted) return;
    setState(() => _showSettingsCoachmark = true);
  }

  Future<void> _maybeShowDoneLibraryCoachmark() async {
    if (!mounted) return;
    if (_showSettingsCoachmark) return;
    if (_sleepModeActive) return;
    if (_isGeneratingVoice || _isDeepening) return;
    if (_loading || _hasNoStory) return;

    final settingsKey = _settingsCoachmarkStorageKeyOrNull();
    final prefs = await SharedPreferences.getInstance();
    final settingsSeen =
        settingsKey != null ? (prefs.getBool(settingsKey) ?? false) : false;
    if (!settingsSeen) return;

    final key = _doneLibraryCoachmarkStorageKeyOrNull();
    if (key == null) return;
    final seen = prefs.getBool(key) ?? false;
    if (seen) return;
    if (!mounted) return;
    setState(() => _showDoneLibraryCoachmark = true);
    doneLibraryCoachmarkVisible.value = true;
  }

  Future<void> _dismissDoneLibraryCoachmark() async {
    if (!_showDoneLibraryCoachmark) return;
    setState(() => _showDoneLibraryCoachmark = false);
    doneLibraryCoachmarkVisible.value = false;
    final key = _doneLibraryCoachmarkStorageKeyOrNull();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
  }

  Future<void> _onDoneTabDuringLibraryCoachmark() async {
    if (!_showDoneLibraryCoachmark) return;
    await _dismissDoneLibraryCoachmark();
  }

  void _afterPlayerLoadedForCoachmarks() {
    if (!mounted || _loading || _hasNoStory) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_maybeShowDoneLibraryCoachmark());
    });
  }

  Future<void> _dismissSettingsCoachmark() async {
    if (!_showSettingsCoachmark) return;
    setState(() => _showSettingsCoachmark = false);
    final key = _settingsCoachmarkStorageKeyOrNull();
    if (key == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, true);
    if (mounted) await _maybeShowDoneLibraryCoachmark();
  }

  AudioContext _buildMixAudioContext() {
    return AudioContextConfig(
      focus: AudioContextConfigFocus.mixWithOthers,
      respectSilence: false,
    ).build();
  }

  Future<void> _applyMixContext() async {
    final ctx = _buildMixAudioContext();
    await _audioPlayer.setAudioContext(ctx);
    await _thetaTrackPlayer.setAudioContext(ctx);
  }

  @override
  void initState() {
    super.initState();
    _backgroundSoundNameNotifier =
        ValueNotifier<String>(_currentThetaTrackName);
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _model = createModel(context, () => PlayerModel());
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _thetaTrackPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _thetaTrackPlayer.setReleaseMode(ReleaseMode.loop);

    _applyMixContext();

    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) async {
      final wasSleepMode = _sleepModeActive;
      if (!_disposed && mounted) {
        _stopThetaBackground();
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
        if (_sleepModeActive) {
          _endSleepSession();
        }
        unawaited(
          RatingPromptController.evaluateAfterPlaybackComplete(
            skipForSleepSession: wasSleepMode,
          ),
        );
      }
    });
    _durationChangedSub = _audioPlayer.onDurationChanged.listen((d) {
      if (!_disposed && mounted) {
        setState(() {
          _duration = d > _expectedDuration ? d : _expectedDuration;
        });
      }
    });
    _positionChangedSub = _audioPlayer.onPositionChanged.listen((p) {
      if (!_disposed && mounted) setState(() => _position = p);
    });
    _loadStoryData();

    doneLibraryCoachmarkOnDoneTabDismiss = _onDoneTabDuringLibraryCoachmark;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await SupabaseService.waitForCurrentUserId();
      if (!mounted) return;
      await _maybeShowSettingsCoachmark();
      if (mounted) await _maybeShowDoneLibraryCoachmark();
    });
  }

  Future<void> _loadStoryData() async {
    final previewFromWidget = (widget.storyPreview ?? '').trim();
    if (previewFromWidget.isNotEmpty) {
      setState(() {
        _previewContent = previewFromWidget;
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
          _voiceId =
              widget.voiceId?.trim().isNotEmpty == true ? widget.voiceId : null;
          _loading = false;
        });
        _saveLastPlayed();
        _afterPlayerLoadedForCoachmarks();
        return;
      }
      List<dynamic>? storiesList;
      final userId = await SupabaseService.getCurrentUserTableId();
      if (userId != null) {
        try {
          final res = await BackendClient.getStories(userId);
          debugPrint('res: $res');
          storiesList = (res['stories'] as List<dynamic>?) ?? [];
          debugPrint('list: $storiesList');
          if (storiesList.isEmpty) {
            await LastPlayedService.clearLastPlayed();
            if (!mounted) return;
            setState(() {
              _hasNoStory = true;
              _loading = false;
              _playUrl = null;
            });
            return;
          }
        } catch (_) {}
      }

      final lastPlayed = await LastPlayedService.loadLastPlayed();
      if (lastPlayed != null &&
          lastPlayed['playUrl']?.toString().trim().isNotEmpty == true) {
        final playUrl = lastPlayed['playUrl']!.toString().trim();
        final title = lastPlayed['title']?.toString().trim();
        final categoryLabel = lastPlayed['categoryLabel']?.toString().trim();
        final durationLabel = lastPlayed['durationLabel']?.toString().trim();
        final storyPreview = lastPlayed['storyPreview']?.toString().trim();
        final storyContent = lastPlayed['storyContent']?.toString().trim();
        final voiceId = lastPlayed['voiceId']?.toString().trim();
        final sid = lastPlayed['storyId'];
        final currentId =
            sid is int ? sid : int.tryParse(sid?.toString() ?? '');
        if (currentId == null) {
          await LastPlayedService.clearLastPlayed();
        } else {
          if (!mounted) return;
          setState(() {
            _playUrl = playUrl;
            _title = title;
            _categoryLabel = categoryLabel ?? 'Love';
            _subtitle = widget.subtitle;
            _durationLabel = durationLabel;
            _voiceId =
                voiceId != null && voiceId.isNotEmpty ? voiceId : null;
            _currentStoryId = currentId;
            if (storyPreview != null && storyPreview.isNotEmpty) {
              _previewContent = storyPreview;
            }
            if (storyContent != null && storyContent.isNotEmpty) {
              _fullStoryContent = storyContent;
            }
            _loading = false;
            _loadError = null;
          });
          if (voiceId != null &&
              voiceId.isNotEmpty &&
              playUrl.isNotEmpty) {
            _voicePlayUrlCache[
                PlayerStoryUtils.voiceCacheKey(currentId, voiceId)] = playUrl;
          }
          _maybeAutoPlayAndActivateSleepMode();
          _afterPlayerLoadedForCoachmarks();
          return;
        }
      }

      Map<String, dynamic>? fallback =
          await PlayerStoryLoader.loadLastCreatedStory();
      if (fallback == null &&
          storiesList != null &&
          storiesList.isNotEmpty) {
        fallback =
            await PlayerStoryLoader.loadFirstAvailableFromList(storiesList);
      }
      if (fallback != null && !mounted) return;
      final fallbackMap = fallback;
      if (fallbackMap != null) {
        final playUrl = fallbackMap['playUrl']!.toString().trim();
        final voiceId = fallbackMap['voiceId']?.toString().trim();
        final storyId = fallbackMap['storyId'] is int
            ? fallbackMap['storyId'] as int
            : int.tryParse(fallbackMap['storyId']?.toString() ?? '');
        setState(() {
          _playUrl = playUrl;
          _title = fallbackMap['title'];
          _categoryLabel = fallbackMap['categoryLabel'] ?? 'Love';
          _durationLabel = fallbackMap['durationLabel'];
          _previewContent = fallbackMap['storyPreview'];
          _fullStoryContent = fallbackMap['storyContent']?.toString().trim();
          _voiceId = voiceId != null && voiceId.isNotEmpty ? voiceId : null;
          _currentStoryId = storyId;
          _loading = false;
          _loadError = null;
        });
        if (storyId != null &&
            voiceId != null &&
            voiceId.isNotEmpty &&
            playUrl.isNotEmpty) {
          _voicePlayUrlCache[
              PlayerStoryUtils.voiceCacheKey(storyId, voiceId)] = playUrl;
        }
        LastPlayedService.saveLastPlayed(
          storyId: fallbackMap['storyId'] as int?,
          playUrl: playUrl,
          title: _title,
          categoryLabel: _categoryLabel,
          durationLabel: _durationLabel,
          storyPreview: _previewContent,
          storyContent: fallbackMap['storyContent']?.toString().trim(),
          voiceId: _voiceId,
        );
        _maybeAutoPlayAndActivateSleepMode();
        _afterPlayerLoadedForCoachmarks();
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
        _voiceId =
            widget.voiceId?.trim().isNotEmpty == true ? widget.voiceId : null;
        _hasNoStory = true;
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
        _voiceId =
            widget.voiceId?.trim().isNotEmpty == true ? widget.voiceId : null;
        if (widget.storyId != null) _currentStoryId = widget.storyId;
      });
    }

    try {
      final res = await SupabaseService.client
          .from('Stories')
          .select(
              'theme, story, title, content, desire_name, category, playUrl, storage, voice_id')
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
          _voiceId =
              widget.voiceId?.trim().isNotEmpty == true ? widget.voiceId : null;
        });
        return;
      }

      final data = res;
      final content = (data['story'] ?? data['content'])?.toString().trim();
      final playUrl = widget.playUrl ??
          data['playUrl']?.toString() ??
          data['play_url']?.toString();

      final preview = (content != null && content.isNotEmpty)
          ? content
          : (_previewContent ?? widget.storyPreview?.trim());

      String? storyVoiceId = PlayerStoryUtils.parseVoiceIdFromMap(data);
      if ((storyVoiceId == null || storyVoiceId.isEmpty) &&
          widget.storyId != null) {
        final userId = await SupabaseService.getCurrentUserTableId();
        if (userId != null && mounted) {
          try {
            final storiesRes = await BackendClient.getStories(userId);
            final list = (storiesRes['stories'] as List<dynamic>?) ?? [];
            for (final s in list) {
              final map = s is Map<String, dynamic> ? s : <String, dynamic>{};
              final id = map['id'] ?? map['Id'];
              final sid = id is int ? id : int.tryParse(id?.toString() ?? '');
              if (sid == widget.storyId) {
                storyVoiceId = PlayerStoryUtils.parseVoiceIdFromMap(map);
                if (storyVoiceId != null && storyVoiceId.isNotEmpty) break;
              }
            }
          } catch (_) {}
        }
      }

      final voiceIdToSet = (storyVoiceId != null && storyVoiceId.isNotEmpty)
          ? storyVoiceId
          : (widget.voiceId?.trim().isNotEmpty == true ? widget.voiceId : null);

      if (!mounted) return;
      setState(() {
        _title = (data['theme'] ?? data['title'])?.toString() ?? widget.title;
        _categoryLabel = (data['desire_name'] ?? data['category'])?.toString() ??
            widget.categoryLabel ??
            'Love';
        _subtitle = widget.subtitle;
        _durationLabel = widget.durationLabel;
        _previewContent =
            (preview != null && preview.toString().trim().isNotEmpty)
                ? preview.toString()
                : null;
        _fullStoryContent = content;
        _playUrl = playUrl;
        _voiceId = voiceIdToSet;
        _loading = false;
        _loadError = null;
        if (widget.storyId != null) _currentStoryId = widget.storyId;
      });
      if (widget.storyId != null &&
          voiceIdToSet != null &&
          voiceIdToSet.isNotEmpty &&
          playUrl != null) {
        final urlStr = playUrl.toString().trim();
        if (urlStr.isNotEmpty) {
          _voicePlayUrlCache[
              PlayerStoryUtils.voiceCacheKey(widget.storyId!, voiceIdToSet)] =
              urlStr;
        }
      }
      _saveLastPlayed();
      _afterPlayerLoadedForCoachmarks();
      if (voiceIdToSet == null && widget.storyId != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchVoiceIdFromStoriesOnce();
        });
      }
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
        _voiceId =
            widget.voiceId?.trim().isNotEmpty == true ? widget.voiceId : null;
      });
    }
  }

  Future<void> _fetchVoiceIdFromStoriesOnce() async {
    if (_voiceId != null && _voiceId!.trim().isNotEmpty) return;
    if (_currentStoryId == null || _disposed || !mounted) return;
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?) ?? [];
      for (final s in list) {
        final map = s is Map<String, dynamic> ? s : <String, dynamic>{};
        final id = map['id'] ?? map['Id'];
        final sid = id is int ? id : int.tryParse(id?.toString() ?? '');
        if (sid != _currentStoryId) continue;
        final voiceId = PlayerStoryUtils.parseVoiceIdFromMap(map);
        if (voiceId != null && voiceId.isNotEmpty && mounted) {
          setState(() => _voiceId = voiceId);
        }
        return;
      }
    } catch (_) {}
  }

  void _saveLastPlayed() {
    final url = _playUrl?.trim();
    if (url == null || url.isEmpty) return;
    LastPlayedService.saveLastPlayed(
      storyId: _currentStoryId ?? widget.storyId,
      playUrl: url,
      title: _title,
      categoryLabel: _categoryLabel,
      durationLabel: _durationLabel,
      storyPreview: _previewContent,
      storyContent: _fullStoryContent,
      voiceId: _voiceId,
    );
  }

  void _maybeAutoPlayAndActivateSleepMode() {
    final url = _playUrl?.trim();
    if (url == null || url.isEmpty || !mounted) return;
    if (sleepModeNotifier.value) {
      _startSleepSession(url);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _disposed) return;
        await _applyMixContext();
        await _audioPlayer.play(
          PlayerStoryUtils.urlSource(url, contentType: _playContentType),
          mode: PlayerMode.mediaPlayer,
        );
        await _audioPlayer.setReleaseMode(
            _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
        await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
        if (mounted) setState(() => _isPlaying = true);
      });
    }
  }

  Future<void> _startSleepSession(String url) async {
    if (_disposed || !mounted) return;

    final wasAlreadyPlaying = _isPlaying;

    setState(() {
      _sleepModeActive = true;
      sleepModeNotifier.value = true;
      _sleepModeStartedAt = DateTime.now();
    });

    await _audioPlayer.setReleaseMode(
        _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
    await _audioPlayer.setPlaybackRate(_normalPlaybackRate);

    _setSleepBrightness(true);

    await _applyMixContext();

    await _startThetaBackground();
    await Future.delayed(const Duration(milliseconds: 300));

    if (_disposed || !mounted) return;

    await _applyMixContext();

    if (wasAlreadyPlaying) {
      await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
      await _audioPlayer.setVolume(1.0);
    } else {
      await _audioPlayer.play(
        PlayerStoryUtils.urlSource(url, contentType: _playContentType),
        mode: PlayerMode.mediaPlayer,
      );
    }

    if (_disposed || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 200));
    await _applyMixContext();

    await _audioPlayer.setVolume(1.0);
    await _thetaTrackPlayer.setVolume(PlayerConstants.thetaVolumeTarget);

    _startSleepMasterTimer();

    if (mounted) setState(() => _isPlaying = true);
  }

  void _startSleepMasterTimer() {
    _sleepMasterTimer?.cancel();
    _sleepMasterTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }

      final started = _sleepModeStartedAt;
      if (started == null) {
        timer.cancel();
        return;
      }

      final elapsed = DateTime.now().difference(started).inSeconds;
      final totalSeconds = (_sleepTimerMinutes ?? 30) * 60;
      final remaining = totalSeconds - elapsed;

      if (remaining <= 0) {
        timer.cancel();
        _sleepMasterTimer = null;
        _endSleepSession();
        return;
      }

      double voiceVol;
      if (elapsed < PlayerConstants.sleepVolumeFadeInSeconds) {
        final progress = elapsed / PlayerConstants.sleepVolumeFadeInSeconds;
        voiceVol = 1.0 -
            ((1.0 - PlayerConstants.sleepVolumeTarget) * progress);
      } else if (remaining <= PlayerConstants.sleepFadeOutSeconds) {
        voiceVol = PlayerConstants.sleepVolumeTarget *
            (remaining / PlayerConstants.sleepFadeOutSeconds);
      } else {
        voiceVol = PlayerConstants.sleepVolumeTarget;
      }

      double thetaVol;
      if (remaining <= PlayerConstants.sleepFadeOutSeconds) {
        thetaVol = PlayerConstants.thetaVolumeTarget *
            (remaining / PlayerConstants.sleepFadeOutSeconds);
      } else {
        thetaVol = PlayerConstants.thetaVolumeTarget;
      }

      _audioPlayer.setVolume(voiceVol.clamp(0.0, 1.0));
      _thetaTrackPlayer.setVolume(thetaVol.clamp(0.0, 1.0));

      setState(() {});
    });
  }

  void _endSleepSession() {
    _sleepMasterTimer?.cancel();
    _sleepMasterTimer = null;
    _sleepModeStartedAt = null;

    _audioPlayer.setReleaseMode(
        _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
    _audioPlayer.setPlaybackRate(_normalPlaybackRate);
    _audioPlayer.setVolume(1.0);
    _audioPlayer.stop();

    _stopThetaBackground();

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

  Future<void> _startThetaBackground() async {
    await _thetaTrackPlayer.stop();
    if (!_backgroundSoundEnabled) return;

    final track = PlayerConstants.thetaTracks[_selectedThetaIndex];
    await _applyMixContext();

    await _thetaTrackPlayer.setReleaseMode(ReleaseMode.loop);
    await _thetaTrackPlayer.setVolume(PlayerConstants.thetaVolumeTarget);

    try {
      await _thetaTrackPlayer.play(AssetSource(track.$2));
      await _thetaTrackPlayer.setVolume(PlayerConstants.thetaVolumeTarget);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Background sound could not load: ${track.$1}'),
          ),
        );
      }
    }
  }

  Future<void> _stopThetaBackground() async {
    await _thetaTrackPlayer.stop();
  }

  Future<void> _setSleepBrightness(bool dim) async {
    try {
      if (dim) {
        await ScreenBrightness.instance.setApplicationScreenBrightness(
          PlayerConstants.sleepBrightness,
        );
      } else {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
    } catch (_) {}
  }

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
    _speedLabelNotifier.dispose();
    _backgroundSoundNameNotifier.dispose();
    _audioPlayer.dispose();
    _thetaTrackPlayer.dispose();
    _model.dispose();
    doneLibraryCoachmarkOnDoneTabDismiss = null;
    doneLibraryCoachmarkVisible.value = false;
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    final url = _playUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio available')),
        );
      }
      return;
    }
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (_sleepModeActive) await _thetaTrackPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        await _applyMixContext();
        final effectiveDuration = _effectiveDuration;
        if (_position == Duration.zero ||
            (effectiveDuration > Duration.zero &&
                _position >= effectiveDuration)) {
          await _audioPlayer.play(
            PlayerStoryUtils.urlSource(url, contentType: _playContentType),
            mode: PlayerMode.mediaPlayer,
          );
        } else {
          await _audioPlayer.resume();
        }
        await _audioPlayer.setReleaseMode(
            _loopEnabled ? ReleaseMode.loop : ReleaseMode.stop);
        if (_sleepModeActive) {
          await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
          await _audioPlayer.setVolume(PlayerConstants.sleepVolumeTarget);
          if (_thetaTrackPlayer.state == PlayerState.paused) {
            await _thetaTrackPlayer.resume();
          } else {
            await _startThetaBackground();
          }
          await _applyMixContext();
        } else {
          await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
        }
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback failed: $e')),
        );
        setState(() => _isPlaying = false);
      }
    }
  }

  Future<void> _skipBackward() async {
    final newPos = _position.inSeconds - PlayerConstants.skipSeconds;
    final target = Duration(
      seconds: newPos.clamp(0, _effectiveDuration.inSeconds),
    );
    await _audioPlayer.seek(target);
  }

  Future<void> _skipForward() async {
    final newPos = _position.inSeconds + PlayerConstants.skipSeconds;
    final target = Duration(
      seconds: newPos.clamp(0, _effectiveDuration.inSeconds),
    );
    await _audioPlayer.seek(target);
  }

  Future<void> _skipToPreviousStory() async {
    await _skipToAdjacentStory(previous: true);
  }

  Future<void> _skipToNextStory() async {
    await _skipToAdjacentStory(previous: false);
  }

  Future<void> _skipToAdjacentStory({required bool previous}) async {
    final currentId = _currentStoryId;
    if (currentId == null) return;
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      final res = await BackendClient.getStories(userId);
      final rawList = (res['stories'] as List<dynamic>?) ?? [];
      final list = rawList
          .map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .where((e) => (e['id'] ?? e['Id']) != null)
          .toList();
      if (list.isEmpty) return;

      list.sort((a, b) {
        final aAt = a['created_at'] ?? a['id'] ?? 0;
        final bAt = b['created_at'] ?? b['id'] ?? 0;
        if (aAt == bAt) return 0;
        return aAt.toString().compareTo(bAt.toString());
      });

      int currentIndex = -1;
      for (var i = 0; i < list.length; i++) {
        final id = list[i]['id'] ?? list[i]['Id'];
        final sid = id is int ? id : int.tryParse(id?.toString() ?? '');
        if (sid == currentId) {
          currentIndex = i;
          break;
        }
      }
      if (currentIndex < 0) return;

      final nextIndex = previous
          ? (currentIndex - 1 + list.length) % list.length
          : (currentIndex + 1) % list.length;
      final story = list[nextIndex];
      final idRaw = story['id'] ?? story['Id'];
      final storyId =
          idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
      if (storyId == null) return;

      final storyVoiceId =
          (story['voice_id'] ?? story['voice_Id'])?.toString().trim();

      String? playUrl =
          (story['playUrl'] ?? story['play_url'])?.toString().trim();
      if (playUrl == null || playUrl.isEmpty) {
        try {
          final urlRes = await BackendClient.getStoryPlayUrl(storyId);
          playUrl = urlRes['playUrl']?.toString().trim();
        } catch (_) {}
      }
      String? voiceIdForCache = storyVoiceId;
      if (playUrl == null || playUrl.isEmpty) {
        final voiceIdToUse = storyVoiceId?.isNotEmpty == true
            ? storyVoiceId
            : (await PlayerStoryLoader.getUserVoiceId());
        if (voiceIdToUse == null || voiceIdToUse.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Could not switch story: no voice available'),
              ),
            );
          }
          return;
        }
        try {
          final genRes = await BackendClient.voiceGenerateAudio(
            voiceId: voiceIdToUse,
            storyId: storyId,
          );
          playUrl = genRes['url']?.toString().trim();
          _playContentType = genRes['content_type']?.toString().trim();
          voiceIdForCache = voiceIdToUse;
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not generate audio: $e')),
            );
          }
          return;
        }
      }
      if (playUrl == null || playUrl.isEmpty) return;
      if (!mounted) return;

      final content = (story['story'] ?? story['content'])?.toString().trim();
      final preview = content != null && content.isNotEmpty ? content : null;
      final durationLabel = PlayerStoryUtils.durationLabelFromStory(story);
      final title = (story['theme'] ??
              story['title'] ??
              story['desire_name'] ??
              'Story')
          .toString();
      final categoryLabel =
          (story['desire_name'] ?? story['category'] ?? 'Love').toString();

      setState(() {
        _playUrl = playUrl;
        _title = title;
        _categoryLabel = categoryLabel;
        _durationLabel = durationLabel;
        _previewContent = preview;
        _fullStoryContent = content;
        _currentStoryId = storyId;
        _voiceId =
            storyVoiceId != null && storyVoiceId.isNotEmpty ? storyVoiceId : null;
        _loadError = null;
      });

      if (voiceIdForCache != null &&
          voiceIdForCache.isNotEmpty &&
          playUrl.isNotEmpty) {
        _voicePlayUrlCache[
            PlayerStoryUtils.voiceCacheKey(storyId, voiceIdForCache)] = playUrl;
      }

      LastPlayedService.saveLastPlayed(
        storyId: storyId,
        playUrl: playUrl,
        title: title,
        categoryLabel: categoryLabel,
        durationLabel: durationLabel,
        storyPreview: preview,
        storyContent: content,
        voiceId: storyVoiceId,
      );

      await _audioPlayer.stop();
      await _audioPlayer.setSource(
        PlayerStoryUtils.urlSource(playUrl, contentType: _playContentType),
      );
      if (_isPlaying) await _audioPlayer.resume();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not switch story')),
        );
      }
    }
  }

  Future<void> _openSettingsModal() async {
    if (_sleepModeActive) {
      _speedLabelNotifier.value = _sleepSpeedLabel;
      showSleepModeSettingsModal(
        context,
        selectedMinutes: _sleepTimerMinutes ?? 30,
        onTimerSelect: (m) => setState(() => _sleepTimerMinutes = m),
        onSleepModeChanged: (value) {
          if (!value) {
            Navigator.of(context).pop();
            _endSleepSession();
          }
        },
        sleepSpeedLabel: _sleepSpeedLabel,
        sleepSpeedListenable: _speedLabelNotifier,
        backgroundSoundEnabled: _backgroundSoundEnabled,
        onBackgroundSoundEnabledChanged: (value) {
          setState(() => _backgroundSoundEnabled = value);
          if (_sleepModeActive) {
            if (value) {
              _startThetaBackground();
            } else {
              _stopThetaBackground();
            }
          }
        },
        backgroundSoundName: PlayerConstants.thetaTracks[_selectedThetaIndex].$1,
        backgroundSoundListenable: _backgroundSoundNameNotifier,
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
          final status = (profile['rc_subscription_status'] ??
                  profile['rc_subscription_status'] ??
                  profile['rc_subscription_status'])
              ?.toString()
              .trim();
          final plan = (profile['rc_subscription_plan'] ??
                  profile['rc_subscription_plan'] ??
                  profile['rc_subscription_plan'])
              ?.toString()
              .trim();
          sleepModeAllowed = PlayerStoryUtils.canUseSleepMode(status, plan);
        } catch (_) {}
      }
      if (!mounted) return;
      _loopNotifier.value = _loopEnabled;
      _speedLabelNotifier.value = _normalSpeedLabel;
      showPlaybackSettingsModal(
        context,
        sleepModeEnabled: _sleepModeActive,
        sleepModeAllowed: sleepModeAllowed,
        speedLabel: _normalSpeedLabel,
        speedListenable: _speedLabelNotifier,
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

  Future<void> _openNormalSpeedSheet() async {
    final current = _normalPlaybackRate;
    final selected = await PlayerOptionSheets.showSpeedSheet(
      context,
      currentRate: current,
      title: 'Speed',
      subtitle: 'Choose playback speed for your story.',
    );

    if (selected != null && selected != current) {
      setState(() {
        _normalPlaybackRate = selected;
      });
      _speedLabelNotifier.value = _normalSpeedLabel;
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

  Future<void> _openLoopSheet() async {
    final current = _loopEnabled;
    final selected = await PlayerOptionSheets.showLoopSheet(
      context,
      currentEnabled: current,
    );

    if (selected != null && selected != current) {
      setState(() => _loopEnabled = selected);
      _loopNotifier.value = selected;
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

  Future<void> _openSleepSpeedSheet() async {
    final current = _normalPlaybackRate;
    final selected = await PlayerOptionSheets.showSpeedSheet(
      context,
      currentRate: current,
      title: 'Sleep Speed',
      subtitle: 'Choose how slowly your story plays in Sleep Mode.',
      sleepStyle: true,
    );

    if (selected != null && selected != current) {
      setState(() {
        _normalPlaybackRate = selected;
      });
      _speedLabelNotifier.value = _normalSpeedLabel;
      if (_sleepModeActive) {
        await _audioPlayer.setPlaybackRate(_normalPlaybackRate);
      }
      if (mounted) {
        final label = _sleepSpeedLabel;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Speed set to $label'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _openThetaBackgroundSheet() async {
    final currentIndex = _selectedThetaIndex;
    final selected = await PlayerOptionSheets.showThetaBackgroundSheet(
      context,
      currentIndex: currentIndex,
    );

    if (selected != null && selected != currentIndex) {
      setState(() {
        _selectedThetaIndex = selected;
      });
      _backgroundSoundNameNotifier.value =
          PlayerConstants.thetaTracks[_selectedThetaIndex].$1;
      if (_sleepModeActive) {
        await _applyMixContext();
        await _startThetaBackground();
        await Future.delayed(const Duration(milliseconds: 200));
        await _applyMixContext();
      }
      if (mounted) {
        final name = PlayerConstants.thetaTracks[_selectedThetaIndex].$1;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Background sound set to $name'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  int? get _sleepRemainingMinutes {
    final started = _sleepModeStartedAt;
    final total = _sleepTimerMinutes;
    if (started == null || total == null || total <= 0) return null;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final remaining = (total * 60) - elapsed;
    if (remaining <= 0) return 0;
    return (remaining / 60).ceil();
  }

  String get _storyPreviewText {
    final fullText = _fullStoryContent ?? _previewContent;
    return fullText?.trim().isNotEmpty == true
        ? fullText!
        : 'No preview available.';
  }

  String get _sleepTimerText => _sleepTimerMinutes == null
      ? 'Loop'
      : '${_sleepRemainingMinutes ?? _sleepTimerMinutes ?? 30} min';

  Future<void> _onSettingsTap() async {
    await _dismissSettingsCoachmark();
    _openSettingsModal();
  }

  Future<void> _onVoiceChanged(String? selectedValue) async {
    if (selectedValue == null ||
        selectedValue == PlayerStoryUtils.voiceDropdownValue(_voiceId)) {
      return;
    }
    final storyId = _currentStoryId;
    if (storyId == null) return;
    late final String voiceIdToUse;
    if (selectedValue == PlayerConstants.voiceDropdownMyVoice) {
      final userVoiceId = await PlayerStoryLoader.getUserVoiceId();
      if (userVoiceId == null || userVoiceId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your voice is not available. Please record your voice first.',
              ),
            ),
          );
        }
        return;
      }
      voiceIdToUse = userVoiceId;
    } else {
      voiceIdToUse = selectedValue;
    }
    if (!mounted) return;

    final cacheKey = PlayerStoryUtils.voiceCacheKey(storyId, voiceIdToUse);
    final cachedUrl = _voicePlayUrlCache[cacheKey]?.trim();
    if (cachedUrl != null && cachedUrl.isNotEmpty) {
      final wasPlaying = _isPlaying;
      setState(() {
        _playUrl = cachedUrl;
        _voiceId = voiceIdToUse;
      });
      LastPlayedService.saveLastPlayed(
        storyId: storyId,
        playUrl: cachedUrl,
        title: _title,
        categoryLabel: _categoryLabel,
        durationLabel: _durationLabel,
        storyPreview: _previewContent,
        storyContent: _fullStoryContent,
        voiceId: voiceIdToUse,
      );
      await _audioPlayer.stop();
      await _audioPlayer.setSource(
        PlayerStoryUtils.urlSource(cachedUrl, contentType: _playContentType),
      );
      if (wasPlaying) await _audioPlayer.resume();
      if (mounted) setState(() => _isPlaying = wasPlaying);
      return;
    }

    setState(() => _isGeneratingVoice = true);
    try {
      final res = await BackendClient.voiceGenerateAudio(
        voiceId: voiceIdToUse,
        storyId: storyId,
      );
      final url = res['url']?.toString().trim();
      final contentType = res['content_type']?.toString().trim();
      if (url == null || url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not generate audio. Please try again.'),
            ),
          );
        }
        return;
      }
      _voicePlayUrlCache[cacheKey] = url;
      final wasPlaying = _isPlaying;
      setState(() {
        _playUrl = url;
        _playContentType = contentType;
        _voiceId = voiceIdToUse;
        _isGeneratingVoice = false;
      });
      LastPlayedService.saveLastPlayed(
        storyId: storyId,
        playUrl: url,
        title: _title,
        categoryLabel: _categoryLabel,
        durationLabel: _durationLabel,
        storyPreview: _previewContent,
        storyContent: _fullStoryContent,
        voiceId: voiceIdToUse,
      );
      await _audioPlayer.stop();
      await _audioPlayer.setSource(
        PlayerStoryUtils.urlSource(url, contentType: contentType),
      );
      if (wasPlaying) await _audioPlayer.resume();
      if (mounted) setState(() => _isPlaying = wasPlaying);
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingVoice = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not switch voice: $e')),
        );
      }
    }
  }

  Future<void> _deepenManifestation() async {
    if (_isDeepening) return;
    final hasConsent = await AIConsentService.ensureConsent(context);
    if (!hasConsent) {
      if (mounted) {
        AppToast.info(
          context,
          'You need to agree to AI data sharing to deepen your manifestation.',
        );
      }
      return;
    }
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    final storyId = _currentStoryId;
    if (storyId == null) {
      if (mounted) {
        AppToast.info(context, 'No story selected to deepen.');
      }
      return;
    }
    if (!mounted) return;
    final shouldAutoPlayNew = _isPlaying;
    try {
      await _audioPlayer.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _position = Duration.zero;
        _isDeepening = true;
      });
    }
    navLockNotifier.value = true;
    String name = '';
    String location = '';
    String energyWord = '';
    String lovedOne = '';
    String dreamLocation = '';
    try {
      final profile = await BackendClient.getUserProfile(userId);
      name = (profile['name'] ?? '').toString().trim();
      location = (profile['location'] ?? profile['dream_place'] ?? '')
          .toString()
          .trim();
      energyWord = (profile['energyWord'] ?? '').toString().trim();
      lovedOne = (profile['lovedOne'] ?? profile['someone_you_love'] ?? '')
          .toString()
          .trim();
      dreamLocation =
          (profile['dream_place'] ?? profile['dreamLocation'] ?? '')
              .toString()
              .trim();
    } catch (_) {}
    if (!mounted) {
      setState(() => _isDeepening = false);
      navLockNotifier.value = false;
      return;
    }
    try {
      final res = await BackendClient.deepenStory(
        userId: userId,
        storyId: storyId,
        name: name,
        location: location,
        energyWord: energyWord,
        lovedOne: lovedOne,
        dreamLocation: dreamLocation,
      );

      debugPrint('deepen res: $res');

      if (!mounted) return;
      final theme =
          (res['theme'] ?? res['title'] ?? 'Deepened Story').toString().trim();
      final story = (res['story'] ?? res['content'] ?? '').toString().trim();
      if (story.isEmpty) {
        AppToast.error(context, 'Deepen response had no story content.');
        return;
      }

      final newStoryIdRaw = res['id'] ?? res['story_id'] ?? res['storyId'];
      final newStoryId = newStoryIdRaw is int
          ? newStoryIdRaw
          : int.tryParse(newStoryIdRaw?.toString() ?? '');
      int storyIdToUse = newStoryId ?? storyId;
      if (newStoryId == null) {
        try {
          final storiesRes = await BackendClient.getStories(userId);
          debugPrint('storiesRes: $storiesRes');
          final list = (storiesRes['stories'] as List<dynamic>?) ?? const [];
          int? bestId;
          for (final s in list) {
            final map = s is Map<String, dynamic> ? s : <String, dynamic>{};
            final idRaw = map['id'] ?? map['Id'];
            final sid =
                idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
            if (sid == null) continue;
            if (bestId == null || sid > bestId) bestId = sid;
          }
          if (bestId != null) storyIdToUse = bestId;
        } catch (_) {}
      }

      final voiceIdToUse = (_voiceId ?? '').trim().isNotEmpty
          ? _voiceId!.trim()
          : await PlayerStoryLoader.getUserVoiceId();

      debugPrint('voiceIdToUse: $voiceIdToUse');

      if (!mounted) return;
      setState(() {
        _currentStoryId = storyIdToUse;
        _title = theme;
        _previewContent = story;
        _fullStoryContent = story;
        _playUrl = null;
        _playContentType = null;
      });

      String? newAudioUrl;
      String? newContentType;
      if (voiceIdToUse != null && voiceIdToUse.isNotEmpty) {
        try {
          final audioRes = await BackendClient.voiceGenerateAudio(
            voiceId: voiceIdToUse,
            storyId: storyIdToUse,
          );
          debugPrint('audioRes: $audioRes');
          final url = audioRes['url']?.toString().trim();
          final contentType = audioRes['content_type']?.toString().trim();
          if (url != null && url.isNotEmpty) {
            newAudioUrl = url;
            newContentType = contentType;
            _voicePlayUrlCache[
                PlayerStoryUtils.voiceCacheKey(storyIdToUse, voiceIdToUse)] =
                url;
          }
        } catch (e) {
          debugPrint('deepen audio generation failed: $e');
          if (mounted) {
            AppToast.error(
              context,
              'Deepened story saved, but audio is not ready yet. Try play again shortly.',
            );
          }
        }
      }

      debugPrint('newAudioUrl: $newAudioUrl');

      if (!mounted) return;
      setState(() {
        if (newAudioUrl != null && newAudioUrl.isNotEmpty) {
          _playUrl = newAudioUrl;
          _playContentType = newContentType;
        }
      });

      if (newAudioUrl != null && newAudioUrl.isNotEmpty) {
        try {
          final source = PlayerStoryUtils.urlSource(
            newAudioUrl,
            contentType: newContentType,
          );
          if (shouldAutoPlayNew) {
            await _audioPlayer.play(source, mode: PlayerMode.mediaPlayer);
          } else {
            await _audioPlayer.setSource(source);
          }
          if (mounted) setState(() => _isPlaying = shouldAutoPlayNew);
        } catch (e) {
          debugPrint('deepen audio playback failed: $e');
          if (mounted) setState(() => _isPlaying = false);
        }
      }

      _saveLastPlayed();
      showDeepenResultModal(context, theme: theme, story: story);
    } catch (e) {
      if (mounted) {
        final msg = e.toString();
        if (msg.contains('403') &&
            (msg.contains('1 story per day') ||
                msg.contains('story per day'))) {
          AppToast.info(context, _nextResetMessage());
        } else {
          AppToast.error(
            context,
            'Could not deepen story: ${msg.replaceAll(RegExp(r'^Exception:?\s*'), '')}',
          );
        }
      }
    } finally {
      navLockNotifier.value = false;
      if (mounted) setState(() => _isDeepening = false);
    }
  }

  void _onDeepenTap() {
    if (_isDeepening) return;
    _checkSubscriptionThenDeepen();
  }

  Future<void> _checkSubscriptionThenDeepen() async {
    bool isSubscribed = false;
    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      if (userId != null) {
        final profile = await BackendClient.getUserProfile(userId);
        final status = (profile['rc_subscription_status'] ??
                profile['rc_subscription_Status'])
            ?.toString()
            .toLowerCase()
            .trim();
        isSubscribed = status == 'active' || status == 'trial';
      }
    } catch (_) {}
    if (!mounted) return;
    if (!isSubscribed) {
      context.go(SubscriptionWidget.routePath);
      return;
    }

    showDeepenConfirmModal(
      context,
      onContinue: _deepenManifestation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasUrl = _playUrl != null && _playUrl!.isNotEmpty;
    final canSkipStory = hasUrl && _currentStoryId != null;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: _sleepModeActive
            ? PlayerColors.sleepDark
            : PlayerColors.surface,
        body: Stack(
          key: _playerBodyStackKey,
          clipBehavior: Clip.none,
          children: [
            if (_sleepModeActive)
              const Positioned.fill(
                child: ColoredBox(color: PlayerColors.sleepDark),
              ),
            SafeArea(
              top: true,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _hasNoStory
                      ? const PlayerNoStoryState()
                      : Padding(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            20,
                            0,
                            20,
                            0,
                          ),
                          child: PlayerBody(
                            settingsButtonKey: _settingsCoachmarkButtonKey,
                            sleepModeActive: _sleepModeActive,
                            categoryHeaderLine: _categoryHeaderLine,
                            title: _title ?? 'A Love That Was\nAlready Yours',
                            durationLabel: _durationLabel,
                            subtitle: _subtitle,
                            voiceLabel: _voiceLabel,
                            isGeneratingVoice: _isGeneratingVoice,
                            showSettingsCoachmark: _showSettingsCoachmark,
                            waveformController: _waveformController,
                            onSettingsTap: _onSettingsTap,
                            position: _position,
                            effectiveDuration: _effectiveDuration,
                            isPlaying: _isPlaying,
                            hasUrl: hasUrl,
                            canSkipStory: canSkipStory,
                            audioPlayer: _audioPlayer,
                            onTogglePlayPause: hasUrl ? _togglePlayPause : null,
                            onSkipBackward: hasUrl ? _skipBackward : null,
                            onSkipForward: hasUrl ? _skipForward : null,
                            onSkipToPreviousStory: canSkipStory
                                ? _skipToPreviousStory
                                : null,
                            onSkipToNextStory:
                                canSkipStory ? _skipToNextStory : null,
                            sleepSpeedLabel: _sleepSpeedLabel,
                            sleepTimerText: _sleepTimerText,
                            isDeepening: _isDeepening,
                            onDeepenTap: _onDeepenTap,
                            storyPreviewText: _storyPreviewText,
                          ),
                        ),
            ),
            if (_isGeneratingVoice)
              const PlayerBlockingOverlay(
                message:
                    'Updating your story with the selected voice. This can take 30-45 seconds.',
                hint: "Please keep the app open and don't lock your screen.",
              ),
            if (_isDeepening)
              const PlayerBlockingOverlay(
                message:
                    'Deepening your manifestation. This can take up to 60 ~ 90 seconds.',
                hint: "Please keep the app open and don't lock your screen.",
              ),
            if (_showSettingsCoachmark)
              Positioned.fill(
                child: PlayerSettingsCoachmarkOverlay(
                  stackKey: _playerBodyStackKey,
                  settingsTargetKey: _settingsCoachmarkButtonKey,
                  onGotIt: () => _dismissSettingsCoachmark(),
                  onSettingsTap: () async {
                    await _dismissSettingsCoachmark();
                    if (mounted) _openSettingsModal();
                  },
                ),
              )
            else if (_showDoneLibraryCoachmark)
              Positioned.fill(
                child: PlayerDoneLibraryCoachmarkOverlay(
                  stackKey: _playerBodyStackKey,
                  doneTabTargetKey: doneLibraryCoachmarkTabKey,
                  onGotIt: () => _dismissDoneLibraryCoachmark(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
