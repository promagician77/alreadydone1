import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/voice_recording_service.dart';
import '/services/app_toast.dart';
import 'onboarding_state.dart';
import 'onboarding_desire_widget.dart';
import 'onboarding_voice_complete_widget.dart';
import 'recording_circle.dart';

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
    if (mounted) {
      setState(() {
        _isRecording = false;
        _isComplete = true;
        _recordedFile = file;
      });
    }
  }

  Future<void> _uploadAndContinue() async {
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
      await BackendClient.uploadVoiceClone(
        userId: userId,
        name: name,
        audioFile: file,
        gender: null,
      );
      try { await file.delete(); } catch (_) {}
      OnboardingState.instance.recordingDurationSec = _recordingDurationSeconds;
      if (!mounted) return;
      setState(() => _isUploading = false);
      context.go(OnboardingVoiceCompleteWidget.routePath);
    } catch (e) {
      try { await file.delete(); } catch (_) {}
      if (mounted) {
        setState(() => _isUploading = false);
        AppToast.error(
          context,
          e.toString().replaceFirst('Exception: ', ''),
        );
      }
    }
  }

  void _reRecord() {
    if (_recordedFile != null) {
      try { _recordedFile!.delete(); } catch (_) {}
      _recordedFile = null;
    }
    setState(() {
      _isComplete = false;
      _elapsedSeconds = 0;
    });
  }

  String get _passageText {
    final story = _state.generatedStory?['story']?.toString()?.trim() ?? '';
    return story.isEmpty ? _defaultPassage : story;
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
                  padding: EdgeInsets.only(left: isNarrow ? 4 : 8, top: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                      color: AuthTheme.gold,
                      onPressed: (_isRecording || _isUploading)
                          ? null
                          : () => context.go(OnboardingDesireWidget.routePath),
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
                              _buildReadingPassage(isNarrow),
                              if (_isComplete) ...[
                                _buildSuccessBanner(isNarrow),
                                _buildWhatHappensNext(isNarrow),
                                _buildActionButtons(isNarrow),
                                _buildCreateVoiceCloneButton(isNarrow),
                              ] else if (!_isRecording) ...[
                                _buildInstructions(isNarrow),
                                SizedBox(height: isNarrow ? 12 : 16),
                                _buildStartRecordingButton(isNarrow),
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
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
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
          ? '0:30'
          : (isRecording ? _formatDuration(_elapsedSeconds) : '0:00'),
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

  Widget _buildReadingPassage(bool isNarrow) {
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
            _passageText,
            style: GoogleFonts.cormorantGaramond(
              fontSize: isNarrow ? 16 : 18,
              fontWeight: FontWeight.w400,
              color: AuthTheme.ink,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
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
      margin: const EdgeInsets.only(top: 8, bottom: 16),
      decoration: BoxDecoration(
        color: _successBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _successBorder),
      ),
      child: Text(
        '🎉 Perfect! 30 seconds recorded',
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
            "We'll create your voice clone and generate your first manifestation story. This takes about 30-45 seconds.",
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
            onPressed: () {
              // TODO: play recording when playback is implemented
            },
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
                    'Create Voice Clone',
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
