import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/widgets/pressable.dart';
import '/services/app_toast.dart';
import 'onboarding_state.dart';
import 'onboarding_desire_widget.dart';
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

  @override
  void initState() {
    super.initState();
    _state = OnboardingState.instance;
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
                  onPressed: () => context.go(OnboardingSplashWidget.routePath),
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
                    Text('Your First Name', style: AuthTheme.labelStyle),
                    const SizedBox(height: 8),
                    _formInput(_state.firstNameController, 'Jordan'),
                    const SizedBox(height: 20),
                    Text('Where does your dream life take place?', style: AuthTheme.labelStyle),
                    const SizedBox(height: 4),
                    Text('City or country', style: AuthTheme.checkboxLabelStyle.copyWith(fontSize: 11, color: AuthTheme.inkSoft)),
                    const SizedBox(height: 8),
                    _formInput(_state.dreamLocationController, 'Bali'),
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
                    Text('Someone You Love', style: AuthTheme.labelStyle),
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
                    onTap: () {
                      final name = _state.firstNameController.text.trim();
                      final place = _state.dreamLocationController.text.trim();
                      final loved = _state.lovedOneController.text.trim();
                      if (name.isEmpty) {
                        AppToast.info(context, 'Please enter your first name');
                        return;
                      }
                      if (place.isEmpty) {
                        AppToast.info(context, 'Please enter your dream place');
                        return;
                      }
                      if (loved.isEmpty) {
                        AppToast.info(context, 'Please enter someone you love');
                        return;
                      }
                      context.go(OnboardingDesireWidget.routePath);
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
