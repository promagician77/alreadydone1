import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import 'onboarding_desire_widget.dart';
import 'onboarding_voice_widget.dart';
import 'onboarding_player_widget.dart';
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
    // Marcus
    ('24EI9FmmGvJruwUi7TJM', 'Marcus', 'Warm & Soothing'),
    // David
    ('8yh4Wuya1OlwcUp0epGF', 'David', 'Confident & Powerful'),
    // Alex
    ('tJHJUEHzOkMoPmJJ5jo2', 'Alex', 'Gentle & Peaceful'),
  ];

  static const _femaleVoices = [
    // Sarah
    ('KGZeK6FsnWQdrkDHnDNA', 'Sarah', 'Warm & Nurturing'),
    // Maya
    ('NXqsj0QYxuanzBw3KwjB', 'Maya', 'Energetic & Inspiring'),
    // Luna
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final isNarrow = width < 360;
    final horizontalPadding = isNarrow ? 16.0 : 20.0;

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
                  onPressed: () => context.go(OnboardingDesireWidget.routePath),
                ),
              ),
            ),
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

  Future<void> _onMyVoiceTapped() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) {
      setState(() => _selectedId = 'my_voice');
      return;
    }
    try {
      final profile = await BackendClient.getUserProfile(userId);
      final voiceId = (profile['voice_id'] ?? profile['voice_Id'])?.toString().trim();
      final hasRecordedVoice = (voiceId != null && voiceId.isNotEmpty);
      if (!mounted) return;
      if (hasRecordedVoice) {
        _showAlreadyRecordedModal();
        return;
      }
      setState(() => _selectedId = 'my_voice');
    } catch (_) {
      if (mounted) setState(() => _selectedId = 'my_voice');
    }
  }

  void _showAlreadyRecordedModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Your voice is already recorded',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AuthTheme.ink,
          ),
        ),
        content: Text(
          'You can go to the home dashboard or choose a pre-made voice for this story.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AuthTheme.inkSoft,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/');
            },
            child: Text('To home', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AuthTheme.gold)),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: FilledButton.styleFrom(
              backgroundColor: AuthTheme.gold,
              foregroundColor: AuthTheme.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Select the pre-made voice', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
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
              context.go(OnboardingVoiceWidget.routePath);
              return;
            }

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
              _isLoading ? 'Loading...' : 'Continue',
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
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
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
      await _player.resume();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Preview: ${widget.voiceName}',
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AuthTheme.ink,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthTheme.gold,
                    ),
                  ),
                ),
              IconButton.filled(
                onPressed: _error != null ? null : _togglePlayPause,
                icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AuthTheme.gold,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onClose,
          child: Text(
            'Close',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: AuthTheme.gold),
          ),
        ),
      ],
    );
  }
}

