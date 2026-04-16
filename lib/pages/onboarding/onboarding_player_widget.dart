import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/pages/player/player_modals/player_modals.dart';
import '/services/backend_client.dart';
import '/services/ai_consent_service.dart';
import '/services/app_toast.dart';
import '/services/onboarding_service.dart';
import '/services/supabase_service.dart';
import '/widgets/pressable.dart';
import 'onboarding_desire_widget.dart';
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
              gradient: isPlayed
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AuthTheme.goldLight, AuthTheme.gold, AuthTheme.goldDark],
                      stops: [0.0, 0.55, 1.0],
                    )
                  : null,
              color: isPlayed ? null : AuthTheme.stone,
              borderRadius: BorderRadius.circular(3),
              boxShadow: isPlayed
                  ? [
                      BoxShadow(
                        color: AuthTheme.gold.withValues(alpha: 0.25),
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
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(size / 2),
      child: child,
    );
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

  Duration get _expectedDuration {
    final seconds = _parseDurationSeconds(
      _state.generatedStory?['play_length'] ?? _state.generatedStory?['duration'],
    );
    if (seconds == null || seconds <= 0) return Duration.zero;
    return Duration(seconds: seconds);
  }

  Duration get _effectiveDuration =>
      _expectedDuration > _duration ? _expectedDuration : _duration;

  int get _visibleWaveBars {
    final dur = _effectiveDuration.inMilliseconds;
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
  bool _isDeepening = false;

  String? get _playUrl => _state.voicePlayUrl;

  String get _voiceSubtitle {
    final name = (_state.selectedVoiceName ?? '').trim();
    if (name.isEmpty || name == 'My Voice') return 'In your voice';
    return "${name}'s voice";
  }

  /// Story title from generated story (theme/title/desire_name from create step).
  String get _storyTitle {
    final raw = (_state.generatedStory?['theme'] ??
            _state.generatedStory?['title'] ??
            _state.generatedStory?['desire_name'])
        ?.toString()
        .trim();
    return (raw != null && raw.isNotEmpty) ? raw : 'A Love That Was\nAlready Yours';
  }

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
    _audioPlayer.setPlayerMode(PlayerMode.mediaPlayer);
    // Mark that the user has generated their first story so relaunch routing works.
    OnboardingService.setFirstStoryGenerated();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
          _playCount++;
        });
      }
    });
    _audioPlayer.onDurationChanged.listen((d) {
      if (mounted) {
        setState(() {
          _duration = d > _expectedDuration ? d : _expectedDuration;
        });
      }
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
        AppToast.info(context, 'No audio available');
      }
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        final atStart = _position == Duration.zero;
        final effectiveDuration = _effectiveDuration;
        final atEnd =
            effectiveDuration > Duration.zero && _position >= effectiveDuration;
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
        AppToast.error(context, 'Playback failed: $e');
        setState(() => _isPlaying = false);
      }
    }
  }

  static const _skipSeconds = 10;

  Future<void> _skipBackward() async {
    final newPos = _position.inSeconds - _skipSeconds;
    final target = Duration(
      seconds: newPos.clamp(0, _effectiveDuration.inSeconds),
    );
    await _audioPlayer.seek(target);
  }

  Future<void> _skipForward() async {
    final newPos = _position.inSeconds + _skipSeconds;
    final target = Duration(
      seconds: newPos.clamp(0, _effectiveDuration.inSeconds),
    );
    await _audioPlayer.seek(target);
  }

  Future<void> _completeOnboarding() async {
    await OnboardingService.setOnboardingCompleted();
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _onDeepenTap() async {
    if (_isDeepening) return;
    if (!mounted) return;
    showDeepenConfirmModal(context, onContinue: _deepenManifestation);
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
    if (!mounted) return;
    // Stop any in-progress playback while generating deepened story/audio.
    final shouldAutoPlayNew = _isPlaying;
    try { await _audioPlayer.stop(); } catch (_) {}
    if (mounted) setState(() {
      _isPlaying = false;
      _position = Duration.zero;
      _isDeepening = true;
    });
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) {
      if (mounted) {
        setState(() => _isDeepening = false);
        AppToast.error(context, 'Could not deepen story: user not found.');
      }
      return;
    }
    final story = _state.generatedStory;
    final storyIdRaw = story?['id'];
    final storyId = storyIdRaw is int ? storyIdRaw : int.tryParse(storyIdRaw?.toString() ?? '');
    if (storyId == null) {
      if (mounted) {
        setState(() => _isDeepening = false);
        AppToast.info(context, 'No story selected to deepen.');
      }
      return;
    }
    if (!mounted) {
      setState(() => _isDeepening = false);
      return;
    }
    String name = '';
    String location = '';
    String energyWord = '';
    String lovedOne = '';
    String dreamLocation = '';
    String? profileVoiceId;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      name = (profile['name'] ?? '').toString().trim();
      location = (profile['location'] ?? profile['dream_place'] ?? '').toString().trim();
      energyWord = (profile['energyWord'] ?? '').toString().trim();
      lovedOne = (profile['lovedOne'] ?? profile['someone_you_love'] ?? '').toString().trim();
      dreamLocation = (profile['dream_place'] ?? profile['dreamLocation'] ?? '').toString().trim();
      profileVoiceId = (profile['voice_id'] ?? profile['voice_Id'])?.toString().trim();
    } catch (_) {}
    if (!mounted) {
      setState(() => _isDeepening = false);
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
      if (!mounted) return;
      final theme = (res['theme'] ?? res['title'] ?? 'Deepened Story').toString().trim();
      final storyText = (res['story'] ?? res['content'] ?? '').toString().trim();
      if (storyText.isEmpty) {
        AppToast.error(context, 'Deepen response had no story content.');
        return;
      }

      // Update player page immediately (title + preview + audio) so when modal shows,
      // the underlying page reflects the deepened story.
      final newStoryIdRaw = res['id'] ?? res['story_id'] ?? res['storyId'];
      final newStoryId = newStoryIdRaw is int
          ? newStoryIdRaw
          : int.tryParse(newStoryIdRaw?.toString() ?? '');
      int storyIdToUse = newStoryId ?? storyId;
      if (newStoryId == null) {
        // Some backends return the deepened story without its new id.
        // Best-effort: load latest story id from list.
        try {
          final storiesRes = await BackendClient.getStories(userId);
          final list = (storiesRes['stories'] as List<dynamic>?) ?? const [];
          int? bestId;
          for (final s in list) {
            final map = s is Map<String, dynamic> ? s : <String, dynamic>{};
            final idRaw = map['id'] ?? map['Id'];
            final sid = idRaw is int ? idRaw : int.tryParse(idRaw?.toString() ?? '');
            if (sid == null) continue;
            if (bestId == null || sid > bestId) bestId = sid;
          }
          if (bestId != null) storyIdToUse = bestId;
        } catch (_) {}
      }

      // Prefer the voice the user selected in onboarding; fall back to profile voice_id.
      final voiceIdToUse = (_state.selectedVoiceId ?? '').trim().isNotEmpty
          ? _state.selectedVoiceId!.trim()
          : ((profileVoiceId ?? '').trim().isNotEmpty ? profileVoiceId!.trim() : null);

      String? newAudioUrl;
      dynamic newPlayLength;
      if (voiceIdToUse != null && voiceIdToUse.isNotEmpty) {
        try {
          final audioRes = await BackendClient.voiceGenerateAudio(
            voiceId: voiceIdToUse,
            storyId: storyIdToUse,
          );
          final url = audioRes['url']?.toString().trim();
          if (url != null && url.isNotEmpty) newAudioUrl = url;
          newPlayLength = audioRes['play_length'];
        } catch (_) {
          // If audio generation fails, keep existing audio; user can still read the deepened story.
        }
      }

      if (!mounted) return;
      setState(() {
        _state.generatedStory ??= <String, dynamic>{};
        _state.generatedStory!['id'] = storyIdToUse;
        _state.generatedStory!['theme'] = theme;
        _state.generatedStory!['title'] = theme;
        _state.generatedStory!['story'] = storyText;
        if (newPlayLength != null) {
          _state.generatedStory!['play_length'] = newPlayLength;
        }
        if (newAudioUrl != null && newAudioUrl!.isNotEmpty) {
          _state.voicePlayUrl = newAudioUrl;
        }
      });

      if (newAudioUrl != null && newAudioUrl!.isNotEmpty) {
        try {
          await _audioPlayer.setSource(UrlSource(newAudioUrl!));
          if (shouldAutoPlayNew) await _audioPlayer.resume();
          if (mounted) setState(() => _isPlaying = shouldAutoPlayNew);
        } catch (_) {
          if (mounted) setState(() => _isPlaying = false);
        }
      }

      showDeepenResultModal(context, theme: theme, story: storyText);
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          'Could not deepen story: ${e.toString().replaceAll(RegExp(r'^Exception:?\s*'), '')}',
        );
      }
    } finally {
      if (mounted) setState(() => _isDeepening = false);
    }
  }

  Widget _buildDeepenButton() {
    final isDisabled = _isDeepening;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled ? null : _onDeepenTap,
          borderRadius: BorderRadius.circular(14),
          child: Opacity(
            opacity: isDisabled ? 0.7 : 1,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AuthTheme.gold.withValues(alpha: 0.15),
                    AuthTheme.surface,
                  ],
                ),
                border: Border.all(color: AuthTheme.gold.withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AuthTheme.ink.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('✨', style: GoogleFonts.outfit(fontSize: 14)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Deepen This Manifestation',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AuthTheme.goldDark,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('→', style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: AuthTheme.goldDark)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
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
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _storyTitle,
                      style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 24),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _effectiveDuration.inSeconds > 0
                          ? '${_formatDurationReadable(_effectiveDuration.inSeconds)} · ${_voiceSubtitle}'
                          : _voiceSubtitle,
                      style: AuthTheme.welcomeSubStyle,
                      textAlign: TextAlign.center,
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
                                _formatDuration(_effectiveDuration.inSeconds),
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
                                onTap: _effectiveDuration.inSeconds > 0 ? _skipBackward : null,
                              ),
                              const SizedBox(width: 16),
                              Pressable(
                                onTap: _playUrl != null && _playUrl!.isNotEmpty
                                    ? _togglePlayPause
                                    : null,
                                borderRadius: BorderRadius.circular(28),
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
                                onTap: _effectiveDuration.inSeconds > 0 ? _skipForward : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDeepenButton(),
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
                                  AppToast.info(
                                    context,
                                    'Please play the story at least $_minPlayCount time${_minPlayCount == 1 ? '' : 's'} before continuing.',
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
          if (_isDeepening)
            Positioned.fill(
              child: Container(
                color: AuthTheme.warmWhite.withValues(alpha: 0.85),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AuthTheme.gold),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Deepening your manifestation. This can take up to 60 ~ 90 seconds.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AuthTheme.ink,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
