import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/onboarding_service.dart';
import 'onboarding_desire_widget.dart';
import 'onboarding_voice_selection_widget.dart';
import 'onboarding_state.dart';

/// Formats seconds as "X min Y sec" (readable) or "0:00" (short).
String _formatDurationReadable(int seconds) {
  if (seconds <= 0) return '0 min 0 sec';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m == 0) return '$s sec';
  if (s == 0) return '$m min';
  return '$m min $s sec';
}

/// Builds waveform bars; [visibleCount] grows with playback progress (0..totalBars).
/// Matches home_dashboard: tight spacing (margin 0.5), bars fill available width.
Widget _buildProgressWaveform(int visibleCount, int totalBars) {
  const heights = [8.0, 20.0, 32.0, 16.0, 36.0, 12.0, 28.0, 24.0, 14.0, 30.0];
  return Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: List.generate(totalBars, (i) {
      final isPlayed = i < visibleCount;
      final h = heights[i % heights.length];
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 0.5),
          child: Container(
            width: double.infinity,
            height: h.clamp(6.0, 36.0),
            decoration: BoxDecoration(
              color: isPlayed ? AuthTheme.gold : AuthTheme.stone,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
        ),
      );
    }),
  );
}

Widget _playerControl({
  required IconData icon,
  required double size,
  VoidCallback? onTap,
}) {
  final child = Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: AuthTheme.offWhite,
      shape: BoxShape.circle,
    ),
    child: Icon(icon, size: 14, color: AuthTheme.ink),
  );
  if (onTap != null) {
    return GestureDetector(onTap: onTap, child: child);
  }
  return child;
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

const int _totalWaveBars = 56;

class OnboardingPlayerWidget extends StatefulWidget {
  const OnboardingPlayerWidget({super.key});

  static String routeName = 'OnboardingPlayer';
  static String routePath = '/onboarding/player';

  @override
  State<OnboardingPlayerWidget> createState() => _OnboardingPlayerWidgetState();
}

class _OnboardingPlayerWidgetState extends State<OnboardingPlayerWidget> {
  int get _visibleWaveBars {
    final dur = _duration.inMilliseconds;
    if (dur <= 0) return 0;
    final pos = _position.inMilliseconds;
    final ratio = (pos / dur).clamp(0.0, 1.0);
    return (ratio * _totalWaveBars).round().clamp(0, _totalWaveBars);
  }
  late OnboardingState _state;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  /// User must play the voice at least this many times before Continue is allowed.
  static const int _minPlayCount = 1;
  int _playCount = 0;

  String? get _playUrl => _state.voicePlayUrl;

  String get _voiceSubtitle {
    final name = (_state.selectedVoiceName ?? '').trim();
    if (name.isEmpty || name == 'My Voice') return 'In your voice';
    return "${name}'s voice";
  }

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) setState(() {
        _isPlaying = false;
        _position = Duration.zero;
      });
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _audioPlayer.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
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
        if (mounted) setState(() => _isPlaying = false);
      } else {
        // resume() only works when paused mid-track; it won't restart after completion.
        // Use play() when: first load, at start (position 0), or at end — otherwise resume().
        final atStart = _position == Duration.zero;
        final atEnd = _duration > Duration.zero && _position >= _duration;
        if (atStart || atEnd) {
          await _audioPlayer.play(
            UrlSource(url),
            mode: PlayerMode.mediaPlayer,
          );
          if (mounted) setState(() {
            _isPlaying = true;
            _playCount++;
          });
        } else {
          await _audioPlayer.resume();
          if (mounted) setState(() => _isPlaying = true);
        }
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

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted();
    _state.clear();
    if (mounted) context.go('/');
  }

  Widget _buildStoryPreview() {
    final story = (_state.generatedStory?['story']?.toString() ?? '').trim();
    if (story.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        border: Border.all(color: AuthTheme.stone),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'STORY PREVIEW',
            style: GoogleFonts.outfit(
              fontSize: 10,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
              color: AuthTheme.gold,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: Text(
                story,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: AuthTheme.inkSoft,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  color: AuthTheme.gold,
                  onPressed: () => context.go(OnboardingVoiceSelectionWidget.routePath),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _state.generatedStory?['title']?.toString() ?? 'A Love That Was\nAlready Yours',
                      style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _duration.inSeconds > 0
                          ? '${_formatDurationReadable(_duration.inSeconds)} · ${_voiceSubtitle}'
                          : _voiceSubtitle,
                      style: AuthTheme.welcomeSubStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => context.go(OnboardingVoiceSelectionWidget.routePath),
                      child: Text(
                        'Change Voice',
                        style: AuthTheme.welcomeSubStyle.copyWith(
                          color: AuthTheme.gold,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: AuthTheme.gold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AuthTheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AuthTheme.stone),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: 36,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _buildProgressWaveform(
                                    _visibleWaveBars,
                                    _totalWaveBars,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(_position.inSeconds),
                                style: GoogleFonts.outfit(fontSize: 11, color: AuthTheme.inkSoft),
                              ),
                              Text(
                                _formatDuration(_duration.inSeconds),
                                style: GoogleFonts.outfit(fontSize: 11, color: AuthTheme.inkSoft),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _playerControl(
                                icon: Icons.skip_previous,
                                size: 36,
                                onTap: _duration.inSeconds > 0 ? _skipBackward : null,
                              ),
                              const SizedBox(width: 16),
                              GestureDetector(
                                onTap: _playUrl != null && _playUrl!.isNotEmpty
                                    ? _togglePlayPause
                                    : null,
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: AuthTheme.gold,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AuthTheme.ink.withValues(alpha: 0.08),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    size: 28,
                                    color: AuthTheme.surface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              _playerControl(
                                icon: Icons.skip_next,
                                size: 36,
                                onTap: _duration.inSeconds > 0 ? _skipForward : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_state.generatedStory?['story'] != null &&
                        (_state.generatedStory!['story'] as String).trim().isNotEmpty) ...[
                      _buildStoryPreview(),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_playCount < _minPlayCount)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Play the story at least $_minPlayCount time${_minPlayCount == 1 ? '' : 's'} to continue',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AuthTheme.inkSoft,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: _playCount >= _minPlayCount
                          ? AuthTheme.gold
                          : AuthTheme.stone,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        onTap: _playCount >= _minPlayCount
                            ? _completeOnboarding
                            : () {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please play the story at least $_minPlayCount time${_minPlayCount == 1 ? '' : 's'} before continuing.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            'Continue',
                            style: AuthTheme.primaryButtonStyle.copyWith(
                              color: _playCount >= _minPlayCount
                                  ? null
                                  : AuthTheme.inkSoft,
                            ),
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
      ),
    );
  }
}
