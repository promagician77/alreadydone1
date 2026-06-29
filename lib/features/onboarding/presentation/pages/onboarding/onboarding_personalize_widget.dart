import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/theme/auth_theme.dart';
import '/shared/widgets/pressable.dart';
import '/shared/services/app_toast.dart';
import '/core/di/profile_locator.dart';
import '/shared/services/supabase_service.dart';
import '/shared/state/onboarding_state.dart';
import 'onboarding_desire_widget.dart';
import 'onboarding_origin_splash_widget.dart';
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

/// Same 15 default locations as in profile dream location modal.
const _popularLocations = [
  'New York City', 'Paris', 'Bali', 'Tokyo', 'Miami', 'London',
  'Los Angeles', 'Dubai', 'Sydney', 'Toronto', 'Munich', 'Zurich',
  'Barcelona', 'Amsterdam', 'Copenhagen',
];

List<List<T>> _chunked<T>(List<T> list, int size) {
  final result = <List<T>>[];
  for (var i = 0; i < list.length; i += size) {
    result.add(list.sublist(i, (i + size).clamp(0, list.length)));
  }
  return result;
}

String _capitalizeFirst(String text) {
  final t = text.trimLeft();
  if (t.isEmpty) return text;
  final first = t.characters.first.toUpperCase();
  final rest = t.characters.skip(1).toString();
  // Preserve original left padding/spaces the user typed.
  final leading = text.substring(0, text.length - t.length);
  return '$leading$first$rest';
}

Widget _formInput(TextEditingController controller, String hint) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    decoration: BoxDecoration(
      color: AuthTheme.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AuthTheme.stone),
    ),
    child: TextField(
      controller: controller,
      textCapitalization: TextCapitalization.words,
      onChanged: (value) {
        final next = _capitalizeFirst(value);
        if (next == value) return;
        final oldSelection = controller.selection;
        final offset = oldSelection.baseOffset.clamp(0, next.length);
        controller.value = controller.value.copyWith(
          text: next,
          selection: TextSelection.collapsed(offset: offset),
          composing: TextRange.empty,
        );
      },
      style: AuthTheme.bodyStyle.copyWith(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AuthTheme.placeholderStyle,
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
        isDense: true,
      ),
    ),
  );
}

class OnboardingPersonalizeWidget extends StatefulWidget {
  const OnboardingPersonalizeWidget({super.key});

  static String routeName = 'OnboardingPersonalize';
  static String routePath = '/onboarding/personalize';

  @override
  State<OnboardingPersonalizeWidget> createState() => _OnboardingPersonalizeWidgetState();
}

