import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart' show SupabaseService;
import '/flutter_flow/nav/nav.dart';
import '/pages/onboarding/onboarding_origin_splash_widget.dart';
import '/services/app_toast.dart';
import 'email_verification_model.dart';
export 'email_verification_model.dart';

class EmailVerificationWidget extends StatefulWidget {
  const EmailVerificationWidget({
    super.key,
    required this.email,
    this.isEmailChange = false,
    this.userId,
  });

  final String email;
  final bool isEmailChange;
  final int? userId;

  static String routeName = 'EmailVerification';
  static String routePath = '/verifyEmailOtp';

  @override
  State<EmailVerificationWidget> createState() => _EmailVerificationWidgetState();
}

class _EmailVerificationWidgetState extends State<EmailVerificationWidget> {
  late EmailVerificationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailVerificationModel());
  }

  @override
  void dispose() {
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
                    onPressed: () => context.go(
                      widget.isEmailChange ? '/profile' : '/signUp',
                    ),
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
                        'Verify your email',
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the verification code we sent to\n${widget.email}',
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeSubStyle,
                      ),
                      const SizedBox(height: 24),
                      _label('Verification code'),
                      const SizedBox(height: 6),
                      _codeInput(),
                      const SizedBox(height: 16),
                      _primaryButton('Verify', _handleVerify),
                      if (_model.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: AuthTheme.gold),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _model.isLoading ? null : _handleResendCode,
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

  Widget _codeInput() {
    return TextFormField(
      controller: _model.codeTextController,
      focusNode: _model.codeFocusNode,
      keyboardType: TextInputType.number,
      maxLength: 8,
      style: AuthTheme.bodyStyle.copyWith(
        letterSpacing: 4,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: '••••••••',
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
          ? await SupabaseService.verifyEmailChangeOtp(
              email: widget.email,
              token: code,
            )
          : await SupabaseService.verifyEmailOtp(
              email: widget.email,
              token: code,
            );

      if (response.user != null && mounted) {
        if (widget.isEmailChange && widget.userId != null) {
          try {
            await BackendClient.updateUserProfile(widget.userId!, email: widget.email);
          } catch (_) {}
        }
        if (mounted) {
          AppToast.success(
            context,
            widget.isEmailChange ? 'Email updated successfully!' : 'Email verified! Welcome.',
          );
          context.go(widget.isEmailChange ? '/' : OnboardingOriginSplashWidget.routePath);
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

  Future<void> _handleResendCode() async {
    setState(() => _model.isLoading = true);

    try {
      if (widget.isEmailChange) {
        await SupabaseService.updateUserEmail(widget.email);
      } else {
        await SupabaseService.sendEmailOtp(email: widget.email);
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

