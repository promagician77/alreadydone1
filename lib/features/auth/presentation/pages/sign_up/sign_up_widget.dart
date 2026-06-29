import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/theme/auth_theme.dart';
import '/core/di/auth_locator.dart';
import '/shared/services/supabase_service.dart';
import '/shared/services/app_toast.dart';
import '/shared/services/timezone_sync_service.dart';
import '/shared/widgets/pressable.dart';
import '/core/constants/legal_urls.dart';
import 'sign_up_model.dart';
export 'sign_up_model.dart';

String _capitalizeNameWordStarts(String text) {
  if (text.isEmpty) return text;
  return text.replaceAllMapped(RegExp(r'(^|[\s])(\S)'), (m) {
    return '${m.group(1)}${m.group(2)!.toUpperCase()}';
  });
}

class SignUpWidget extends StatefulWidget {
  const SignUpWidget({super.key});

  static String routeName = 'SignUp';
  static String routePath = '/signUp';

  @override
  State<SignUpWidget> createState() => _SignUpWidgetState();
}

class _SignUpWidgetState extends State<SignUpWidget> {
  late SignUpModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpModel());

    _termsTap = TapGestureRecognizer()
      ..onTap = () {
        launchURL(kTermsOfServiceUri.toString());
      };
    _privacyTap = TapGestureRecognizer()
      ..onTap = () {
        launchURL(kPrivacyPolicyUri.toString());
      };
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: AuthTheme.warmWhite,
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, top: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                    color: AuthTheme.gold,
                    onPressed: () => context.go('/login'),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 28),
                      const Center(child: WaveformIcon()),
                      const SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: AuthTheme.welcomeTitleStyle,
                          children: [
                            const TextSpan(text: 'Welcome to '),
                            TextSpan(text: 'Already Done', style: AuthTheme.welcomeTitleItalicStyle),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Listen To Stories of Your Dream Life in Your Own Voice',
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeSubStyle,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create your account to begin manifesting',
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeSubStyle,
                      ),
                      const SizedBox(height: 24),
                      _label('Full Name'),
                      const SizedBox(height: 6),
                      _input(
                        controller: _model.nameTextController,
                        focusNode: _model.nameFocusNode,
                        hint: 'Jordan Smith',
                        keyboardType: TextInputType.name,
                        textCapitalization: TextCapitalization.words,
                        onChanged: _onFullNameChanged,
                      ),
                      const SizedBox(height: 16),
                      _label('Email Address'),
                      const SizedBox(height: 6),
                      _input(
                        controller: _model.emailTextController,
                        focusNode: _model.emailFocusNode,
                        hint: 'jordan@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _label('Password'),
                      const SizedBox(height: 6),
                      _input(
                        controller: _model.passwordTextController,
                        focusNode: _model.passwordFocusNode,
                        hint: '8+ chars, upper/lower, number, symbol',
                        obscureText: _model.obscurePassword,
                        onObscuredToggle: () => setState(
                          () => _model.obscurePassword = !_model.obscurePassword,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _label('Confirm Password'),
                      const SizedBox(height: 6),
                      _input(
                        controller: _model.confirmPasswordTextController,
                        focusNode: _model.confirmPasswordFocusNode,
                        hint: 'Re-enter your password',
                        obscureText: _model.obscureConfirmPassword,
                        onObscuredToggle: () => setState(
                          () => _model.obscureConfirmPassword =
                              !_model.obscureConfirmPassword,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _termsCheckbox(),
                      const SizedBox(height: 8),
                      _primaryButton('Create Account', _handleSignUp),
                      const SizedBox(height: 20),
                      _divider(),
                      const SizedBox(height: 20),
                      _socialButtons(),
                      if (_model.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator(color: AuthTheme.gold)),
                        ),
                      const SizedBox(height: 16),
                      _footer('Already have an account? ', 'Log in', () => context.go('/login')),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text, style: AuthTheme.labelStyle);

  String? _getPasswordValidationError(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return 'Password must include at least one uppercase letter.';
    }
    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return 'Password must include at least one lowercase letter.';
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return 'Password must include at least one number.';
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];`~+=]').hasMatch(password)) {
      return 'Password must include at least one special character.';
    }
    return null;
  }

  void _onFullNameChanged(String value) {
    final next = _capitalizeNameWordStarts(value);
    if (next == value) return;
    final c = _model.nameTextController;
    final offset = c.selection.baseOffset.clamp(0, next.length);
    c.value = c.value.copyWith(
      text: next,
      selection: TextSelection.collapsed(offset: offset),
      composing: TextRange.empty,
    );
  }

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    TextCapitalization textCapitalization = TextCapitalization.none,
    ValueChanged<String>? onChanged,
    VoidCallback? onObscuredToggle,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      onChanged: onChanged,
      style: AuthTheme.bodyStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AuthTheme.placeholderStyle,
        filled: true,
        fillColor: AuthTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuthTheme.stone)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AuthTheme.gold)),
        suffixIcon: onObscuredToggle == null
            ? null
            : IconButton(
                tooltip: obscureText ? 'Show password' : 'Hide password',
                icon: Icon(
                  obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: AuthTheme.inkMid,
                  size: 22,
                ),
                onPressed: onObscuredToggle,
              ),
      ),
    );
  }

  Widget _termsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: _model.termsAccepted,
            onChanged: (v) => setState(() => _model.termsAccepted = v ?? false),
            activeColor: AuthTheme.gold,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: RichText(
              text: TextSpan(
                style: AuthTheme.checkboxLabelStyle,
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AuthTheme.checkboxLabelStyle.copyWith(
                      color: AuthTheme.gold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _termsTap,
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AuthTheme.checkboxLabelStyle.copyWith(
                      color: AuthTheme.gold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _privacyTap,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _primaryButton(String label, VoidCallback? onPressed) {
    return Material(
      color: _model.isLoading ? AuthTheme.goldDark : AuthTheme.gold,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _model.isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          alignment: Alignment.center,
          child: Text(label, style: AuthTheme.primaryButtonStyle),
        ),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    if (!_model.termsAccepted) {
      AppToast.info(context, 'Please accept the Terms of Service and Privacy Policy');
      return;
    }

    final name = _model.nameTextController.text.trim();
    final email = _model.emailTextController.text.trim();
    final password = _model.passwordTextController.text;
    final confirmPassword = _model.confirmPasswordTextController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      AppToast.info(context, 'Please fill in all fields');
      return;
    }

    final passwordError = _getPasswordValidationError(password);
    if (passwordError != null) {
      AppToast.info(context, passwordError);
      return;
    }

    if (password != confirmPassword) {
      AppToast.info(context, 'Passwords do not match.');
      return;
    }

    final currentDeviceId = await SupabaseService.getDeviceId();
    debugPrint('Current device id: $currentDeviceId');
    if (currentDeviceId != null && currentDeviceId.isNotEmpty) {
      final alreadyRegistered =
          await SupabaseService.doesDeviceIdExistInDeviceInfo(currentDeviceId);
      if (alreadyRegistered) {
        if (mounted) {
          AppToast.info(
            context,
            'This device is already registered. Please log in instead.',
          );
        }
        return;
      }
    }

    setState(() => _model.isLoading = true);

    try {
      final response = await authRepository.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      debugPrint('Sign up response: $response');

      if (response.user != null && mounted) {
        Future<void>(() async {
          try {
            await SupabaseService.ensureUserProfileFromAuth(overrideName: name);
          } catch (_) {}
          try {
            await TimezoneSyncService.syncIfNeeded();
          } catch (_) {}
        });

        String message =
            'Account created! We emailed you a verification code. Please check your email and enter the verification code below.';
        var toastType = ToastType.success;
        try {
          await authRepository.sendEmailOtp(email: email);
        } catch (e) {
          final errorText = e.toString();
          if (errorText.contains('over_email_send_rate_limit') ||
              errorText.contains('429')) {
            message =
                'Account created! We emailed you a verification code. Please check your email and enter the verification code below.';
          } else {
            message =
                'Account created, but we could not send a new code. Please check your email or try again shortly.';
            toastType = ToastType.info;
          }
        }

        AppToast.show(
          context,
          message,
          type: toastType,
          duration: const Duration(seconds: 45),
        );

        context.go('/verifyEmailOtp?email=$email');
      }
    } catch (e) {
      if (mounted) {
        if (authRepository.isEmailAlreadyRegisteredError(e)) {
          AppToast.info(
            context,
            'This email is already registered. Please sign in instead.',
          );
          context.go('/login');
        } else {
          AppToast.error(context, 'Error: ${e.toString()}');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _model.isLoading = false);
      }
    }
  }

  Widget _divider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: AuthTheme.stone)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or continue with', style: AuthTheme.dividerTextStyle),
        ),
        Expanded(child: Container(height: 1, color: AuthTheme.stone)),
      ],
    );
  }

  Widget _socialButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleAppleSignIn(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              side: const BorderSide(color: AuthTheme.stone),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AuthTheme.surface,
              foregroundColor: AuthTheme.inkMid,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apple, size: 20, color: AuthTheme.inkMid),
                const SizedBox(width: 8),
                Text('Apple', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AuthTheme.inkMid)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _handleGoogleSignIn(),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              side: const BorderSide(color: AuthTheme.stone),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: AuthTheme.surface,
              foregroundColor: AuthTheme.inkMid,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const GoogleLogoIcon(size: 20),
                const SizedBox(width: 8),
                Text('Google', style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w500, color: AuthTheme.inkMid)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer(String text, String linkText, VoidCallback onTap) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(text, style: AuthTheme.footerStyle),
          Pressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: Text(linkText, style: AuthTheme.footerLinkStyle),
        ),
      ),
        ],
      ),
    );
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await authRepository.signInWithApple();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Apple sign in error: ${e.toString()}');
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await authRepository.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Google sign in error: ${e.toString()}');
      }
    }
  }
}
