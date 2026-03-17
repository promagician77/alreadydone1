import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import '/services/app_toast.dart';
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

class OnboardingDesireWidget extends StatefulWidget {
  const OnboardingDesireWidget({super.key, this.fromDesires = false});

  static String routeName = 'OnboardingDesire';
  static String routePath = '/onboarding/desire';

  /// When true, user came from Desires "Add New Manifestation"; prefill from profile.
  final bool fromDesires;

  @override
  State<OnboardingDesireWidget> createState() => _OnboardingDesireWidgetState();
}

class _OnboardingDesireWidgetState extends State<OnboardingDesireWidget> {
  late OnboardingState _state;
  bool _prefillLoading = false;

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
    if (widget.fromDesires) {
      _prefillLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _prefillFromProfile());
    }
  }

  /// When opening from Desires, load user profile and prefill name, location, energy word, loved one.
  Future<void> _prefillFromProfile() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null || !mounted) return;
    try {
      final profile = await BackendClient.getUserProfile(userId);
      if (!mounted) return;
      final name = (profile['name'] as String? ?? '').toString().trim();
      final loc = (profile['location'] ?? profile['country_city'] ?? profile['dream_place'] ?? '').toString().trim();
      final loved = (profile['lovedOne'] ?? profile['someone_love'] ?? profile['someone_you_love'] ?? '').toString().trim();
      final energyWord = (profile['energy_word'] ?? profile['energyWord'] ?? '').toString();
      if (name.isNotEmpty) _state.firstNameController.text = name;
      if (loc.isNotEmpty) _state.dreamLocationController.text = loc;
      if (loved.isNotEmpty) _state.lovedOneController.text = loved;
      final idx = OnboardingState.energyWords.indexOf(energyWord);
      if (idx >= 0) _state.selectedEnergyWord = idx;
      if (mounted) setState(() => _prefillLoading = false);
    } catch (_) {
      if (mounted) setState(() => _prefillLoading = false);
    }
  }

  Future<void> _handleCreateStory() async {
    final userId = await SupabaseService.getCurrentUserTableId();
    if (userId == null) return;

    final body = _state.toStoryRequestBody(userId);

    final name = body['name'] as String? ?? '';
    final location = body['location'] as String? ?? '';
    final description = body['desireDescription'] as String? ?? '';
    final someoneYouLove = body['lovedOne'] as String? ?? '';

    if (name.isEmpty || location.isEmpty || description.isEmpty || someoneYouLove.isEmpty) {
      if (mounted) {
        final missing = <String>[];
        if (name.isEmpty) missing.add('First Name');
        if (location.isEmpty) missing.add('Dream Place');
        if (someoneYouLove.isEmpty) missing.add('Someone You Love');
        if (description.isEmpty) missing.add('Description');
        AppToast.info(context, 'Please fill in ${missing.join(', ')}');
      }
      return;
    }

    try {
      final profile = await BackendClient.getUserProfile(userId);

      debugPrint('Profile: $profile');
      final status = (profile['rc_subscription_status'] ?? profile['rc_subscription_Status'])
          ?.toString()
          .toLowerCase()
          .trim();
        
      debugPrint('Status: $status');

      final isSubscribed = status == 'active' || status == 'trial';

      if (!isSubscribed) {
        final res = await BackendClient.getStories(userId);
        final list = res['stories'];
        final storyCount = list is List ? list.length : 0;
        if (storyCount >= 1 && mounted) {
          AppToast.info(
            context,
            'You can create one story per day without a subscription. Subscribe to create more.',
          );
          context.go(OnboardingSplashWidget.routePath);
          return;
        }
      }
    } catch (_) {
      // If profile/stories fetch fails, let the backend enforce the limit (may get 403).
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
            (msg.contains('Non-subscribers') || msg.contains('1 story per day'))) {
          AppToast.info(
            context,
            'You can create one story per day without a subscription. Subscribe to create more.',
          );
        } else {
          AppToast.error(context, 'Failed to generate story. Please try again.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('♡', 'Love'),
      (r'$', 'Money'),
      ('✦', 'Career'),
      ('🌿', 'Health'),
      ('🏠', 'Home'),
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
                  onPressed: () => context.pop(),
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
                    Text('Describe What\'s Already Yours', style: AuthTheme.labelStyle),
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
                    ],
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
