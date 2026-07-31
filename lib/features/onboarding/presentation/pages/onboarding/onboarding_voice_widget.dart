import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
import '../../widgets/onboarding_guide_content.dart';
import '../../widgets/onboarding_guide_modal.dart';
import '/shared/theme/auth_theme.dart';
import '/core/network/backend_client.dart';
import '/core/di/profile_locator.dart';
import '/shared/services/supabase_service.dart';
import '/features/onboarding/data/datasources/voice_recording_service.dart';
import '/shared/services/app_toast.dart';
import '/shared/services/ai_consent_service.dart';
import '/shared/widgets/pressable.dart';
import '/shared/state/onboarding_state.dart';
import 'onboarding_player_widget.dart';
import 'onboarding_voice_selection_widget.dart';
import 'celebration_overlay.dart';
import '/shared/widgets/recording_circle.dart';

/// Design-spec passage when no story content.
const String _defaultPassage =
    "You woke up in your dream home, and everything you'd ever wanted was already here. Not as a wish, but as your reality, already complete.";

const int _recordingDurationSeconds = 30;

Widget _progressBar(int activeSegments) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: Row(
      children: List.generate(4, (i) => Expanded(
        child: Container(
          height: 3,
          margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
          decoration: BoxDecoration(
            color: i < activeSegments ? AuthTheme.gold : AuthTheme.stone,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      )),
    ),
  );
}

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

const int _listenWaveBars = 56;

