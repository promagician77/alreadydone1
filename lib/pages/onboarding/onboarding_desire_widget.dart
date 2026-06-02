import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
import '/services/ai_consent_service.dart';
import '/services/desire_speech_service.dart';
import '/widgets/pressable.dart';
import '/flutter_flow/nav/nav.dart';
import 'onboarding_state.dart';
import 'onboarding_personalize_widget.dart';
import 'onboarding_voice_selection_widget.dart';
import 'onboarding_splash_widget.dart';

const _desireNavy = Color(0xFF1E2A4A);
const _desireRecordRed = Color(0xFFC0392B);

const _categoryExamples = [
  "The deeply loving relationship where I'm completely seen, adored, and chosen every single day. I wake up next to someone who feels like home, and I finally understand what it means to be loved exactly as I am.",
  "The money hits my account and I feel calm, not anxious. Every bill is paid, my savings keep growing, and I buy what I want without checking the price. I'm finally free, and I get to be generous with the people I love.",
  "I built something that matters and the world noticed. I do work I'm proud of, I'm paid what I'm worth, and I lead with confidence. People respect me, and for the first time my career feels like mine.",
  "I wake up with energy and my body feels strong and alive. I'm at peace in my own skin, the tests came back clear, and I trust my body again. I feel healthy, vibrant, and genuinely happy to be here.",
  "I turn the key and walk into the home that's truly mine. Sunlight fills every room, my family is safe and happy here, and I feel a deep sense of peace knowing this is ours. I'm finally home.",
  "I finally feel like myself. The fear that used to run my life is gone, I trust my own decisions, and I'm proud of who I've become. I'm calm, confident, and at peace with exactly where I am.",
];

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

String _capitalizeSentences(String text) {
  if (text.isEmpty) return text;
  final chars = text.characters.toList();
  bool shouldCapNextLetter = true; // start of input

  for (var i = 0; i < chars.length; i++) {
    final c = chars[i];

    // Sentence terminators toggle the next-letter flag.
    if (c == '.' || c == '!' || c == '?') {
      shouldCapNextLetter = true;
      continue;
    }

    // Whitespace doesn't consume the flag.
    if (c.trim().isEmpty) continue;

    if (shouldCapNextLetter) {
      chars[i] = c.toUpperCase();
      shouldCapNextLetter = false;
    } else {
      shouldCapNextLetter = false;
    }
  }

  return chars.join();
}

class OnboardingDesireWidget extends StatefulWidget {
  const OnboardingDesireWidget({
    super.key,
    @Deprecated('No longer used; kept for hot-reload/backwards compatibility.')
    this.fromDesires,
  });

  @Deprecated('No longer used; kept for hot-reload/backwards compatibility.')
  final bool? fromDesires;

  static String routeName = 'OnboardingDesire';
  static String routePath = '/onboarding/desire';

  @override
  State<OnboardingDesireWidget> createState() => _OnboardingDesireWidgetState();
}

class _OnboardingDesireWidgetState extends State<OnboardingDesireWidget> {
  late OnboardingState _state;
  bool _prefillLoading = false;
  bool _isSubscribed = false;
  final _desireFocusNode = FocusNode();
  final _speechService = DesireSpeechService();
  final _pingPlayer = AudioPlayer();
  bool _isListening = false;
  bool _fieldFocused = false;
  String _speechBase = '';

