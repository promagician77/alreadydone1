import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/theme/auth_theme.dart';
import '/core/network/backend_client.dart';
import '/core/di/auth_locator.dart';
import '/shared/services/supabase_service.dart' show SupabaseService;
import '/features/onboarding/presentation/pages/onboarding/onboarding_origin_splash_widget.dart';
import '/shared/services/app_toast.dart';
import 'email_verification_model.dart';
export 'email_verification_model.dart';

class EmailVerificationWidget extends StatefulWidget {
  const EmailVerificationWidget({
    super.key,
    required this.email,
    this.isEmailChange = false,
    this.isPasswordRecovery = false,
    this.userId,
  });

  final String email;
  final bool isEmailChange;
  final bool isPasswordRecovery;
  final int? userId;

  static String routeName = 'EmailVerification';
  static String routePath = '/verifyEmailOtp';

  @override
  State<EmailVerificationWidget> createState() =>
      _EmailVerificationWidgetState();
}

class _EmailVerificationWidgetState extends State<EmailVerificationWidget> {
  late EmailVerificationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();
  int _previousCodeLength = 0;

  void _onCodeFocusChanged() {
    if (mounted) setState(() {});
  }

  void _onCodeChanged() {
    final length = _model.codeTextController.text.length;
    if (!widget.isPasswordRecovery &&
        !_model.isLoading &&
        length == _codeDigitCount &&
        _previousCodeLength < _codeDigitCount) {
      FocusScope.of(context).unfocus();
      _handleVerify();
    }
    _previousCodeLength = length;
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailVerificationModel());
    _model.codeFocusNode.addListener(_onCodeFocusChanged);
    _model.codeTextController.addListener(_onCodeChanged);
  }

  @override
  void dispose() {
    _model.codeFocusNode.removeListener(_onCodeFocusChanged);
    _model.codeTextController.removeListener(_onCodeChanged);
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
                    onPressed: _handleBack,
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
                      Text(
                        _titleText,
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _subtitleText,
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeSubStyle,
                      ),
                      const SizedBox(height: 24),
                      if (widget.isPasswordRecovery) ...[
                        _label('Verification code'),
                        const SizedBox(height: 6),
                        _codeInput(),
                        const SizedBox(height: 16),
                        _label('New password'),
                        const SizedBox(height: 6),
                        _passwordInput(
                          controller: _model.passwordTextController,
                          focusNode: _model.passwordFocusNode,
                          hint: '8+ chars, upper/lower, number, symbol',
                          obscureText: _model.obscurePassword,
                          onObscuredToggle: () => setState(
                            () => _model.obscurePassword = !_model.obscurePassword,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _label('Confirm password'),
                        const SizedBox(height: 6),
                        _passwordInput(
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
                        _primaryButton('Reset password', _handlePasswordRecovery),
                      ] else ...[
                        _label('Verification code'),
                        const SizedBox(height: 6),
                        _codeInput(),
                        const SizedBox(height: 16),
                        _primaryButton('Verify', _handleVerify),
                      ],
                      if (_model.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AuthTheme.gold),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed:
                              _model.isLoading ? null : _handleResendCode,
                          child: Text(
                            'Resend code',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AuthTheme.gold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: _model.isLoading ? null : _handleBack,
                          child: Text(
                            _backLinkLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AuthTheme.gold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ),
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

  String get _backRoute {
    if (widget.isEmailChange) return '/profile';
    if (widget.isPasswordRecovery) return '/passwordReset';
    return '/signUp';
  }

  String get _backLinkLabel {
    if (widget.isEmailChange) return 'Back to profile';
    if (widget.isPasswordRecovery) return 'Back to reset password';
    return 'Back to sign up';
  }

  String get _titleText {
    if (widget.isPasswordRecovery) return 'Reset your password';
    return 'Verify your email';
  }

  String get _subtitleText {
    if (widget.isPasswordRecovery) {
      return 'Enter the 8-digit code and your new password for\n${widget.email}';
    }
    return 'Enter the verification code we sent to\n${widget.email}';
  }

  Future<void> _handleBack() async {
    if (widget.isPasswordRecovery && authRepository.isAuthenticated) {
      try {
        await authRepository.signOut();
      } catch (_) {}
    }
    if (!mounted) return;
    context.go(_backRoute);
  }

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

  static const int _codeDigitCount = 8;
  static const double _codeBoxGap = 8;

  int _activeCodeSlot(String text, TextSelection selection, bool hasFocus) {
    if (!hasFocus || !selection.isValid) return 0;
    final o = selection.baseOffset;
    if (o >= text.length) {
      return text.length.clamp(0, _codeDigitCount - 1);
    }
    return o.clamp(0, _codeDigitCount - 1);
  }

  void _focusCodeSlot(int slotIndex) {
    _model.codeFocusNode.requestFocus();
    final t = _model.codeTextController.text;
    final offset = slotIndex > t.length ? t.length : slotIndex;
    _model.codeTextController.selection = TextSelection.collapsed(offset: offset);
    setState(() {});
  }

  Widget _codeInput() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _model.codeTextController,
      builder: (context, value, _) {
        final text = value.text;
        final selection = value.selection;
        final hasFocus = _model.codeFocusNode.hasFocus;
        final activeSlot = _activeCodeSlot(text, selection, hasFocus);

        return SizedBox(
          height: 52,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: TextField(
                  controller: _model.codeTextController,
                  focusNode: _model.codeFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: _codeDigitCount,
                  style: AuthTheme.bodyStyle.copyWith(
                    color: Colors.transparent,
                    height: 1.2,
                  ),
                  cursorColor: Colors.transparent,
                  showCursor: false,
                  enableInteractiveSelection: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  autofillHints: const [AutofillHints.oneTimeCode],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(_codeDigitCount, (i) {
                  final char = i < text.length ? text[i] : '';
                  final isActive = hasFocus && activeSlot == i;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < _codeDigitCount - 1 ? _codeBoxGap : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => _focusCodeSlot(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          curve: Curves.easeOut,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AuthTheme.surface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive ? AuthTheme.gold : AuthTheme.stone,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Text(
                            char,
                            style: AuthTheme.bodyStyle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _passwordInput({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    required bool obscureText,
    required VoidCallback onObscuredToggle,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      style: AuthTheme.bodyStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: AuthTheme.placeholderStyle,
        filled: true,
        fillColor: AuthTheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.stone),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AuthTheme.gold),
        ),
        suffixIcon: IconButton(
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

  Future<void> _handleVerify() async {
    final code = _model.codeTextController.text.trim();

    if (code.length < 6 || code.length > 8) {
      AppToast.info(context, 'Please enter the 6–8 digit code from your email');
      return;
    }

    setState(() => _model.isLoading = true);

    try {
      final response = widget.isEmailChange
          ? await authRepository.verifyEmailChangeOtp(
              email: widget.email,
              token: code,
            )
          : await authRepository.verifyEmailOtp(
              email: widget.email,
              token: code,
            );

      if (response.user != null && mounted) {
        if (widget.isEmailChange && widget.userId != null) {
          try {
            await BackendClient.updateUserProfile(widget.userId!,
                email: widget.email);
          } catch (_) {}
        }
        if (!widget.isEmailChange) {
          try {
            await SupabaseService.ensureUserProfileFromAuth();
          } catch (_) {}
          try {
            await SupabaseService.upsertDeviceInfoForCurrentUser(
              emailHint: response.user?.email ?? widget.email,
            );
          } catch (_) {}
        }
        if (mounted) {
          AppToast.success(
            context,
            widget.isEmailChange
                ? 'Email updated successfully!'
                : 'Email verified! Welcome.',
          );
          context.go(
              widget.isEmailChange ? '/' : OnboardingOriginSplashWidget.routePath);
        }
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        AppToast.error(context, msg.isEmpty ? 'Verification failed' : msg);
      }
    } finally {
      if (mounted) {
        setState(() => _model.isLoading = false);
      }
    }
  }

  Future<void> _handlePasswordRecovery() async {
    final code = _model.codeTextController.text.trim();
    final password = _model.passwordTextController.text;
    final confirmPassword = _model.confirmPasswordTextController.text;

    if (code.length < 6 || code.length > 8) {
      AppToast.info(context, 'Please enter the 8-digit code from your email');
      return;
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      AppToast.info(context, 'Please enter and confirm your new password');
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

    setState(() => _model.isLoading = true);

    try {
      final response = await authRepository.verifyRecoveryOtp(
        email: widget.email,
        token: code,
      );
      if (response.user == null) {
        throw Exception('Invalid or expired code');
      }

      await authRepository.completePasswordRecovery(newPassword: password);

      if (mounted) {
        AppToast.success(
          context,
          'Password updated! Please sign in with your new password.',
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        AppToast.error(context, msg.isEmpty ? 'Could not reset password' : msg);
      }
    } finally {
      if (mounted) {
        setState(() => _model.isLoading = false);
      }
    }
  }

  Future<void> _handleResendCode() async {
    setState(() => _model.isLoading = true);

    try {
      if (widget.isPasswordRecovery) {
        await authRepository.resetPasswordForEmail(widget.email);
      } else if (widget.isEmailChange) {
        await authRepository.updateUserEmail(widget.email);
      } else {
        await authRepository.sendEmailOtp(email: widget.email);
      }
      if (mounted) {
        AppToast.success(context, 'A new code has been sent to your email.');
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
        AppToast.error(context, msg.isEmpty ? 'Failed to resend code' : msg);
      }
    } finally {
      if (mounted) {
        setState(() => _model.isLoading = false);
      }
    }
  }
}
