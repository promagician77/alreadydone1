import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/ai_consent_service.dart';
import '/services/supabase_service.dart';
import 'onboarding_desire_widget.dart';
import 'onboarding_player_widget.dart';
import 'onboarding_splash_widget.dart';
import 'onboarding_voice_widget.dart';
import 'onboarding_state.dart';

Widget _progressBar(int activeSegments) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Row(
      children: List.generate(
        4,
        (i) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
            decoration: BoxDecoration(
              color: i < activeSegments ? AuthTheme.gold : AuthTheme.stone,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    ),
  );
}

class OnboardingVoiceSelectionWidget extends StatefulWidget {
  const OnboardingVoiceSelectionWidget({super.key});

  static String routeName = 'OnboardingVoiceSelection';
  static String routePath = '/onboarding/voice-selection';

  @override
  State<OnboardingVoiceSelectionWidget> createState() =>
      _OnboardingVoiceSelectionWidgetState();
}

class _OnboardingVoiceSelectionWidgetState
    extends State<OnboardingVoiceSelectionWidget> {
  String _selectedId = 'my_voice';
  bool _isLoading = false;

  static const _maleVoices = [
    ('Q1QcmfZPmFDVUWmzASdy', 'Matt', 'Warm & Soothing'),
    ('8yh4Wuya1OlwcUp0epGF', 'David', 'Confident & Powerful'), 
    ('tJHJUEHzOkMoPmJJ5jo2', 'Alex', 'Gentle & Peaceful'),
  ];

  static const _femaleVoices = [
    ('KGZeK6FsnWQdrkDHnDNA', 'Sarah', 'Warm & Nurturing'),
    ('NXqsj0QYxuanzBw3KwjB', 'Maya', 'Energetic & Inspiring'),
    ('VlQRLHkc5IdFj7o0atT1', 'Luna', 'Calm & Serene'),
  ];

  bool get _isMyVoiceSelected => _selectedId == 'my_voice';

  String get _selectedVoiceDisplayName {
    if (_selectedId == 'my_voice') return 'My Voice';
    for (final t in _maleVoices) {
      if (t.$1 == _selectedId) return t.$2;
    }
    for (final t in _femaleVoices) {
      if (t.$1 == _selectedId) return t.$2;
    }
    return 'My Voice';
  }

  /// Gate voice generation behind an active/trial subscription.
  /// If not subscribed, sends the user to the paywall and returns false.
  Future<bool> _ensureSubscribedForVoiceGeneration() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) {
      if (mounted) context.go('/login?welcomeBack=true');
      return false;
    }

    bool isSubscribed = false;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      final status = (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
          ?.toString()
          .toLowerCase()
          .trim();
      // Treat "trial" as subscribed; legacy "trialing" is no longer used.
      isSubscribed = status == 'active' || status == 'trial';
    } catch (_) {
      isSubscribed = false;
    }

    if (isSubscribed) return true;

    if (!mounted) return false;
    final returnTo = Uri.encodeComponent(OnboardingVoiceSelectionWidget.routePath);
    context.go('${OnboardingSplashWidget.routePath}?returnTo=$returnTo');
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = isNarrow ? 16.0 : 20.0;

    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                _progressBar(3),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxWidth = constraints.maxWidth - horizontalPadding * 2;
                  final contentMaxWidth =
                      maxWidth > 440 ? 440.0 : maxWidth.clamp(0.0, double.infinity);
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: contentMaxWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: isNarrow ? 16 : 24),
                          _buildPageHeader(isNarrow),
                          SizedBox(height: isNarrow ? 16 : 24),
                          _buildCustomVoiceCard(isNarrow),
                          _buildDivider(),
                          const SizedBox(height: 8),
                          _buildSectionTitle('Male Voices'),
                          const SizedBox(height: 8),
                          for (final v in _maleVoices)
                            _buildPresetVoiceTile(
                              id: v.$1,
                              name: v.$2,
                              description: v.$3,
                            ),
                          const SizedBox(height: 16),
                          _buildSectionTitle('Female Voices'),
                          const SizedBox(height: 8),
                          for (final v in _femaleVoices)
                            _buildPresetVoiceTile(
                              id: v.$1,
                              name: v.$2,
                              description: v.$3,
                            ),
                          SizedBox(height: isNarrow ? 20 : 24),
                          _buildContinueButton(isNarrow),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
              ],
            ),
          ),
          if (_isLoading)
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
                          'Updating your manifestation story using your selected voice. This can take 30-45 seconds.',
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

  Widget _buildPageHeader(bool isNarrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'VOICE SELECTION',
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            letterSpacing: 3,
            color: AuthTheme.inkSoft,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'Choose Your Voice',
          style: GoogleFonts.cormorantGaramond(
            fontSize: isNarrow ? 26 : 28,
            fontWeight: FontWeight.w400,
            color: AuthTheme.ink,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'Select how your manifestations will sound',
          style: AuthTheme.welcomeSubStyle.copyWith(
            fontSize: isNarrow ? 12 : 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Returns true if the user already has a recorded voice (voice_id set in profile).
  Future<bool> _hasRecordedVoice() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return false;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      final voiceId = (profile['voice_id'] ?? profile['voice_Id'])?.toString().trim();
      return voiceId != null && voiceId.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  void _onMyVoiceTapped() {
    setState(() => _selectedId = 'my_voice');
  }

  /// If the user has a cloned voice (`voice_id`), generate audio with it.
  /// Otherwise, go to the recording page to create the cloned voice first.
  Future<void> _handleContinueMyVoice() async {
    final hasConsent = await AIConsentService.ensureConsent(context);
    if (!hasConsent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to AI data sharing to continue.'),
          ),
        );
      }
      return;
    }

    // First, ensure the user has an active/trial subscription.
    // If not, they are redirected to the subscription paywall (same as other voices).
    if (!await _ensureSubscribedForVoiceGeneration()) return;

    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;

    String? voiceId;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      voiceId = (profile['voice_id'] ?? profile['voice_Id'])?.toString().trim();
    } catch (_) {}

    if (voiceId == null || voiceId.isEmpty) {
      // Subscribed but no cloned voice yet – go to the recording flow.
      if (mounted) context.go(OnboardingVoiceWidget.routePath);
      return;
    }

    setState(() => _isLoading = true);
    final story = OnboardingState.instance.generatedStory;
    final storyIdRaw = story?['id'];
    final storyId = storyIdRaw is int
        ? storyIdRaw
        : int.tryParse(storyIdRaw?.toString() ?? '');
    if (storyId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Story not found. Please go back and try again.')),
        );
      }
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final res = await BackendClient.voiceGenerateAudio(
        voiceId: voiceId,
        storyId: storyId,
      );
      final url = res['url']?.toString().trim();
      if (url == null || url.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not generate audio. Please try again.')),
          );
        }
        return;
      }
      OnboardingState.instance.voicePlayUrl = url;
      OnboardingState.instance.selectedVoiceName = 'My Voice';
      OnboardingState.instance.selectedVoiceId = voiceId;
      if (mounted) context.go(OnboardingPlayerWidget.routePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not generate audio: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildCustomVoiceCard(bool isNarrow) {
    final selected = _isMyVoiceSelected;
    return GestureDetector(
      onTap: _onMyVoiceTapped,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AuthTheme.gold : AuthTheme.goldLight,
            width: 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AuthTheme.ink.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRadioCircle(selected),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'My Voice',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AuthTheme.ink,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AuthTheme.gold,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'RECOMMENDED',
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your own cloned voice — the most powerful for manifestation',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AuthTheme.inkSoft,
                      height: 1.4,
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

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              color: AuthTheme.stone,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'OR CHOOSE A PRE-MADE VOICE',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: AuthTheme.inkSoft,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              height: 1,
              color: AuthTheme.stone,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
        color: AuthTheme.inkMid,
      ),
    );
  }

  Widget _buildPresetVoiceTile({
    required String id,
    required String name,
    required String description,
  }) {
    final selected = _selectedId == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedId = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AuthTheme.goldPale : AuthTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AuthTheme.gold : AuthTheme.stone,
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AuthTheme.ink.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            _buildRadioCircle(selected, small: true),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AuthTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => _playPresetVoicePreview(voiceId: id, voiceName: name),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AuthTheme.warmWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AuthTheme.stoneMid, width: 1.5),
                ),
                child: const Center(
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: AuthTheme.inkMid,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _playPresetVoicePreview({
    required String voiceId,
    required String voiceName,
  }) async {
    final hasConsent = await AIConsentService.ensureConsent(context);
    if (!hasConsent) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please agree to AI data sharing to preview voices.'),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: SizedBox(
          width: 48,
          height: 48,
          child: CircularProgressIndicator(color: AuthTheme.gold),
        ),
      ),
    );
    try {
      final result = await BackendClient.voicePreview(voiceId);
      if (!mounted) return;
      Navigator.of(context).pop(); // loading
      _showVoicePreviewModal(
        context: context,
        voiceName: voiceName,
        audioBytes: result.bytes,
        contentType: result.contentType,
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load preview: $e')),
        );
      }
    }
  }

  void _showVoicePreviewModal({
    required BuildContext context,
    required String voiceName,
    required Uint8List audioBytes,
    String? contentType,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _VoicePreviewModal(
        voiceName: voiceName,
        audioBytes: audioBytes,
        contentType: contentType,
        onClose: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  Widget _buildRadioCircle(bool selected, {bool small = false}) {
    final size = small ? 18.0 : 20.0;
    final innerSize = small ? 8.0 : 10.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AuthTheme.gold : AuthTheme.stoneMid,
          width: 2,
        ),
      ),
      child: AnimatedScale(
        scale: selected ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        child: Center(
          child: Container(
            width: innerSize,
            height: innerSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AuthTheme.gold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton(bool isNarrow) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AuthTheme.gold,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _isLoading ? null : () async {
            if (_isMyVoiceSelected) {
              await _handleContinueMyVoice();
              return;
            }

            final hasConsent = await AIConsentService.ensureConsent(context);
            if (!hasConsent) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please agree to AI data sharing to continue.'),
                  ),
                );
              }
              return;
            }

            if (!await _ensureSubscribedForVoiceGeneration()) return;

            setState(() => _isLoading = true);
            try {
              final story = OnboardingState.instance.generatedStory;
              final storyIdRaw = story?['id'];
              final storyId = storyIdRaw is int
                  ? storyIdRaw
                  : int.tryParse(storyIdRaw?.toString() ?? '');
              if (storyId == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Story not found. Please go back and try again.'),
                    ),
                  );
                }
                return;
              }

              final res = await BackendClient.voiceGenerateAudio(
                voiceId: _selectedId,
                storyId: storyId,
              );
              final url = res['url']?.toString();
              OnboardingState.instance.voicePlayUrl = url;
              OnboardingState.instance.selectedVoiceName = _selectedVoiceDisplayName;
              OnboardingState.instance.selectedVoiceId = _selectedId;

              if (mounted) {
                context.go(OnboardingPlayerWidget.routePath);
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not load voice: $e')),
                );
              }
            } finally {
              if (mounted) {
                setState(() => _isLoading = false);
              }
            }
          },
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isNarrow ? 14 : 16),
            alignment: Alignment.center,
            child: Text(
              'Continue',
              style: AuthTheme.primaryButtonStyle.copyWith(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

/// Modal that plays voice preview from bytes (from api/voice/preview).
class _VoicePreviewModal extends StatefulWidget {
  const _VoicePreviewModal({
    required this.voiceName,
    required this.audioBytes,
    this.contentType,
    required this.onClose,
  });

  final String voiceName;
  final Uint8List audioBytes;
  final String? contentType;
  final VoidCallback onClose;

  @override
  State<_VoicePreviewModal> createState() => _VoicePreviewModalState();
}

class _VoicePreviewModalState extends State<_VoicePreviewModal> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = true;
  String? _error;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isScrubbing = false;
  double _scrubValueSeconds = 0;

  String? get _mimeType {
    final c = widget.contentType;
    if (c == null || c.isEmpty) return null;
    final parts = c.split(';');
    return parts.first.trim();
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
          if (state == PlayerState.playing || state == PlayerState.completed) {
            _isLoading = false;
          }
        });
      }
    });
    _player.onDurationChanged.listen((d) {
      if (!mounted) return;
      setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (!mounted) return;
      if (_isScrubbing) return;
      setState(() => _position = p);
    });
    _player.onPlayerComplete.listen((_) {
      if (!mounted) return;
      setState(() {
        _isPlaying = false;
        _position = _duration;
      });
    });
    _play();
  }

  Future<void> _play() async {
    setState(() => _error = null);
    try {
      await _player.play(
        BytesSource(widget.audioBytes, mimeType: _mimeType),
        mode: PlayerMode.mediaPlayer,
      );
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Future<void> _togglePlayPause() async {
    if (_error != null) return;
    if (_isPlaying) {
      await _player.pause();
    } else {
      // If the preview already finished, restart from the beginning.
      final durMs = _duration.inMilliseconds;
      if (durMs > 0) {
        final posMs = _position.inMilliseconds;
        if (posMs >= durMs - 250) {
          await _player.seek(Duration.zero);
          if (mounted) setState(() => _position = Duration.zero);
        }
      }
      await _player.resume();
    }
  }

  Future<void> _seekToSeconds(double seconds) async {
    if (_error != null) return;
    final clamped = seconds.clamp(0, _duration.inMilliseconds / 1000.0);
    await _player.seek(Duration(milliseconds: (clamped * 1000).round()));
  }

  String _fmt(Duration d) {
    final totalSeconds = d.inSeconds;
    final m = (totalSeconds ~/ 60).toString().padLeft(1, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePosition = _isScrubbing
        ? Duration(milliseconds: (_scrubValueSeconds * 1000).round())
        : _position;
    final durationSeconds = (_duration.inMilliseconds / 1000.0);
    final sliderMax = durationSeconds.isFinite && durationSeconds > 0 ? durationSeconds : 1.0;
    final sliderValueSeconds = durationSeconds > 0
        ? (effectivePosition.inMilliseconds / 1000.0).clamp(0.0, sliderMax)
        : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.96, end: 1),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: AuthTheme.warmWhite,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
                            ),
                            border: Border.all(color: AuthTheme.goldLight, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              widget.voiceName.isNotEmpty
                                  ? widget.voiceName.characters.first.toUpperCase()
                                  : 'V',
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AuthTheme.ink,
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
                                widget.voiceName,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AuthTheme.ink,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _error != null
                                          ? Colors.red.shade600
                                          : (_isPlaying ? AuthTheme.gold : AuthTheme.inkSoft),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _error != null
                                        ? 'Preview unavailable'
                                        : _isLoading
                                            ? 'Loading preview…'
                                            : _isPlaying
                                                ? 'Playing'
                                                : 'Paused',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: AuthTheme.inkSoft,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed: widget.onClose,
                          icon: const Icon(Icons.close_rounded),
                          color: AuthTheme.inkMid,
                          splashRadius: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (_error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.red.withValues(alpha: 0.18)),
                        ),
                        child: Text(
                          _error!,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.red.shade700,
                            height: 1.35,
                          ),
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SliderTheme(
                            data: theme.sliderTheme.copyWith(
                              trackHeight: 4,
                              activeTrackColor: AuthTheme.gold,
                              inactiveTrackColor: AuthTheme.stone,
                              thumbColor: AuthTheme.gold,
                              overlayColor: AuthTheme.gold.withValues(alpha: 0.12),
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                            ),
                            child: Slider(
                              min: 0,
                              max: sliderMax,
                              value: sliderValueSeconds,
                              onChangeStart: (_) {
                                setState(() {
                                  _isScrubbing = true;
                                  _scrubValueSeconds = sliderValueSeconds;
                                });
                              },
                              onChanged: _duration.inMilliseconds <= 0
                                  ? null
                                  : (v) => setState(() => _scrubValueSeconds = v),
                              onChangeEnd: (v) async {
                                setState(() => _isScrubbing = false);
                                await _seekToSeconds(v);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _fmt(effectivePosition),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AuthTheme.inkSoft,
                                  ),
                                ),
                                Text(
                                  _fmt(_duration),
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AuthTheme.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: SizedBox(
                              width: 64,
                              height: 64,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (_isLoading)
                                    const SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 3,
                                        color: AuthTheme.gold,
                                      ),
                                    )
                                  else
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AuthTheme.gold,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AuthTheme.ink.withValues(alpha: 0.10),
                                            blurRadius: 14,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  IconButton(
                                    onPressed: _togglePlayPause,
                                    iconSize: 34,
                                    color: Colors.white,
                                    tooltip: _isPlaying ? 'Pause' : 'Play',
                                    icon: Icon(
                                      _isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Tap play to hear how your manifestations will sound.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: AuthTheme.inkSoft,
                              height: 1.35,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: widget.onClose,
                            style: TextButton.styleFrom(
                              foregroundColor: AuthTheme.inkMid,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: BorderSide(color: AuthTheme.stoneMid.withValues(alpha: 0.7)),
                              ),
                            ),
                            child: Text(
                              'Close',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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
      ),
    );
  }
}

// (Removed) _UseMyVoiceDialog: "My Voice" now continues directly based on `voice_id`.

