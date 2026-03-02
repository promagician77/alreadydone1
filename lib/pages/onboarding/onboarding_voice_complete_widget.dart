import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import 'onboarding_state.dart';
import 'onboarding_voice_widget.dart';
import 'onboarding_player_widget.dart';
import 'recording_circle.dart';
import 'celebration_overlay.dart';

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

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class OnboardingVoiceCompleteWidget extends StatefulWidget {
  const OnboardingVoiceCompleteWidget({super.key});

  static String routeName = 'OnboardingVoiceComplete';
  static String routePath = '/onboarding/complete';

  @override
  State<OnboardingVoiceCompleteWidget> createState() =>
      _OnboardingVoiceCompleteWidgetState();
}

class _OnboardingVoiceCompleteWidgetState
    extends State<OnboardingVoiceCompleteWidget> {
  bool _isLoading = false;

  Future<void> _onContinue() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final userId = await SupabaseService.getCurrentUserTableId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in to continue')),
          );
        }
        return;
      }

      final profile = await BackendClient.getUserProfile(userId);
      final voiceId = profile['voice_id']?.toString() ??
          profile['voice_Id']?.toString() ??
          '';
      if (voiceId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Voice not yet available. Please wait.')),
          );
        }
        return;
      }

      final story = OnboardingState.instance.generatedStory;
      final storyIdRaw = story?['id'];
      final storyId = storyIdRaw is int
          ? storyIdRaw
          : int.tryParse(storyIdRaw?.toString() ?? '');
      if (storyId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Story not found. Please try again.')),
          );
        }
        return;
      }

      final res = await BackendClient.voiceSpeak(voiceId: voiceId, storyId: storyId);
      final url = res['url']?.toString();
      OnboardingState.instance.voicePlayUrl = url;

      if (mounted) {
        showCelebrationOverlay(
          context,
          message: 'Perfect! Your voice is cloned.',
          onComplete: () => context.go(OnboardingPlayerWidget.routePath),
          duration: const Duration(milliseconds: 2500),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load voice: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final durationSec =
        OnboardingState.instance.recordingDurationSec ?? 47;
    final timerText = _formatDuration(durationSec);
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = isNarrow ? 16.0 : 20.0;
    final contentPadding = isNarrow ? 12.0 : 16.0;
    final titleFontSize = isNarrow ? 22.0 : 24.0;
    final circleScale = width < 340 ? (width - horizontalPadding * 2) / 180 : 1.0;

    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: isNarrow ? 4 : 8, top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                  color: AuthTheme.gold,
                  onPressed: _isLoading ? null : () => context.go(OnboardingVoiceWidget.routePath),
                ),
              ),
            ),
            _progressBar(3),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxContentWidth = constraints.maxWidth - horizontalPadding * 2;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: maxContentWidth > 440 ? 440.0 : maxContentWidth,
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: isNarrow ? 16 : 24),
                          Text(
                            'Perfect!',
                            style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: titleFontSize),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isNarrow ? 8 : 12),
                          Text(
                            'Your voice has been recorded',
                            style: AuthTheme.welcomeSubStyle.copyWith(
                              fontSize: isNarrow ? 12 : 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: isNarrow ? 20 : 28),
                          if (circleScale < 1.0)
                            Transform.scale(
                              scale: circleScale,
                              child: RecordingCircle(
                                progress: 1.0,
                                timerText: timerText,
                                label: 'COMPLETE',
                                showCheckmark: true,
                              ),
                            )
                          else
                            RecordingCircle(
                              progress: 1.0,
                              timerText: timerText,
                              label: 'COMPLETE',
                              showCheckmark: true,
                            ),
                          SizedBox(height: isNarrow ? 24 : 32),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(contentPadding),
                            decoration: BoxDecoration(
                              color: AuthTheme.goldPale,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AuthTheme.goldLight),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  'Great recording!',
                                  style: GoogleFonts.outfit(
                                    fontSize: isNarrow ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: AuthTheme.goldDark,
                                  ),
                                ),
                                SizedBox(height: isNarrow ? 4 : 6),
                                Text(
                                  "We'll use this to create stories in your authentic voice",
                                  style: GoogleFonts.outfit(
                                    fontSize: isNarrow ? 10 : 11,
                                    color: AuthTheme.inkMid,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: isNarrow ? 18 : 24),
                          Opacity(
                            opacity: _isLoading ? 0.5 : 1,
                            child: GestureDetector(
                              onTap: _isLoading ? null : () {
                                // TODO: play recording when audio is implemented
                              },
                              child: Text(
                                'Listen to recording',
                                style: GoogleFonts.outfit(
                                  fontSize: isNarrow ? 12 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: AuthTheme.gold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isNarrow ? 18 : 24),
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: AuthTheme.gold,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: _isLoading ? null : _onContinue,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    vertical: isNarrow ? 14 : 15,
                                    horizontal: 16,
                                  ),
                                  alignment: Alignment.center,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AuthTheme.surface,
                                          ),
                                        )
                                      : FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Continue',
                                            style: AuthTheme.primaryButtonStyle,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () =>
                                  context.go(OnboardingVoiceWidget.routePath),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: isNarrow ? 14 : 15,
                                ),
                                side: const BorderSide(color: AuthTheme.stone, width: 1.5),
                                backgroundColor: AuthTheme.warmWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Re-record',
                                  style: GoogleFonts.outfit(
                                    fontSize: isNarrow ? 14 : 15,
                                    fontWeight: FontWeight.w600,
                                    color: AuthTheme.gold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: isNarrow ? 24 : 32),
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
    );
  }
}
