import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
import '/services/ai_consent_service.dart';
import '/widgets/pressable.dart';
import '/flutter_flow/nav/nav.dart';
import 'onboarding_state.dart';
import 'onboarding_personalize_widget.dart';
import 'onboarding_voice_selection_widget.dart';
import 'onboarding_splash_widget.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybePrefillForSubscribedUser());
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
        if (someoneYouLove.isEmpty) missing.add('Someone You Love');
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
                  onPressed: () =>
                      context.go(OnboardingPersonalizeWidget.routePath),
                ),
              ),
            ),
            _progressBar(2),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "What's already done\nfor you?",
                      style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text('Choose a category', style: AuthTheme.welcomeSubStyle),
                    const SizedBox(height: 32),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.2,
                      children: List.generate(categories.length, (i) {
                        final (icon, label) = categories[i];
                        final selected = _state.selectedCategory == i;
                        return Pressable(
                          onTap: () => setState(() => _state.selectedCategory = i),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: selected ? AuthTheme.goldPale : AuthTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selected ? AuthTheme.gold : AuthTheme.stone,
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(icon, style: const TextStyle(fontSize: 24)),
                                const SizedBox(height: 6),
                                Text(
                                  label,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AuthTheme.ink,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text('Describe What\'s Already Yours', style: AuthTheme.labelStyle),
                        Text(
                          '(Write Your Desired Manifestation Here)',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AuthTheme.inkSoft,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AuthTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AuthTheme.stone),
                      ),
                      child: TextField(
                        controller: _state.desireDescriptionController,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          final next = _capitalizeSentences(value);
                          if (next == value) return;
                          final controller = _state.desireDescriptionController;
                          final oldSelection = controller.selection;
                          final offset = oldSelection.baseOffset.clamp(0, next.length);
                          controller.value = controller.value.copyWith(
                            text: next,
                            selection: TextSelection.collapsed(offset: offset),
                            composing: TextRange.empty,
                          );
                        },
                        style: AuthTheme.bodyStyle.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Write it like it already happened. Be specific. Be emotional.\n\nExample: The deeply loving relationship where I felt completely seen, valued, and cherished every single day",
                          hintStyle: AuthTheme.placeholderStyle.copyWith(fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                child: Material(
                  color: (_state.isGenerating || _prefillLoading) ? AuthTheme.stone : AuthTheme.gold,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: (_state.isGenerating || _prefillLoading) ? null : _handleCreateStory,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
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
                        : Text('Create My Story', style: AuthTheme.primaryButtonStyle),
                    ),
                  ),
                ),
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
