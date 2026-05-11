import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart' show SupabaseService;
import '/pages/tutorial/tutorial_widget.dart';
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
  State<EmailVerificationWidget> createState() =>
      _EmailVerificationWidgetState();
}

class _EmailVerificationWidgetState extends State<EmailVerificationWidget> {
  late EmailVerificationModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  void _onCodeFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => EmailVerificationModel());
    _model.codeFocusNode.addListener(_onCodeFocusChanged);
  }

  @override
  void dispose() {
    _model.codeFocusNode.removeListener(_onCodeFocusChanged);
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
                          onPressed: _model.isLoading
                              ? null
                              : () => context.go(
                                    widget.isEmailChange
                                        ? '/profile'
                                        : '/signUp',
                                  ),
                          child: Text(
                            widget.isEmailChange
                                ? 'Back to profile'
                                : 'Back to sign up',
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
            await BackendClient.updateUserProfile(widget.userId!,
                email: widget.email);
          } catch (_) {}
        }
        if (!widget.isEmailChange) {
          try {
            await SupabaseService.ensureUserProfileFromAuth();
          } catch (_) {}
          try {
            await SupabaseService.upsertDeviceInfoForCurrentUser();
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
              widget.isEmailChange ? '/' : OnboardingTutorialWidget.routePath);
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
