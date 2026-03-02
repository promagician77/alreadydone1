import 'dart:async';
import 'dart:math' as math;
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/voice_service.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'player_model.dart';
export 'player_model.dart';

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({
    super.key,
    this.categoryLabel,
    this.title,
    this.subtitle,
    this.durationLabel,
    this.storyId,
    this.audioUrl,
  });

  final String? categoryLabel;
  final String? title;
  final String? subtitle;
  final String? durationLabel;
  final int? storyId;
  final String? audioUrl;

  static String routeName = 'Player';
  static String routePath = '/player';

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  late PlayerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<double> _staticWaveHeights = [
    10, 20, 30, 16, 36, 24, 32, 12, 40, 22, 28, 38, 14, 24, 34,
  ];
  static const int _maxWaveBars = 32;
  static const int _barWidth = 5;
  static const double _barGap = 2.0;

  bool _isWavePlaying = false;
  List<double> _waveBars = List.from(_staticWaveHeights);
  Timer? _waveTimer;
  final math.Random _random = math.Random();

  late AudioPlayer _audioPlayer;
  String? _currentAudioUrl;
  bool _isLoadingAudio = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

<<<<<<< Updated upstream
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
=======
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
>>>>>>> Stashed changes

  String _formatDurationFull(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _togglePlayPause() async {
    final url = widget.audioUrl ?? _currentAudioUrl;
    if (url != null) {
      if (_isWavePlaying) {
        await _audioPlayer.pause();
        _stopWaveStream();
      } else {
        await _audioPlayer.play(UrlSource(url, mimeType: 'audio/mpeg'));
        _startWaveStream();
      }
      return;
    }
    if (widget.storyId == null) return;
    if (_isLoadingAudio) return;
    setState(() => _isLoadingAudio = true);
    try {
      final newUrl = await VoiceService.speak(storyId: widget.storyId!);
      if (!mounted) return;
      setState(() {
        _isLoadingAudio = false;
        _currentAudioUrl = newUrl;
      });
      if (newUrl != null) {
        await _audioPlayer.play(UrlSource(newUrl, mimeType: 'audio/mpeg'));
        _startWaveStream();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate audio')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load voice: $e')),
      );
    }
  }

  void _startWaveStream() {
    _waveTimer?.cancel();
    setState(() {
      _isWavePlaying = true;
      _waveBars = List.from(_staticWaveHeights);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted || !_isWavePlaying) return;
      setState(() {
        final h = 8.0 + _random.nextDouble() * 32.0;
        _waveBars.add(h.clamp(8.0, 40.0));
        if (_waveBars.length > _maxWaveBars) {
          _waveBars.removeAt(0);
        }
      });
    });
  }

  void _stopWaveStream() {
    _waveTimer?.cancel();
    _waveTimer = null;
    setState(() {
      _isWavePlaying = false;
      _waveBars = List.from(_staticWaveHeights);
    });
  }

  List<Widget> _buildWaveBars() {
    return [
      for (int i = 0; i < _waveBars.length; i++) ...[
        if (i > 0) SizedBox(width: _barGap),
        Container(
          width: _barWidth.toDouble(),
          height: _waveBars[i].clamp(8.0, 54.0),
          decoration: BoxDecoration(
            color: Color(
              i % 2 == 0 ? 0xFF1C1917 : 0xFFE8E2DA,
            ),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildFullWidthWaveBars(double availableWidth) {
    final barCount = ((availableWidth + _barGap) / (_barWidth + _barGap))
        .floor()
        .clamp(1, 200);
    return [
      for (int i = 0; i < barCount; i++) ...[
        if (i > 0) SizedBox(width: _barGap),
        Container(
          width: _barWidth.toDouble(),
          height: _staticWaveHeights[i % _staticWaveHeights.length]
              .clamp(8.0, 54.0),
          decoration: BoxDecoration(
            color: Color(
              i % 2 == 0 ? 0xFF1C1917 : 0xFFE8E2DA,
            ),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ],
    ];
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlayerModel());
    _audioPlayer = AudioPlayer();
    _currentAudioUrl = widget.audioUrl;
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          _stopWaveStream();
          setState(() => _currentPosition = Duration.zero);
        }
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration);
    });
    if (widget.audioUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _audioPlayer.play(UrlSource(widget.audioUrl!, mimeType: 'audio/mpeg'));
        _startWaveStream();
      });
    }
  }

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
  @override
  void dispose() {
    _waveTimer?.cancel();
    _audioPlayer.dispose();
    _model.dispose();
    super.dispose();
  }