/// Waveform bars for listen modal (matches onboarding player spacing).
Widget _buildListenWaveform(int visibleCount, int totalBars) {
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

Widget _listenPlayerControl({
  required IconData icon,
  required double size,
  VoidCallback? onTap,
}) {
  final child = Container(
    width: size,
    height: size,
    decoration: const BoxDecoration(
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

/// Success banner colors (from design).
const Color _successBg = Color(0xFFEEF4EE);
const Color _successText = Color(0xFF2F7C31);
const Color _successBorder = Color(0xFF7FA882);

class OnboardingVoiceWidget extends StatefulWidget {
  const OnboardingVoiceWidget({super.key});

  static String routeName = 'OnboardingVoice';
  static String routePath = '/onboarding/voice';

  @override
  State<OnboardingVoiceWidget> createState() => _OnboardingVoiceWidgetState();
}

class _OnboardingVoiceWidgetState extends State<OnboardingVoiceWidget>
    with SingleTickerProviderStateMixin {
  late OnboardingState _state;
  late VoiceRecordingService _recordingService;
  bool _isRecording = false;
  bool _isComplete = false;
  bool _isUploading = false;
  int _elapsedSeconds = 0;
  Timer? _timer;
  File? _recordedFile;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
    _recordingService = VoiceRecordingService();
    _recordingService.requestPermission().catchError((_) {});
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowGuideModal());
  }

  void _maybeShowGuideModal() {
    OnboardingGuideModal.maybeShow(context, OnboardingGuideContent.voiceRecord);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _recordingService.cancel();
    _recordingService.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      await _recordingService.start();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, e.toString().replaceFirst('Exception: ', ''));
      }
      return;
    }
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _isComplete = false;
      _recordedFile = null;
      _elapsedSeconds = 0;
    });
    _pulseController.repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final next = _elapsedSeconds + 1;
      setState(() => _elapsedSeconds = next);
      if (next >= _recordingDurationSeconds) {
        _timer?.cancel();
        _timer = null;
        _finishRecording();
      }
    });
  }

  Future<void> _finishRecording() async {
    _pulseController.stop();
    _pulseController.reset();
    _timer?.cancel();
    _timer = null;
    File? file;
    try {
      file = await _recordingService.stop();
    } catch (_) {
      if (mounted) AppToast.error(context, 'Failed to save recording.');
      setState(() => _isRecording = false);
      return;
    }
    if (file == null || !await file.exists()) {
      if (mounted) AppToast.error(context, 'No recording saved.');
      setState(() => _isRecording = false);
      return;
    }
    _state.recordedVoiceFilePath = file.path;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isComplete = true;
        _recordedFile = file;
      });
    }
  }

  Future<void> _uploadAndContinue() async {
    final hasConsent = await AIConsentService.ensureConsent(context);
    if (!hasConsent) {
      if (mounted) {
        AppToast.info(
          context,
          'You need to agree to AI data sharing to create your voice clone.',
        );
      }
      return;
    }

    final file = _recordedFile;
    if (file == null || !await file.exists()) {
      AppToast.error(context, 'No recording to upload.');
      return;
    }
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) {
      AppToast.error(context, 'Please sign in to upload your voice.');
      return;
    }

    final name = _state.firstNameController.text.trim().isNotEmpty
        ? _state.firstNameController.text.trim()
        : 'My Voice';

    setState(() => _isUploading = true);
    try {
      final uploadResult = await BackendClient.uploadVoiceClone(
        userId: userId,
        name: name,
        audioFile: file,
        gender: null,
      );
      try { await file.delete(); } catch (_) {}
      _state.recordedVoiceFilePath = null;
      OnboardingState.instance.recordingDurationSec = _recordingDurationSeconds;

      var voiceId = uploadResult['voice_id']?.toString().trim() ??
          uploadResult['voiceId']?.toString().trim() ??
          '';
      if (voiceId.isEmpty) {
        voiceId = (await _waitForVoiceId(userId)) ?? '';
      }
      final storyId = _getGeneratedStoryId();
      if (voiceId.isEmpty) {
        if (mounted) {
          AppToast.info(
            context,
            'Your voice is still processing. Please wait a bit and tap "Create Voice Clone" again.',
          );
          setState(() => _isUploading = false);
        }
        return;
      }
      if (storyId == null) {
        if (mounted) {
          AppToast.error(context, 'Story not found. Please go back and try again.');
          setState(() => _isUploading = false);
        }
        return;
      }

      final res = await BackendClient.voiceGenerateAudioAwaitReady(
        voiceId: voiceId,
        storyId: storyId,
      );
      final url = res['url']?.toString().trim();
      if (url == null || url.isEmpty) {
        if (mounted) {
          AppToast.error(context, 'Could not generate audio. Please try again.');
          setState(() => _isUploading = false);
        }
        return;
      }
      OnboardingState.instance.voicePlayUrl = url;
      if (res['play_length'] != null) {
        OnboardingState.instance.generatedStory ??= <String, dynamic>{};
        OnboardingState.instance.generatedStory!['play_length'] = res['play_length'];
      }
      OnboardingState.instance.selectedVoiceName = name;
      OnboardingState.instance.selectedVoiceId = voiceId;

      if (!mounted) return;
      setState(() => _isUploading = false);
      showCelebrationOverlay(
        context,
        message: 'Perfect! Your voice is cloned.',
        onComplete: () => context.go(OnboardingPlayerWidget.routePath),
        duration: const Duration(milliseconds: 2500),
      );
    } catch (e) {
      try { await file.delete(); } catch (_) {}
      _state.recordedVoiceFilePath = null;
      if (mounted) {
        setState(() => _isUploading = false);
        AppToast.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  int? _getGeneratedStoryId() {
    final story = OnboardingState.instance.generatedStory;
    final storyIdRaw = story?['id'];
    if (storyIdRaw is int) return storyIdRaw;
    return int.tryParse(storyIdRaw?.toString() ?? '');
  }

  Future<String?> _waitForVoiceId(int userId) async {
    // Fallback when clone response omitted voice_id; poll profile up to ~60s.
    const attempts = 30;
    const delay = Duration(seconds: 2);
    for (int i = 0; i < attempts; i++) {
      try {
        final profile = await profileRepository.getUserProfile(userId);
        final voiceId = profile['voice_id']?.toString().trim() ??
            profile['voice_Id']?.toString().trim() ??
            '';
        if (voiceId.isNotEmpty) return voiceId;
      } catch (_) {
        // ignore transient failures and retry
      }
      await Future<void>.delayed(delay);
    }
    return null;
  }

  void _reRecord() {
    if (_recordedFile != null) {
      try { _recordedFile!.delete(); } catch (_) {}
      _recordedFile = null;
    }
    _state.recordedVoiceFilePath = null;
    setState(() {
      _isComplete = false;
      _elapsedSeconds = 0;
    });
  }

  /// Story title for listen modal (aligned with [OnboardingPlayerWidget]).
  String get _modalStoryTitle {
    final raw = (_state.generatedStory?['theme'] ??
            _state.generatedStory?['title'] ??
            _state.generatedStory?['desire_name'])
        ?.toString()
        .trim();
    return (raw != null && raw.isNotEmpty) ? raw : 'A Love That Was\nAlready Yours';
  }

  String _modalListenSubtitle(bool hasGeneratedUrl) {
    if (hasGeneratedUrl) {
      final name = (_state.selectedVoiceName ?? '').trim();
      if (name.isEmpty || name == 'My Voice') return 'In your voice';
      return "${name}'s voice";
    }
    final first = _state.firstNameController.text.trim();
    if (first.isNotEmpty) return '$first · your recording';
    return 'Your recording';
  }

  void _openListenModal() {
    final url = _state.voicePlayUrl?.trim();
    final hasUrl = url != null && url.isNotEmpty;
    final file = _recordedFile;
    if (!hasUrl && (file == null || !file.existsSync())) {
      AppToast.error(context, 'No audio to play.');
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceListenSheet(
        title: _modalStoryTitle,
        subtitle: _modalListenSubtitle(hasUrl),
        localFile: hasUrl ? null : file,
        remoteUrl: hasUrl ? url : null,
      ),
    );
  }

  String get _passageText {
    final story = _state.generatedStory?['story']?.toString()?.trim() ?? '';
    return story.isEmpty ? _defaultPassage : story;
  }

  /// Truncates [text] so the preview ends on a complete word (no "he..." or "stre...").
  /// Uses [maxLength] as a soft cap, then cuts at the last space to leave only complete words.
  static String _truncateToCompleteWords(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    final truncated = text.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');
    if (lastSpace < 0) return ''; // no space: cannot end on a word boundary, show nothing
    if (lastSpace == 0) return '';
    return truncated.substring(0, lastSpace).trim();
  }

  /// Truncates [text] so the preview ends on a complete sentence when possible.
  /// Falls back to [_truncateToCompleteWords] if no sentence boundary is found.
  static String _truncateToCompleteSentence(String text, int maxLength) {
    if (text.length <= maxLength) return text.trim();
    final truncated = text.substring(0, maxLength);
    final lastPeriod = truncated.lastIndexOf('.');
    final lastBang = truncated.lastIndexOf('!');
    final lastQuestion = truncated.lastIndexOf('?');
    final lastEnd = [lastPeriod, lastBang, lastQuestion].reduce((a, b) => a > b ? a : b);
    if (lastEnd > 0) {
      return truncated.substring(0, lastEnd + 1).trim();
    }
    return _truncateToCompleteWords(text, maxLength);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = isNarrow ? 16.0 : 20.0;
    final progress = (_elapsedSeconds / _recordingDurationSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                      color: AuthTheme.gold,
                      onPressed: _isUploading
                          ? null
                          : () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go(OnboardingVoiceSelectionWidget.routePath);
                              }
                            },
                    ),
                  ),
                ),
                _progressBar(3),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxW = constraints.maxWidth - horizontalPadding * 2;
                      final contentMaxWidth = maxW > 440 ? 440.0 : maxW;
                      return SingleChildScrollView(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: contentMaxWidth),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildHeader(isNarrow),
                              SizedBox(height: isNarrow ? 12 : 24),
                              _buildProgressCircle(progress, isNarrow),
                              SizedBox(height: _isRecording ? (isNarrow ? 8 : 12) : (isNarrow ? 16 : 20)),
                              if (_isComplete) ...[
                                _buildSuccessBanner(isNarrow),
                                _buildWhatHappensNext(isNarrow),
                                _buildActionButtons(isNarrow),
                                _buildCreateVoiceCloneButton(isNarrow),
                                SizedBox(height: isNarrow ? 16 : 24),
                                _buildReadingPassage(isNarrow),
                              ] else ...[
                                _buildReadingPassage(isNarrow),
                                if (!_isRecording) ...[
                                  _buildInstructions(isNarrow),
                                  SizedBox(height: isNarrow ? 12 : 16),
                                  _buildStartRecordingButton(isNarrow),
                                ],
                              ],
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
          if (_isUploading)
            Positioned.fill(
              child: Container(
                color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AuthTheme.gold),
                      const SizedBox(height: 16),
                      Text(
                        'Creating your voice clone...',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This can take 30–45 seconds.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28),
                        child: Text(
                          "Please keep the app open and don't lock your screen.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.35,
                          ),
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

  Widget _buildHeader(bool isNarrow) {
    String title;
    String? subtitle;
    if (_isComplete) {
      title = 'Great Recording!';
      subtitle = 'Your voice clone is ready to create';
    } else if (_isRecording) {
      title = 'Recording...';
      subtitle = null;
    } else {
      title = 'Clone Your Voice';
      subtitle = 'Record yourself reading the words below';
    }
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: _isRecording ? 8 : (isNarrow ? 12 : 20),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: AuthTheme.welcomeTitleStyle.copyWith(
              fontSize: isNarrow ? 24 : 28,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            SizedBox(height: isNarrow ? 4 : 8),
            Text(
              subtitle,
              style: AuthTheme.welcomeSubStyle.copyWith(
                fontSize: isNarrow ? 12 : 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCircle(double progress, bool isNarrow) {
    const double circleSize = 126;
    final isComplete = _isComplete;
    final isRecording = _isRecording;

    Widget circle = RecordingCircle(
      size: circleSize,
      progress: isComplete ? 1.0 : (isRecording ? progress : 0),
      timerText: isComplete
          ? _formatDuration(_recordingDurationSeconds)
          : (isRecording
              ? _formatDuration(_recordingDurationSeconds - _elapsedSeconds)
              : '0:30'),
      label: '',
      showCheckmark: isComplete,
    );

    if (isRecording) {
      circle = AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final spread = _pulseAnimation.value * 8;
          final opacity = 0.4 * (1 - _pulseAnimation.value);
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
              ),
              boxShadow: [
                BoxShadow(
                  color: AuthTheme.gold.withValues(alpha: opacity),
                  blurRadius: 16,
                  spreadRadius: spread,
                ),
              ],
            ),
            child: child,
          );
        },
        child: circle,
      );
    } else if (isComplete) {
      circle = SizedBox(
        width: circleSize,
        height: circleSize,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AuthTheme.goldPale, AuthTheme.warmWhite],
            ),
          ),
          child: circle,
        ),
      );
    }

    return Center(child: circle);
  }

  /// Approximate max characters that fit in ~8 lines in the passage card.
  static const int _passagePreviewMaxChars = 380;

  Widget _buildReadingPassage(bool isNarrow) {
    final fullText = _passageText;
    final preview = _truncateToCompleteSentence(fullText, _passagePreviewMaxChars);
    final displayText = preview;

    return Container(
      padding: EdgeInsets.all(isNarrow ? 16 : 24),
      margin: EdgeInsets.symmetric(
        vertical: _isRecording ? 8 : (isNarrow ? 12 : 20),
      ),
      decoration: BoxDecoration(
        color: AuthTheme.warmWhite,
        border: Border.all(color: AuthTheme.goldLight, width: 2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            'READ THIS ALOUD 3 TIMES',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AuthTheme.goldDark,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: isNarrow ? 12 : 16),
          Text(
            displayText,
            style: GoogleFonts.cormorantGaramond(
              fontSize: isNarrow ? 16 : 18,
              fontWeight: FontWeight.w400,
              color: AuthTheme.ink,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            maxLines: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBanner(bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 16,
        vertical: 12,
      ),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _successBorder),
      ),
      child: Text(
        "Perfect! 30 seconds recorded.\nClick the 'Create Clone Voice' button below to continue.",
        style: GoogleFonts.outfit(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: _successText,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWhatHappensNext(bool isNarrow) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        border: Border.all(color: AuthTheme.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '✨ What happens next?',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Click the ‘Create Clone Voice’ button below to generate your manifestation story with your cloned voice. Please note: this takes 30-45 seconds.",
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AuthTheme.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isNarrow) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _openListenModal,
            icon: const Text('🎧', style: TextStyle(fontSize: 16)),
            label: const Text('Listen'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AuthTheme.stone, width: 1.5),
              backgroundColor: AuthTheme.warmWhite,
              foregroundColor: AuthTheme.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isUploading ? null : _reRecord,
            icon: const Text('🔄', style: TextStyle(fontSize: 16)),
            label: const Text('Re-record'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AuthTheme.stone, width: 1.5),
              backgroundColor: AuthTheme.warmWhite,
              foregroundColor: AuthTheme.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateVoiceCloneButton(bool isNarrow) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: SizedBox(
        width: double.infinity,
        child: Material(
          color: AuthTheme.gold,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: _isUploading ? null : _uploadAndContinue,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isNarrow ? 14 : 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('✨', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    'Create Clone Voice',
                    style: AuthTheme.primaryButtonStyle.copyWith(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructions(bool isNarrow) {
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: AuthTheme.surface,
        border: Border.all(color: AuthTheme.stone),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '📱 Recording Instructions',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthTheme.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Click Start Recording\n'
            '• Read the passage aloud slowly and clearly 3 times\n'
            '• Recording auto-completes at 30 seconds\n'
            '• Watch the circle fill up as you read',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: AuthTheme.inkSoft,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartRecordingButton(bool isNarrow) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: AuthTheme.gold,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: _isUploading ? null : _startRecording,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: isNarrow ? 14 : 16),
            alignment: Alignment.center,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎙️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Text(
                  'Start Recording',
                  style: AuthTheme.primaryButtonStyle.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceListenSheet extends StatefulWidget {
  const _VoiceListenSheet({
    required this.title,
    required this.subtitle,
    this.localFile,
    this.remoteUrl,
  });

  final String title;
  final String subtitle;
  final File? localFile;
  final String? remoteUrl;

  @override
  State<_VoiceListenSheet> createState() => _VoiceListenSheetState();
}

class _VoiceListenSheetState extends State<_VoiceListenSheet> {
  static const _skipSeconds = 10;

  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  int get _visibleWaveBars {
    final dur = _duration.inMilliseconds;
    if (dur <= 0) return 0;
    final pos = _position.inMilliseconds;
    final ratio = (pos / dur).clamp(0.0, 1.0);
    return (ratio * _listenWaveBars).round().clamp(0, _listenWaveBars);
  }

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _position = Duration.zero;
        });
      }
    });
    _player.onDurationChanged.listen((d) {
      if (mounted) setState(() => _duration = d);
    });
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _position = p);
    });
    _loadSource();
  }

  Future<void> _loadSource() async {
    try {
      if (widget.remoteUrl != null && widget.remoteUrl!.isNotEmpty) {
        await _player.setSource(UrlSource(widget.remoteUrl!));
      } else if (widget.localFile != null && await widget.localFile!.exists()) {
        await _player.setSource(DeviceFileSource(widget.localFile!.path));
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Could not load audio.');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
        if (mounted) setState(() => _isPlaying = false);
      } else {
        final atStart = _position <= const Duration(milliseconds: 150);
        final atEnd = _duration > Duration.zero &&
            _position >= _duration - const Duration(milliseconds: 300);
        if (atStart || atEnd) {
          if (widget.remoteUrl != null && widget.remoteUrl!.isNotEmpty) {
            await _player.play(
              UrlSource(widget.remoteUrl!),
              mode: PlayerMode.mediaPlayer,
            );
          } else if (widget.localFile != null) {
            await _player.play(DeviceFileSource(widget.localFile!.path));
          }
          if (mounted) setState(() => _isPlaying = true);
        } else {
          await _player.resume();
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

  Future<void> _skipBackward() async {
    final newPos = _position.inSeconds - _skipSeconds;
    final target = Duration(seconds: newPos.clamp(0, _duration.inSeconds));
    await _player.seek(target);
  }

  Future<void> _skipForward() async {
    final newPos = _position.inSeconds + _skipSeconds;
    final target = Duration(seconds: newPos.clamp(0, _duration.inSeconds));
    await _player.seek(target);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Material(
          color: AuthTheme.warmWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AuthTheme.stone,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 22),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: AuthTheme.welcomeSubStyle.copyWith(fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
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
                        child: _buildListenWaveform(_visibleWaveBars, _listenWaveBars),
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
                          _listenPlayerControl(
                            icon: Icons.skip_previous,
                            size: 36,
                            onTap: _duration.inSeconds > 0 ? _skipBackward : null,
                          ),
                          const SizedBox(width: 16),
                          Pressable(
                            onTap: _togglePlayPause,
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
                          _listenPlayerControl(
                            icon: Icons.skip_next,
                            size: 36,
                            onTap: _duration.inSeconds > 0 ? _skipForward : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Close',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: AuthTheme.inkSoft,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