  String _nextResetMessage() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
    final time = dateTimeFormat('jm', nextMidnight);
    final date = dateTimeFormat('MMM d', nextMidnight);
    return 'You can create one story per day. Try again at $time ($date).';
  }

  bool _isSameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
    _prefillLoading = true;
    _desireFocusNode.addListener(() {
      final focused = _desireFocusNode.hasFocus;
      if (focused != _fieldFocused && mounted) {
        setState(() => _fieldFocused = focused);
      }
    });
    _speechService.onStatus = (status) {
      if (!mounted) return;
      if ((status == 'done' || status == 'notListening') && _isListening) {
        setState(() => _isListening = false);
      }
    };
    _speechService.onError = (_) {
      if (!mounted) return;
      setState(() => _isListening = false);
      AppToast.info(context, 'Could not recognize speech. Try again.');
    };
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrefillForSubscribedUser());
  }

  @override
  void dispose() {
    _speechService.stopListening();
    _pingPlayer.dispose();
    _desireFocusNode.dispose();
    super.dispose();
  }

  String _desireHintText() {
    const prefix = 'Be specific. Be emotional. Make it real.\n\nExample: ';
    return '$prefix${_categoryExamples[_state.selectedCategory]}';
  }

  /// Generates a short ping tone (880 Hz, 0.3 s, exponential decay) as WAV bytes.
  Uint8List _generatePingWav() {
    const sampleRate = 44100;
    const frequency = 880.0;
    final numSamples = (sampleRate * 0.3).round();
    final dataSize = numSamples * 2;

    final wav = ByteData(44 + dataSize);
    // RIFF
    wav..setUint8(0, 0x52)..setUint8(1, 0x49)..setUint8(2, 0x46)..setUint8(3, 0x46);
    wav.setUint32(4, 36 + dataSize, Endian.little);
    // WAVE
    wav..setUint8(8, 0x57)..setUint8(9, 0x41)..setUint8(10, 0x56)..setUint8(11, 0x45);
    // fmt
    wav..setUint8(12, 0x66)..setUint8(13, 0x6D)..setUint8(14, 0x74)..setUint8(15, 0x20);
    wav.setUint32(16, 16, Endian.little);
    wav.setUint16(20, 1, Endian.little); // PCM
    wav.setUint16(22, 1, Endian.little); // mono
    wav.setUint32(24, sampleRate, Endian.little);
    wav.setUint32(28, sampleRate * 2, Endian.little);
    wav.setUint16(32, 2, Endian.little);
    wav.setUint16(34, 16, Endian.little);
    // data
    wav..setUint8(36, 0x64)..setUint8(37, 0x61)..setUint8(38, 0x74)..setUint8(39, 0x61);
    wav.setUint32(40, dataSize, Endian.little);

    for (var i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = math.exp(-t * 18);
      final sample = (envelope * 32767 * math.sin(2 * math.pi * frequency * t)).round().clamp(-32768, 32767);
      wav.setInt16(44 + i * 2, sample, Endian.little);
    }

    return wav.buffer.asUint8List();
  }

  Future<void> _playPing() async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/ping.wav');
      await file.writeAsBytes(_generatePingWav(), flush: true);
      await _pingPlayer.play(DeviceFileSource(file.path));
    } catch (_) {}
  }

  Future<void> _toggleSpeech() async {
    if (_isListening) {
      await _speechService.stopListening();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    unawaited(_playPing());

    final available = await _speechService.initialize();
    if (!available) {
      if (mounted) {
        AppToast.info(
          context,
          'Speech recognition is not available on this device.',
        );
      }
      return;
    }

    _speechBase = _state.desireDescriptionController.text.trim();
    final started = await _speechService.startListening(
      onTranscript: _applySpeechTranscript,
    );
    if (!started) {
      if (mounted) {
        AppToast.info(
          context,
          'Microphone permission is required to dictate your manifestation.',
        );
      }
      return;
    }
    if (mounted) setState(() => _isListening = true);
  }

  void _applySpeechTranscript(String words) {
    if (words.trim().isEmpty) return;
    final controller = _state.desireDescriptionController;
    final combined =
        _speechBase.isEmpty ? words.trim() : '${_speechBase.trim()} $words';
    final next = _capitalizeSentences(combined.trim());
    final offset = next.length;
    controller.value = controller.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  bool _isSubscribedFromProfile(Map<String, dynamic> profile) {
    final status = (profile['rc_subscription_status'] ??
            profile['rc_subscription_Status'])
        ?.toString()
        .toLowerCase()
        .trim();
    return status == 'active' || status == 'trial';
  }

  void _applyProfileToState(Map<String, dynamic> profile) {
    final name = (profile['name'] as String? ?? '').toString().trim();
    final loc = (profile['location'] ?? '').toString().trim();
    final loved = (profile['lovedOne'] ?? '').toString().trim();
    final energyWord = (profile['energyWord'] ?? '').toString().trim();

    _state.firstNameController.text = name;
    _state.dreamLocationController.text = loc;
    _state.lovedOneController.text = loved;

    final idx = OnboardingState.energyWords.indexOf(energyWord);
    if (idx >= 0) _state.selectedEnergyWord = idx;
  }

  Future<void> _maybePrefillForSubscribedUser() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    debugPrint('userId: $userId');

    if (userId == null || !mounted) {
      if (mounted) {
        setState(() {
          _isSubscribed = false;
          _prefillLoading = false;
        });
      }
      return;
    }
    try {
      final profile = await BackendClient.getUserProfile(userId);
      debugPrint('profile: $profile');
      if (!mounted) return;

      final subscribed = _isSubscribedFromProfile(profile);
      if (subscribed) {
        debugPrint('profile is subscribed');
        _applyProfileToState(profile);
        // Subscribed users are treated as "profile-driven": reset desire page inputs
        // on load so they start fresh.
        _state.clearDesireOnly();
      }

      if (mounted) {
        setState(() {
          _isSubscribed = subscribed;
          _prefillLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isSubscribed = false;
          _prefillLoading = false;
        });
      }
    }
  }

  Future<void> _handleCreateStory() async {
    if (_isListening) {
      await _speechService.stopListening();
      if (mounted) setState(() => _isListening = false);
    }

    final hasConsent = await AIConsentService.ensureConsent(context);
    if (!hasConsent) {
      if (mounted) {
        AppToast.info(
          context,
          'You need to agree to AI data sharing to create a manifestation.',
        );
      }
      return;
    }

    final userId = await SupabaseService.getCurrentUserTableId();
    String? timezone;
    if (userId != null) {
      try {
        final profile = await BackendClient.getUserProfile(userId);
        timezone = profile['timezone']?.toString();
      } catch (_) {
        // Best-effort; if profile fetch fails we'll proceed without timezone.
      }
    }
    final body = _state.toStoryRequestBody(userId, timezone: timezone);

    final name = body['name'] as String? ?? '';
    final location = body['location'] as String? ?? '';
    final description = body['desireDescription'] as String? ?? '';
    final someoneYouLove = body['lovedOne'] as String? ?? '';

    if (description.trim().isEmpty) {
      if (mounted) {
        AppToast.info(context, "Please describe what's already yours.");
      }
      return;
    }

    if (name.isEmpty || location.isEmpty || description.isEmpty || someoneYouLove.isEmpty) {
      if (mounted) {
        final missing = <String>[];
        if (name.isEmpty) missing.add('First Name');
        if (location.isEmpty) missing.add('Dream Place');
        if (someoneYouLove.isEmpty) missing.add('Someone You Love (Romantic)');
        AppToast.info(context, 'Please fill in ${missing.join(', ')}');
      }
      return;
    }

    if (userId == null) {
      if (mounted) {
        AppToast.info(context, 'Please sign in and try again.');
      }
      return;
    }

    try {
      setState(() => _state.isGenerating = true);

      if (userId != null) {
        final loved = body['lovedOne'] as String?;
        await BackendClient.updateUserProfile(
          userId,
          name: name,
          dreamPlace: location,
          location: location,
          energyWord: body['energyWord'] as String?,
          someoneYouLove: loved != null && loved.trim().isNotEmpty ? loved.trim() : null,
        );
      }
      final result = await BackendClient.generateStory(body);
      if (mounted) {
        _state.generatedStory = result;
        setState(() => _state.isGenerating = false);

        var subscribed = false;
        try {
          final profile = await BackendClient.getUserProfile(userId);
          final status = (profile['rc_subscription_status'] ??
                  profile['rc_subscription_Status'])
              ?.toString()
              .toLowerCase()
              .trim();
          subscribed = status == 'active' || status == 'trial';
        } catch (_) {}

        if (subscribed) {
          // No-op: subscribed users are reset on page load (initState) so that
          // non-subscribed users keep their maintained draft immediately after generation.
        }

        await _state.persistToPrefs(OnboardingVoiceSelectionWidget.routePath);
        if (mounted) {
          context.go(OnboardingVoiceSelectionWidget.routePath);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _state.isGenerating = false);
        final msg = e.toString();
        debugPrint('Error: $msg');
        if (msg.contains('403') &&
            (msg.contains('1 story per day') ||
                msg.contains('story per day'))) {
          AppToast.info(
            context,
            _nextResetMessage(),
          );
          final returnTo =
              Uri.encodeComponent(OnboardingDesireWidget.routePath);
          context.go('${OnboardingSplashWidget.routePath}?returnTo=$returnTo');
        } else {
          AppToast.error(context, 'Failed to generate story. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('❤️', 'Love'),
      ('💰', 'Money/Lifestyle'),
      ('💼', 'Career/Business'),
      ('🌟', 'Health'),
      ('🏠', 'Home'),
      ('✨', 'Personal Growth'),
    ];
    return Scaffold(
      backgroundColor: AuthTheme.warmWhite,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                      color: AuthTheme.gold,
                      onPressed: () async {
                        if (_isListening) {
                          await _speechService.stopListening();
                        }
                        if (context.mounted) {
                          context.go(OnboardingPersonalizeWidget.routePath);
                        }
                      },
                    ),
                  ),
                ),
                _progressBar(2),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const gridSpacing = 8.0;
                      const gridAspectRatio = 2.85;
                      final gridWidth = constraints.maxWidth - 40;
                      final cellWidth =
                          (gridWidth - gridSpacing) / 2;
                      final cellHeight = cellWidth / gridAspectRatio;
                      final gridHeight =
                          cellHeight * 3 + gridSpacing * 2;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 8),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "What's already done\nfor you?",
                                    style: AuthTheme.welcomeTitleStyle
                                        .copyWith(fontSize: 22),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Choose a category',
                                    style: AuthTheme.welcomeSubStyle,
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: gridHeight,
                                    child: GridView.count(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: 2,
                                      mainAxisSpacing: gridSpacing,
                                      crossAxisSpacing: gridSpacing,
                                      childAspectRatio: gridAspectRatio,
                                      children: List.generate(
                                        categories.length,
                                        (i) {
                                          final (icon, label) =
                                              categories[i];
                                          final selected =
                                              _state.selectedCategory == i;
                                          return Pressable(
                                            onTap: () => setState(
                                              () => _state.selectedCategory =
                                                  i,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? AuthTheme.goldPale
                                                    : AuthTheme.surface,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: selected
                                                      ? AuthTheme.gold
                                                      : AuthTheme.stone,
                                                  width:
                                                      selected ? 1.5 : 1,
                                                ),
                                              ),
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    icon,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    label,
                                                    textAlign: TextAlign.center,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: GoogleFonts.outfit(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: AuthTheme.ink,
                                                      height: 1.1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Describe What\'s Already Yours',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AuthTheme.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '(Describe it like it\'s already yours)',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AuthTheme.inkSoft,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: AuthTheme.surface,
                                        borderRadius:
                                            BorderRadius.circular(18),
                                        border: Border.all(
                                          color: _fieldFocused ||
                                                  _isListening
                                              ? AuthTheme.gold
                                              : AuthTheme.stone,
                                          width: 1.5,
                                        ),
                                        boxShadow: (_fieldFocused ||
                                                _isListening)
                                            ? [
                                                BoxShadow(
                                                  color: AuthTheme.gold
                                                      .withValues(
                                                          alpha: 0.10),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                              18,
                                              14,
                                              18,
                                              56,
                                            ),
                                            child: TextField(
                                              controller: _state
                                                  .desireDescriptionController,
                                              focusNode: _desireFocusNode,
                                              expands: true,
                                              maxLines: null,
                                              textAlignVertical:
                                                  TextAlignVertical.top,
                                              textCapitalization:
                                                  TextCapitalization
                                                      .sentences,
                                              scrollPhysics:
                                                  const BouncingScrollPhysics(),
                                              onChanged: (value) {
                                                final next =
                                                    _capitalizeSentences(
                                                        value);
                                                if (next == value) return;
                                                final controller = _state
                                                    .desireDescriptionController;
                                                final oldSelection =
                                                    controller.selection;
                                                final offset = oldSelection
                                                    .baseOffset
                                                    .clamp(0, next.length);
                                                controller.value = controller
                                                    .value
                                                    .copyWith(
                                                  text: next,
                                                  selection:
                                                      TextSelection.collapsed(
                                                    offset: offset,
                                                  ),
                                                  composing: TextRange.empty,
                                                );
                                              },
                                              style: AuthTheme.bodyStyle
                                                  .copyWith(
                                                fontSize: 15,
                                                height: 1.5,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: _desireHintText(),
                                                hintStyle: AuthTheme
                                                    .placeholderStyle
                                                    .copyWith(
                                                  fontSize: 15,
                                                  color: const Color(
                                                    0xFFB6B1A7,
                                                  ),
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                              ),
                                            ),
                                          ),
                                          if (_isListening)
                                            const Positioned(
                                              left: 18,
                                              bottom: 20,
                                              child: _ListeningIndicator(),
                                            ),
                                          Positioned(
                                            right: 14,
                                            bottom: 12,
                                            child: _DesireMicButton(
                                              isListening: _isListening,
                                              onPressed: _toggleSpeech,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.mic_none,
                                        size: 13,
                                        color: AuthTheme.inkSoft
                                            .withValues(alpha: 0.9),
                                      ),
                                      const SizedBox(width: 6),
                                      Flexible(
                                        child: Text(
                                          'Tap the mic to speak instead of type',
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
                                            color: AuthTheme.inkSoft,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AuthTheme.surface,
                              border: Border(
                                top: BorderSide(
                                  color:
                                      AuthTheme.stone.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  (MediaQuery.sizeOf(context).width * 0.064)
                                      .clamp(20.0, 32.0),
                              vertical: 10,
                            ),
                            child: SizedBox(
                              width: double.infinity,
                              child: Material(
                                color: (_state.isGenerating || _prefillLoading)
                                    ? AuthTheme.stone
                                    : AuthTheme.gold,
                                borderRadius: BorderRadius.circular(12),
                                child: InkWell(
                                  onTap: (_state.isGenerating || _prefillLoading)
                                      ? null
                                      : _handleCreateStory,
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    alignment: Alignment.center,
                                    child: _prefillLoading
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AuthTheme.surface,
                                            ),
                                          )
                                        : Text(
                                            'Create My Story',
                                            style:
                                                AuthTheme.primaryButtonStyle,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_state.isGenerating)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  color: Colors.black54,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AuthTheme.gold),
                      const SizedBox(height: 16),
                      Text(
                        'Creating your story...',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Please wait...',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This takes about 30 seconds.',
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
            ),
          if (_prefillLoading)
            Positioned.fill(
              child: AbsorbPointer(
                child: Container(
                  color: AuthTheme.warmWhite.withValues(alpha: 0.85),
                  alignment: Alignment.center,
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthTheme.gold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ListeningIndicator extends StatelessWidget {
  const _ListeningIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ListeningBars(),
        const SizedBox(width: 8),
        Text(
          'Listening...',
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _desireRecordRed,
          ),
        ),
      ],
    );
  }
}

class _ListeningBars extends StatefulWidget {
  const _ListeningBars();

  @override
  State<_ListeningBars> createState() => _ListeningBarsState();
}

class _ListeningBarsState extends State<_ListeningBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 16,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final phase = i * 0.15;
              final t = (_controller.value + phase) * 2 * math.pi;
              final height = 5 + 11 * ((math.sin(t) + 1) / 2);
              return Container(
                width: 3,
                height: height.clamp(5.0, 16.0),
                margin: EdgeInsets.only(left: i == 0 ? 0 : 3),
                decoration: BoxDecoration(
                  color: _desireRecordRed,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class _DesireMicButton extends StatefulWidget {
  const _DesireMicButton({
    required this.isListening,
    required this.onPressed,
  });

  final bool isListening;
  final VoidCallback onPressed;

  @override
  State<_DesireMicButton> createState() => _DesireMicButtonState();
}

class _DesireMicButtonState extends State<_DesireMicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    );
  }

  @override
  void didUpdateWidget(covariant _DesireMicButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isListening && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  static const _buttonSize = 46.0;
  static const _haloSize = 56.0;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isListening ? _desireRecordRed : _desireNavy;
    final haloColor = widget.isListening ? _desireRecordRed : _desireNavy;
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final pulse = widget.isListening ? _pulseController.value : 0.0;
        final haloExpand = widget.isListening ? 8 * pulse : 0.0;
        final haloOpacity =
            widget.isListening ? 0.28 + 0.22 * (1 - pulse) : 0.14;
        final haloDiameter = _haloSize + haloExpand;
        return SizedBox(
          width: haloDiameter + 12,
          height: haloDiameter + 12,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              // Circular halo — drawn outside the button so it is not clipped
              // to the 46×46 ink bounds (which looked like a light square).
              Container(
                width: haloDiameter,
                height: haloDiameter,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: haloColor.withValues(alpha: haloOpacity),
                  boxShadow: [
                    BoxShadow(
                      color: haloColor.withValues(
                        alpha: widget.isListening ? 0.35 * (1 - pulse) : 0.12,
                      ),
                      blurRadius: widget.isListening ? 20 : 10,
                      spreadRadius: widget.isListening ? 2 * pulse : 0,
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onPressed,
                  customBorder: const CircleBorder(),
                  splashColor: Colors.white.withValues(alpha: 0.22),
                  highlightColor: Colors.white.withValues(alpha: 0.12),
                  child: Container(
                    width: _buttonSize,
                    height: _buttonSize,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: child,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.mic, color: Colors.white, size: 22),
    );
  }
}
