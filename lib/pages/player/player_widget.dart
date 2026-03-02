import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/services/last_played_service.dart';
import '/services/theta_wave_generator.dart';
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

class _PlayerWidgetState extends State<PlayerWidget> with SingleTickerProviderStateMixin {
  late PlayerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ThetaWaveGenerator _thetaGenerator = ThetaWaveGenerator(volume: 0.05);

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
  Timer? _sleepCountdownTimer;
  Timer? _sleepVolumeFadeTimer;

  /// Sleep mode playback speed (only used when sleep mode is active).
  /// Default is 0.75x.
  static const List<double> _sleepSpeedOptions = [0.5, 0.75, 1.0];
  double _sleepPlaybackRate = 0.75;

  /// Sleep mode: target narration volume (70% per client spec).
  static const double _sleepVolumeTarget = 0.7;
  /// Fade-to-silence duration at end of sleep timer (seconds).
  static const int _sleepFadeOutSeconds = 60;
  /// Screen brightness when sleep mode active (~40%).
  static const double _sleepBrightness = 0.4;

  late AnimationController _waveformController;

  @override
  void initState() {
    super.initState();
    _waveformController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _model = createModel(context, () => PlayerModel());
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    _playerCompleteSub = _audioPlayer.onPlayerComplete.listen((_) {
      if (!_disposed && mounted && !_sleepModeActive) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
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
          if (_previewContent == null && previewFromWidget.isEmpty) _previewContent = null;
          _playUrl = widget.playUrl;
          _loading = false;
        });
        _saveLastPlayed();
        return;
      }
      final lastPlayed = await LastPlayedService.loadLastPlayed();
      if (lastPlayed != null && lastPlayed['playUrl']?.toString().trim().isNotEmpty == true) {
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
            _previewContent = storyPreview.length > 200 ? '${storyPreview.substring(0, 200)}...' : storyPreview;
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
        if (_previewContent == null && previewFromWidget.isEmpty) _previewContent = null;
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
          .select('theme, story, title, content, desire_name, category, playUrl, storage')
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
      final content = (data['story'] ?? data['content'])?.toString().trim();
      final playUrl = widget.playUrl ??
          data['playUrl']?.toString() ??
          data['play_url']?.toString();
      final storage = data['storage']?.toString();

      final preview = (content != null && content.isNotEmpty)
          ? (content.length > 200 ? '${content.substring(0, 200)}...' : content)
          : (_previewContent ?? widget.storyPreview?.trim());

      setState(() {
        _title = (data['theme'] ?? data['title'])?.toString() ?? widget.title;
        _categoryLabel = (data['desire_name'] ?? data['category'])?.toString() ?? widget.categoryLabel ?? 'Love';
        _subtitle = widget.subtitle;
        _durationLabel = widget.durationLabel;
        _previewContent = (preview != null && preview.toString().trim().isNotEmpty)
            ? (preview.toString().length > 200 ? '${preview.toString().substring(0, 200)}...' : preview.toString())
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

  /// Load the last created story when no last played exists. Returns map with
  /// playUrl, title, categoryLabel, durationLabel, storyPreview, storyId or null.
  Future<Map<String, dynamic>?> _loadLastCreatedStory() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return null;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      final voiceId = profile['voice_id']?.toString().trim() ?? profile['voice_Id']?.toString().trim();
      if (voiceId == null || voiceId.isEmpty) return null;

      final res = await BackendClient.getStories(userId);
      final list = (res['stories'] as List<dynamic>?)
          ?.map((e) => e is Map<String, dynamic> ? e : <String, dynamic>{})
          .toList() ?? [];
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

      final speakRes = await BackendClient.voiceSpeak(voiceId: voiceId, storyId: storyId);
      final playUrl = speakRes['url']?.toString().trim();
      if (playUrl == null || playUrl.isEmpty) return null;

      final content = (story['story'] ?? story['content'])?.toString().trim();
      final preview = content != null && content.isNotEmpty
          ? (content.length > 200 ? '${content.substring(0, 200)}...' : content)
          : null;
      final duration = story['play_length'] ?? story['duration'];
      int secs = 0;
      if (duration != null) {
        if (duration is int) secs = duration;
        else if (duration is num) secs = duration.round();
        else secs = int.tryParse(duration.toString()) ?? 0;
      }
      final m = secs ~/ 60;
      final s = secs % 60;
      final durationLabel = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      return {
        'playUrl': playUrl,
        'storyId': storyId,
        'title': (story['theme'] ?? story['title'] ?? story['desire_name'] ?? 'Story').toString(),
        'categoryLabel': (story['desire_name'] ?? story['category'] ?? 'Love').toString(),
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

  /// When opened from navbar or Unlock Sleep Mode (no story params), auto-play last played.
  /// If sleepModeNotifier is true (came from Unlock Sleep Mode), activate sleep mode first.
  void _maybeAutoPlayAndActivateSleepMode() {
    final url = _playUrl?.trim();
    if (url == null || url.isEmpty || !mounted) return;
    if (sleepModeNotifier.value) {
      _activateSleepModeAndPlay(url);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _disposed) return;
        _audioPlayer.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
        setState(() => _isPlaying = true);
      });
    }
  }

  void _activateSleepModeAndPlay(String url) {
    setState(() {
      _sleepModeActive = true;
      sleepModeNotifier.value = true;
      _sleepModeStartedAt = DateTime.now();
    });
    _audioPlayer.setReleaseMode(ReleaseMode.loop);
    _audioPlayer.setPlaybackRate(_sleepPlaybackRate);

    _sleepVolumeFadeTimer?.cancel();
    _audioPlayer.setVolume(1.0);
    const fadeDurationSeconds = 120;
    const stepSeconds = 10;
    int step = 0;
    _sleepVolumeFadeTimer = Timer.periodic(const Duration(seconds: stepSeconds), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      step++;
      final target = _sleepVolumeTarget + (1.0 - _sleepVolumeTarget) * (1 - (step * stepSeconds / fadeDurationSeconds).clamp(0.0, 1.0));
      _audioPlayer.setVolume(target.clamp(0.0, 1.0));
      if (step * stepSeconds >= fadeDurationSeconds) {
        t.cancel();
        _sleepVolumeFadeTimer = null;
        _audioPlayer.setVolume(_sleepVolumeTarget);
      }
    });

    _thetaGenerator.start();
    _setSleepBrightness(true);

    final minutes = _sleepTimerMinutes;
    if (minutes != null && minutes > 0) {
      _sleepCountdownTimer?.cancel();
      _sleepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        final elapsed = DateTime.now().difference(_sleepModeStartedAt!).inSeconds;
        final remaining = (minutes * 60) - elapsed;
        if (remaining <= 0) {
          t.cancel();
          _sleepCountdownTimer = null;
          _endSleepMode();
        } else {
          if (remaining <= _sleepFadeOutSeconds) {
            final vol = (remaining / _sleepFadeOutSeconds) * _sleepVolumeTarget;
            _audioPlayer.setVolume(vol.clamp(0.0, 1.0));
            _thetaGenerator.setVolume((remaining / _sleepFadeOutSeconds) * 0.15);
          }
          setState(() {});
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _disposed) return;
      await _audioPlayer.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
      await _audioPlayer.setPlaybackRate(_sleepPlaybackRate);
      await _audioPlayer.setVolume(_sleepVolumeTarget);
      if (mounted) setState(() => _isPlaying = true);
    });
  }

  Future<void> _setSleepBrightness(bool dim) async {
    try {
      if (dim) {
        await ScreenBrightness.instance.setApplicationScreenBrightness(_sleepBrightness);
      } else {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
    } catch (_) {}
  }

  void _endSleepMode() {
    _sleepCountdownTimer?.cancel();
    _sleepCountdownTimer = null;
    _sleepVolumeFadeTimer?.cancel();
    _sleepVolumeFadeTimer = null;
    _sleepModeStartedAt = null;
    _audioPlayer.setReleaseMode(ReleaseMode.stop);
    _audioPlayer.setPlaybackRate(1.0);
    _audioPlayer.setVolume(1.0);
    _audioPlayer.stop();
    _thetaGenerator.stop();
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

  @override
  void dispose() {
    _disposed = true;
    _playerCompleteSub?.cancel();
    _playerCompleteSub = null;
    _durationChangedSub?.cancel();
    _durationChangedSub = null;
    _positionChangedSub?.cancel();
    _positionChangedSub = null;
    _sleepCountdownTimer?.cancel();
    _sleepVolumeFadeTimer?.cancel();
    if (_sleepModeActive) {
      sleepModeNotifier.value = false;
      _setSleepBrightness(false);
    }
    _thetaGenerator.stop();
    _waveformController.dispose();
    _audioPlayer.dispose();
    _model.dispose();
    super.dispose();
  }

  static const _totalWaveBars = 32;

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _togglePlayPause() async {
    final url = _playUrl;
    if (url == null || url.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No audio available')));
      return;
    }
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        if (_position == Duration.zero && _duration == Duration.zero) {
          await _audioPlayer.play(UrlSource(url), mode: PlayerMode.mediaPlayer);
        } else {
          await _audioPlayer.resume();
        }
        if (_sleepModeActive) {
          await _audioPlayer.setPlaybackRate(_sleepPlaybackRate);
          await _audioPlayer.setVolume(_sleepVolumeTarget);
        }
        if (mounted) setState(() => _isPlaying = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playback failed: $e')));
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

  /// Subscription statuses that allow sleep mode (user has access).
  static const _sleepModeAllowedStatuses = ['trialing', 'active', 'past_due'];
  /// Subscription plans that include sleep mode.
  static const _sleepModeAllowedPlans = ['weekly', 'annual'];

  static bool _canUseSleepMode(String? status, String? plan) {
    final s = (status ?? '').toString().toLowerCase().trim();
    final p = (plan ?? '').toString().toLowerCase().trim();
    if (!_sleepModeAllowedStatuses.contains(s)) return false;
    return _sleepModeAllowedPlans.contains(p);
  }

  Future<void> _openSettingsModal() async {
    if (_sleepModeActive) {
      showSleepModeSettingsModal(
        context,
        selectedMinutes: _sleepTimerMinutes ?? 30,
        onTimerSelect: (m) => setState(() => _sleepTimerMinutes = m),
        sleepSpeedLabel: _sleepSpeedLabel,
        onSleepModeChanged: (value) {
          if (!value) {
            Navigator.of(context).pop();
            _sleepCountdownTimer?.cancel();
            _sleepCountdownTimer = null;
            _sleepVolumeFadeTimer?.cancel();
            _sleepVolumeFadeTimer = null;
            _sleepModeStartedAt = null;
            _audioPlayer.setReleaseMode(ReleaseMode.stop);
            _audioPlayer.setPlaybackRate(1.0);
            _audioPlayer.setVolume(1.0);
            _audioPlayer.stop();
            _thetaGenerator.stop();
            _setSleepBrightness(false);
            if (mounted) {
              setState(() {
                _sleepModeActive = false;
                sleepModeNotifier.value = false;
                _isPlaying = false;
                _position = Duration.zero;
              });
            }
          }
        },
        onSleepSpeedTap: _openSleepSpeedSheet,
        onBackgroundSoundTap: () {},
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
      showPlaybackSettingsModal(
        context,
        sleepModeEnabled: _sleepModeActive,
        sleepModeAllowed: sleepModeAllowed,
        onSleepModeChanged: (value) {
          if (value) {
            Navigator.of(context).pop();
            showSleepTimerModal(
              context,
              selectedMinutes: _sleepTimerMinutes ?? 30,
              onSelect: (m) => setState(() => _sleepTimerMinutes = m),
              onStartSleepMode: () {
                Navigator.of(context).pop();
                setState(() {
                  _sleepModeActive = true;
                  sleepModeNotifier.value = true;
                  _sleepModeStartedAt = DateTime.now();
                });
                _audioPlayer.setReleaseMode(ReleaseMode.loop);
                _audioPlayer.setPlaybackRate(_sleepPlaybackRate);

                // Softer volume: gradually fade to 70% over 2 minutes (client spec).
                _sleepVolumeFadeTimer?.cancel();
                _audioPlayer.setVolume(1.0);
                const fadeDurationSeconds = 120;
                const stepSeconds = 10;
                int step = 0;
                _sleepVolumeFadeTimer = Timer.periodic(const Duration(seconds: stepSeconds), (t) {
                  if (!mounted) {
                    t.cancel();
                    return;
                  }
                  step++;
                  final target = _sleepVolumeTarget + (1.0 - _sleepVolumeTarget) * (1 - (step * stepSeconds / fadeDurationSeconds).clamp(0.0, 1.0));
                  _audioPlayer.setVolume(target.clamp(0.0, 1.0));
                  if (step * stepSeconds >= fadeDurationSeconds) {
                    t.cancel();
                    _sleepVolumeFadeTimer = null;
                    _audioPlayer.setVolume(_sleepVolumeTarget);
                  }
                });

                // Theta wave background (4–8 Hz binaural) generated in real-time per ThetaWaveGenerator.js spec.
                _thetaGenerator.start();

                // Visual changes: dim screen to ~40%, blue light filter applied via overlay.
                _setSleepBrightness(true);

                final minutes = _sleepTimerMinutes;
                if (minutes != null && minutes > 0) {
                  _sleepCountdownTimer?.cancel();
                  _sleepCountdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
                    if (!mounted) {
                      t.cancel();
                      return;
                    }
                    final elapsed = DateTime.now().difference(_sleepModeStartedAt!).inSeconds;
                    final remaining = (minutes * 60) - elapsed;
                    if (remaining <= 0) {
                      t.cancel();
                      _sleepCountdownTimer = null;
                      _endSleepMode();
                    } else {
                      // Auto-fade to silence in last 60 seconds (client spec).
                      if (remaining <= _sleepFadeOutSeconds) {
                        final vol = (remaining / _sleepFadeOutSeconds) * _sleepVolumeTarget;
                        _audioPlayer.setVolume(vol.clamp(0.0, 1.0));
                        _thetaGenerator.setVolume((remaining / _sleepFadeOutSeconds) * 0.15);
                      }
                      setState(() {});
                    }
                  });
                }
              },
              onCancel: () => Navigator.of(context).pop(),
            );
          }
        },
        onSpeedTap: () {
          Navigator.of(context).pop();
          // TODO: open speed selector
        },
        onLoopTap: () {
          Navigator.of(context).pop();
          // TODO: open loop options
        },
      );
    }
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
        backgroundColor: _sleepModeActive ? _PlayerColors.sleepDark : _PlayerColors.surface,
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
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 0),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Player header
                        _buildPlayerHeader(),

                        // Waveform
                        _buildWaveform(),

                        // Sleep info (when sleep mode active) - above progress per HTML design
                        if (_sleepModeActive) _buildSleepInfo(),

                        // Progress section (time + bar) - per HTML .progress-section
                        _buildProgressSection(),

                        // Controls (margin-bottom 0 in sleep mode per HTML)
                        _buildControls(),
                        SizedBox(height: _sleepModeActive ? 0 : 28),

                        // Story preview card
                        if (!_sleepModeActive) _buildStoryPreview(),
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

  Widget _buildPlayerHeader() {
    return Padding(
      padding: EdgeInsets.only(top: 24, bottom: _sleepModeActive ? 16 : 24),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: _sleepModeActive ? Alignment.topCenter : Alignment.topLeft,
        children: [
          Align(
            alignment: _sleepModeActive ? Alignment.topCenter : Alignment.topLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: _sleepModeActive ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
              if (_sleepModeActive) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _PlayerColors.sleepPurple.withValues(alpha: 0.3),
                    border: Border.all(color: _PlayerColors.sleepPurple.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nightlight_round, size: 14, color: _PlayerColors.goldLight),
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
                '${(_categoryLabel ?? 'Love').trim()} · Already Done'.toUpperCase(),
                textAlign: _sleepModeActive ? TextAlign.center : null,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  color: _sleepModeActive ? Colors.white.withValues(alpha: 0.5) : _PlayerColors.blush,
                ),
              ),
              SizedBox(height: _sleepModeActive ? 8 : 12),
              Text(
                _title ?? 'A Love That Was\nAlready Yours',
                textAlign: _sleepModeActive ? TextAlign.center : null,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: _sleepModeActive ? 20 : 32,
                  fontWeight: FontWeight.w400,
                  color: _sleepModeActive ? Colors.white.withValues(alpha: 0.9) : _PlayerColors.ink,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _duration.inSeconds > 0
                    ? '${_formatDuration(_duration.inSeconds)} · In your voice'
                    : (_durationLabel ?? _subtitle ?? 'In your voice · Generated today'),
                textAlign: _sleepModeActive ? TextAlign.center : null,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: _sleepModeActive ? Colors.white.withValues(alpha: 0.6) : _PlayerColors.inkSoft,
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
                    color: _sleepModeActive ? Colors.white.withValues(alpha: 0.7) : null,
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

  static const _barHeights = [12.0, 24.0, 36.0, 20.0, 44.0, 32.0, 16.0, 28.0, 36.0, 24.0, 40.0, 28.0, 16.0, 32.0, 20.0, 12.0];
  /// Sleep mode: smaller bars per HTML (10,18,28,36,40,36,24,16,8)
  static const _sleepBarHeights = [10.0, 18.0, 28.0, 36.0, 40.0, 36.0, 24.0, 16.0, 8.0];

  String get _sleepSpeedLabel => '${_formatSleepSpeed(_sleepPlaybackRate)}x';

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
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).padding.bottom + 24),
          decoration: const BoxDecoration(
            color: _PlayerColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                children: _sleepSpeedOptions.map((v) {
                  final isSelected = v == current;
                  return GestureDetector(
                    onTap: () => Navigator.of(ctx).pop(v),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _PlayerColors.goldPale
                            : _PlayerColors.warmWhite,
                        border: Border.all(
                          color: isSelected ? _PlayerColors.gold : _PlayerColors.stone,
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
                            Icon(Icons.check, size: 18, color: _PlayerColors.gold),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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

  int? get _sleepRemainingMinutes {
    final started = _sleepModeStartedAt;
    final total = _sleepTimerMinutes;
    if (started == null || total == null || total <= 0) return null;
    final elapsed = DateTime.now().difference(started).inSeconds;
    final remaining = (total * 60) - elapsed;
    if (remaining <= 0) return 0;
    return (remaining / 60).ceil();
  }

  /// Sleep info per HTML: single card, padding 12px, margin-bottom 20px
  Widget _buildSleepInfo() {
    final timerText = _sleepTimerMinutes == null
        ? 'Loop'
        : '${_sleepRemainingMinutes ?? _sleepTimerMinutes ?? 30} min';
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _PlayerColors.sleepPurple.withValues(alpha: 0.2),
        border: Border.all(color: _PlayerColors.sleepPurple.withValues(alpha: 0.3)),
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
            color: valueIsGold ? _PlayerColors.goldLight : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildWaveform() {
    final barCount = _sleepModeActive ? 9 : _totalWaveBars;
    final heights = _sleepModeActive ? _sleepBarHeights : _barHeights;
    final visible = _sleepModeActive
        ? (_duration.inMilliseconds > 0
            ? ((_position.inMilliseconds / _duration.inMilliseconds) * barCount).round().clamp(0, barCount)
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
              final h = baseH * (0.55 + 0.45 * math.sin(t + i * math.pi / 4));
              return Padding(
                padding: EdgeInsets.only(right: i < barCount - 1 ? 3 : 0),
                child: Container(
                  width: 6,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [_PlayerColors.goldLight, _PlayerColors.gold, _PlayerColors.sleepPurple, _PlayerColors.sleepBlue],
                            stops: [0.0, 0.35, 0.7, 1.0],
                          )
                        : null,
                    color: isPlayed ? null : Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: _PlayerColors.sleepPurple.withValues(alpha: 0.3),
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
      // Normal mode: water-flow animation so bar heights change over time; progress = first [visible] bars gold
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
              final mult = (0.55 + 0.45 * math.sin(t + i * math.pi / 4)).clamp(0.2, 1.0);
              final h = baseH * mult;
              return Padding(
                padding: EdgeInsets.only(right: i < barCount - 1 ? 3 : 0),
                child: Container(
                  width: 6,
                  height: h,
                  decoration: BoxDecoration(
                    gradient: isPlayed
                        ? const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [_PlayerColors.goldLight, _PlayerColors.gold, _PlayerColors.goldDark],
                            stops: [0.0, 0.5, 1.0],
                          )
                        : null,
                    color: isPlayed ? null : _PlayerColors.stone,
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isPlayed
                        ? [
                            BoxShadow(
                              color: _PlayerColors.gold.withValues(alpha: 0.3),
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
    // Fixed height so progress bar and controls below do not shift when bar heights animate
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

  /// Progress section per HTML: time row above 4px bar (design third screen-wrap)
  Widget _buildProgressSection() {
    final durMs = _duration.inMilliseconds;
    final posMs = _position.inMilliseconds;
    final progress = durMs > 0 ? (posMs / durMs).clamp(0.0, 1.0) : 0.0;
    final textColor = _sleepModeActive ? Colors.white.withValues(alpha: 0.6) : _PlayerColors.inkSoft;
    final trackColor = _sleepModeActive ? Colors.white.withValues(alpha: 0.2) : _PlayerColors.stone;

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
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  _formatDuration(_duration.inSeconds),
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    fontFeatures: const [FontFeature.tabularFigures()],
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
                        final rel = (d.localPosition.dx / barWidth).clamp(0.0, 1.0);
                        _audioPlayer.seek(Duration(milliseconds: (rel * durMs).round()));
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
                                  colors: [_PlayerColors.goldLight, _PlayerColors.gold, _PlayerColors.sleepPurple],
                                  stops: [0.0, 0.5, 1.0],
                                )
                              : null,
                          color: _sleepModeActive ? null : _PlayerColors.gold,
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
    final primarySize = isNarrow ? 52.0 : (isCompact ? 58.0 : 64.0);
    final secondarySize = isNarrow ? 38.0 : (isCompact ? 42.0 : 48.0);
    final spacing = isNarrow ? 8.0 : (isCompact ? 14.0 : 20.0);
    final sleepSpacing = isNarrow ? 20.0 : 32.0;

    final row = _sleepModeActive
        ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlBtn(_iconPrev, false, hasUrl ? _skipBackward : null, size: secondarySize),
              SizedBox(width: sleepSpacing),
              _controlBtn(_isPlaying ? _iconPause : _iconPlay, true, hasUrl ? _togglePlayPause : null, size: primarySize),
              SizedBox(width: sleepSpacing),
              _controlBtn(_iconNext, false, hasUrl ? _skipForward : null, size: secondarySize),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _controlBtn(_iconPrev, false, hasUrl ? _skipBackward : null, size: secondarySize),
              SizedBox(width: spacing),
              _controlBtn(_iconRewind, false, hasUrl ? _skipBackward : null, size: secondarySize),
              SizedBox(width: spacing),
              _controlBtn(_isPlaying ? _iconPause : _iconPlay, true, hasUrl ? _togglePlayPause : null, size: primarySize),
              SizedBox(width: spacing),
              _controlBtn(_iconForward, false, hasUrl ? _skipForward : null, size: secondarySize),
              SizedBox(width: spacing),
              _controlBtn(_iconNext, false, hasUrl ? _skipForward : null, size: secondarySize),
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

  Widget _controlBtn(String symbol, bool primary, VoidCallback? onTap, {double? size}) {
    final btnSize = size ?? (primary ? 64.0 : 48.0);
    final fontSize = primary ? (btnSize * 0.4).clamp(18.0, 26.0) : (btnSize * 0.375).clamp(14.0, 20.0);
    final primaryColor = _sleepModeActive ? _PlayerColors.sleepPurple : _PlayerColors.gold;
    final secondaryColor = _sleepModeActive ? Colors.white.withValues(alpha: 0.5) : _PlayerColors.inkMid;
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(btnSize / 2),
      splashColor: (primary ? Colors.white : primaryColor).withValues(alpha: 0.2),
      highlightColor: (primary ? Colors.white : primaryColor).withValues(alpha: 0.1),
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

  // Widget _buildModeButtons() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 24),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         _modeBtn('Standard', true),
  //         const SizedBox(width: 8),
  //         _modeBtn('Sleep', false),
  //         const SizedBox(width: 8),
  //         _modeBtn('Loop', false),
  //       ],
  //     ),
  //   );
  // }

  Widget _modeBtn(String label, bool active) {
    return Pressable(
      onTap: () {
        // TODO: switch mode (Standard/Sleep/Loop)
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? _PlayerColors.goldPale : _PlayerColors.surface,
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