<<<<<<< Updated upstream
=======
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

>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              border: Border.all(
                color: Color(0xFFE9E5DF),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 14.0),
                        child: Text(
                          '← Back',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF6B6460),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ),
<<<<<<< Updated upstream
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
=======
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
>>>>>>> Stashed changes
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF5EDD8),
                              Color(0xFFFDF0EE),
                              Color(0xFFF9F7F4)
                            ],
                            stops: [0.0, 0.6, 1.0],
                            begin: AlignmentDirectional(0.87, 1.0),
                            end: AlignmentDirectional(-0.87, -1.0),
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Color(0x19C9972A),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 22.0, 0.0, 9.0),
                              child: Text(
                                widget.categoryLabel ?? '♡ Love · Today',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFFB8861E),
                                      fontSize: 9.0,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            Text(
                              widget.title ?? 'A Love That Was',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.cormorantGaramond(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF1C1917),
                                    fontSize: 22.0,
                                    letterSpacing: 1.3,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 7.0),
                              child: Text(
                                widget.subtitle ?? 'Always Yours',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.cormorantGaramond(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      color: Color(0xFFC9972A),
                                      fontSize: 22.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 22.0),
                              child: Text(
                                _totalDuration > Duration.zero
                                    ? _formatDurationFull(_totalDuration)
                                    : (widget.durationLabel ?? '00:00:00'),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmMono(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF9E9189),
                                      fontSize: 10.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 9.0),
                      child: Container(
                        width: double.infinity,
                        height: 54.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: Color(0x141C1917),
                          ),
                        ),
                        padding: EdgeInsetsDirectional.fromSTEB(
                            14.0, 0.0, 14.0, 0.0),
                        alignment: Alignment.center,
                        child: _isWavePlaying
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: _buildWaveBars(),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _buildFullWidthWaveBars(w),
                                  );
                                },
                              ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        height: 14.0,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmMono(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF9E9189),
                                    fontSize: 10.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmMono(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF9E9189),
                                    fontSize: 10.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '⏮',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '⏪',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 58.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFF1C1917),
                                borderRadius: BorderRadius.circular(29.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(29.0),
                                  onTap: _togglePlayPause,
                                  child: Center(
                                    child: _isLoadingAudio
                                        ? SizedBox(
                                            width: 18.0,
                                            height: 18.0,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                      _isWavePlaying ? '⏸' : '▶',
                                      style: TextStyle(
                                        fontSize: 24.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '⏩',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '↻',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 72.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF9F7F4),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0x151C1917),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 10.0, 0.0, 3.0),
                                    child: Text(
                                      '☀️',
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Standard',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3D3530),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 72.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFFBF4E6),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0x151C1917),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 10.0, 0.0, 3.0),
                                    child: Text(
                                      '🌙',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 15.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    'Sleep',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFFB8861E),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 72.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF9F7F4),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0x151C1917),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 10.0, 0.0, 3.0),
                                    child: Text(
                                      '🔁',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 15.0,
                                            letterSpacing: 0.0,
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                    ),
                                  ),
                                  Text(
                                    'Loop',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 14.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: Color(0x1A1C1917),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              13.0, 13.0, 0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 7.0),
                                  child: Text(
                                    'Story Preview',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF9E9189),
                                          fontSize: 9.0,
                                          letterSpacing: 2.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Text(
                                  '\"You wake beside someone who looks at you like you\'re the whole world. The morning light is warm, and Jordan, you feel it — this easy, certain love…\"',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.cormorantGaramond(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        color: Color(0xFF3D3530),
                                        letterSpacing: 0.0,
                                        fontWeight:
                                            FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                        fontStyle: FontStyle.italic,
                                        lineHeight: 1.72,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  6.0, 10.0, 6.0, 10.0),
                              child: Text(
                                '♡ Save',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3D3530),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  6.0, 10.0, 6.0, 10.0),
                              child: Text(
                                '↗ Share',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3D3530),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  6.0, 10.0, 6.0, 10.0),
                              child: Text(
                                '✦ New',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3D3530),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
<<<<<<< Updated upstream
              ),
=======
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
>>>>>>> Stashed changes
            ),
          ),
        ),
      ),
    );
  }
}
