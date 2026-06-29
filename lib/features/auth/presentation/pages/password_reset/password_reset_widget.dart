import 'package:flutter/material.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/shared/theme/auth_theme.dart';
import '/core/di/auth_locator.dart';
import '/shared/services/app_toast.dart';
import '/shared/widgets/pressable.dart';
import '/features/auth/presentation/pages/email_verification/email_verification_widget.dart';
import 'password_reset_model.dart';
export 'password_reset_model.dart';

class PasswordResetWidget extends StatefulWidget {
  const PasswordResetWidget({super.key, this.initialEmail});

  /// When opened from sign-up (or elsewhere) with `?email=`, pre-fills the field.
  final String? initialEmail;

  static String routeName = 'PasswordReset';
  static String routePath = '/passwordReset';

  @override
  State<PasswordResetWidget> createState() => _PasswordResetWidgetState();
}

class _PasswordResetWidgetState extends State<PasswordResetWidget> {
  late PasswordResetModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PasswordResetModel());
    final prefill = widget.initialEmail?.trim();
    if (prefill != null && prefill.isNotEmpty) {
      _model.emailTextController.text = prefill;
    }
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
                      const Center(child: KeyIcon()),
                      const SizedBox(height: 20),
                      Text(
                        'Reset your\npassword',
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "We'll email you an 8-digit code to reset your password",
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeSubStyle,
                      ),
                      const SizedBox(height: 24),
                      _label('Email Address'),
                      const SizedBox(height: 6),
                      _input(
                        controller: _model.emailTextController,
                        focusNode: _model.emailFocusNode,
                        hint: 'jordan@example.com',
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 8),
                      _primaryButton('Send reset code', _handlePasswordReset),
                      if (_model.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Center(child: CircularProgressIndicator(color: AuthTheme.gold)),
                        ),
                      const SizedBox(height: 32),
                      _footer('Remember your password? ', 'Log in', () => context.go('/login')),
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

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
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

  Future<void> _handlePasswordReset() async {
    final email = _model.emailTextController.text.trim();

    if (email.isEmpty) {
      AppToast.info(context, 'Please enter your email address');
      return;
    }

    setState(() => _model.isLoading = true);

    try {
      await authRepository.resetPasswordForEmail(email);

      if (mounted) {
        AppToast.success(
          context,
          'Reset code sent! Check your email for the 8-digit code.',
        );
        context.go(
          '${EmailVerificationWidget.routePath}?email=${Uri.encodeQueryComponent(email)}&recovery=1',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _model.isLoading = false);
      }
    }
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
}