class _OnboardingPersonalizeWidgetState extends State<OnboardingPersonalizeWidget> {
  late OnboardingState _state;
  bool _collectFirstName = true;
  bool _authNameLoading = true;

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
    _state.dreamLocationController.addListener(_onDreamLocationChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAuthProvidedName());
  }

  Future<void> _loadAuthProvidedName() async {
    final collect = await SupabaseService.shouldCollectFirstNameInOnboarding();
    if (!mounted) return;
    setState(() {
      _collectFirstName = collect;
      _authNameLoading = false;
    });
  }

  String? get _resolvedFirstName {
    final name = _state.firstNameController.text.trim();
    return name.isEmpty ? null : name;
  }

  void _onDreamLocationChanged() => setState(() {});

  @override
  void dispose() {
    _state.dreamLocationController.removeListener(_onDreamLocationChanged);
    super.dispose();
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
                  onPressed: () => context.go(OnboardingOriginSplashWidget.routePath),
                ),
              ),
            ),
            _progressBar(1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "First, let's personalize\nyour experience",
                      style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These details make every story unique to you',
                      style: AuthTheme.welcomeSubStyle.copyWith(height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    if (_authNameLoading) ...[
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AuthTheme.gold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ] else if (_collectFirstName) ...[
                      Text('Your First Name', style: AuthTheme.labelStyle),
                      const SizedBox(height: 8),
                      _formInput(_state.firstNameController, 'Jordan'),
                      const SizedBox(height: 20),
                    ] else if (_resolvedFirstName != null) ...[
                      Text(
                        'Hi, ${_resolvedFirstName!}!',
                        style: AuthTheme.welcomeTitleStyle.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 20),
                    ],
                    Text('Where does your dream life take place?', style: AuthTheme.labelStyle),
                    const SizedBox(height: 4),
                    Text('City or country', style: AuthTheme.checkboxLabelStyle.copyWith(fontSize: 11, color: AuthTheme.inkSoft)),
                    const SizedBox(height: 8),
                    _formInput(_state.dreamLocationController, 'Bali'),
                    const SizedBox(height: 12),
                    Text(
                      'POPULAR LOCATIONS',
                      style: AuthTheme.labelStyle.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                        color: AuthTheme.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._chunked(_popularLocations, 3).map((row) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: row.asMap().entries.map((e) {
                          final loc = e.value;
                          final isSelected = _state.dreamLocationController.text.trim() == loc;
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(right: e.key < row.length - 1 ? 8 : 0),
                              child: Pressable(
                                onTap: () {
                                  _state.dreamLocationController.text = loc;
                                  setState(() {});
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AuthTheme.goldPale : AuthTheme.surface,
                                    border: Border.all(
                                      color: isSelected ? AuthTheme.gold : AuthTheme.stone,
                                      width: 1.5,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      loc,
                                      style: GoogleFonts.outfit(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? AuthTheme.gold : AuthTheme.ink,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    )),
                    const SizedBox(height: 20),
                    Text('Choose Your Energy Word', style: AuthTheme.labelStyle),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(OnboardingState.energyWords.length, (i) {
                        final selected = _state.selectedEnergyWord == i;
                        return Pressable(
                          onTap: () => setState(() => _state.selectedEnergyWord = i),
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AuthTheme.goldPale : AuthTheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: selected ? AuthTheme.gold : AuthTheme.stone,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              OnboardingState.energyWords[i],
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: selected ? AuthTheme.gold : AuthTheme.inkSoft,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    Text('Someone You Love (Romantic)', style: AuthTheme.labelStyle),
                    const SizedBox(height: 8),
                    _formInput(_state.lovedOneController, 'Alex'),
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
                  color: AuthTheme.gold,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () async {
                      if (_authNameLoading) return;
                      final name = _state.firstNameController.text.trim();
                      final place = _state.dreamLocationController.text.trim();
                      final loved = _state.lovedOneController.text.trim();
                      if (_collectFirstName && name.isEmpty) {
                        AppToast.info(context, 'Please enter your first name');
                        return;
                      }
                      if (!_collectFirstName && name.isEmpty) {
                        AppToast.info(
                          context,
                          'We could not load your name from Sign in with Apple. '
                          'Please sign out and sign in again.',
                        );
                        return;
                      }
                      if (place.isEmpty) {
                        AppToast.info(context, 'Please enter your dream place');
                        return;
                      }
                      if (loved.isEmpty) {
                        AppToast.info(context, 'Please enter someone you love (romantic)');
                        return;
                      }
                      await _state.persistToPrefs(OnboardingDesireWidget.routePath);
                      final userId = await SupabaseService.getCurrentUserTableId();
                      if (userId != null) {
                        try {
                          await profileRepository.updateUserProfile(
                            userId,
                            name: name,
                            location: place,
                            someoneYouLove: loved,
                          );
                        } catch (e) {
                          if (!context.mounted) return;
                          AppToast.error(
                            context,
                            'Could not save to your profile: '
                            '${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
                          );
                        }
                      }
                      if (!context.mounted) return;
                      context.push(OnboardingDesireWidget.routePath);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text('Continue', style: AuthTheme.primaryButtonStyle),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
