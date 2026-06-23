import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';

import '/services/supabase_service.dart';
import '/services/timezone_sync_service.dart';
import '/services/app_toast.dart';

import '/widgets/pressable.dart';

import '/pages/auth/auth_theme.dart';
import '/pages/password_reset/password_reset_widget.dart';

import 'login_model.dart';
export 'login_model.dart';

class LoginWidget extends StatefulWidget {
  const LoginWidget({super.key});

  static String routeName = 'Login';
  static String routePath = '/login';

  @override
  State<LoginWidget> createState() => _LoginWidgetState();
}

class _LoginWidgetState extends State<LoginWidget> {
  late LoginModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginModel());
    _loadWelcomeBackState();
  }

  Future<void> _loadWelcomeBackState() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSignedInBefore = prefs.getBool('user_has_signed_in_once') ?? false;
    if (mounted) setState(() => _model.userHasSignedInBefore = hasSignedInBefore);
  }

  bool _showWelcomeBack(BuildContext context) {
    return GoRouterState.of(context).uri.queryParameters['welcomeBack'] == 'true' ||
        _model.userHasSignedInBefore;
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
                        _showWelcomeBack(context)
                            ? 'Welcome Back'
                            : 'Sign in',
                        textAlign: TextAlign.center,
                        style: AuthTheme.welcomeTitleStyle,
                      ),
                      const SizedBox(height: 8),
                      Text('Your voice is ready for you', textAlign: TextAlign.center, style: AuthTheme.welcomeSubStyle),
                      const SizedBox(height: 24),
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
                        hint: 'Enter your password',
                        obscureText: _model.obscurePassword,
                        onObscuredToggle: () => setState(
                          () => _model.obscurePassword = !_model.obscurePassword,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Pressable(
                          onTap: _goToForgotPassword,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Text('Forgot password?', style: AuthTheme.forgotLinkStyle),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _primaryButton('Log In', _handleLogin),
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
                      _footer("Don't have an account? ", 'Sign up', () => context.go('/signUp')),
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
    bool obscureText = false,
    VoidCallback? onObscuredToggle,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
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

  void _goToForgotPassword() {
    final email = _model.emailTextController.text.trim();
    if (email.isNotEmpty) {
      context.go(
        '${PasswordResetWidget.routePath}?email=${Uri.encodeQueryComponent(email)}',
      );
    } else {
      context.go(PasswordResetWidget.routePath);
    }
  }

  Future<void> _handleLogin() async {
    final email = _model.emailTextController.text.trim();
    final password = _model.passwordTextController.text;

    if (email.isEmpty || password.isEmpty) {
      AppToast.info(context, 'Please fill in all fields');
      return;
    }

    setState(() => _model.isLoading = true);

    try {
      final response = await SupabaseService.signIn(email: email, password: password);

      debugPrint('Login response: $response');
      if (response.user != null && mounted) {
        AppToast.success(context, 'Welcome back!');
        context.go('/');
      }
      
    // After successful login, sync user's timezone with backend
    try {
      final didSync = await TimezoneSyncService.syncIfNeeded();
      debugPrint(didSync ? 'Timezone synced' : 'Timezone sync skipped');
    } catch (e) {
      debugPrint('[Login] Failed to sync timezone: $e');
    }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, _loginErrorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _model.isLoading = false);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await SupabaseService.signInWithApple();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, _socialSignInErrorMessage('Apple', e));
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await SupabaseService.signInWithGoogle();
    } catch (e) {
      if (mounted) {
        AppToast.error(context, _socialSignInErrorMessage('Google', e));
      }
    }
  }

  /// User-friendly message for email/password login errors (no raw exception text).
  String _loginErrorMessage(dynamic e) {
    if (e is AuthException) {
      final code = e.statusCode?.toString() ?? '';
      final msg = (e.message ?? '').toLowerCase();
      if (e.code == 'invalid_credentials' || msg.contains('invalid') && msg.contains('credential')) {
        return 'Invalid email or password.';
      }
      if (e.code == 'email_not_confirmed' || msg.contains('email not confirmed')) {
        return 'Please confirm your email address.';
      }
    }
    final s = e.toString().toLowerCase();
    if (s.contains('invalid') && (s.contains('credential') || s.contains('login'))) {
      return 'Invalid email or password.';
    }
    return 'Login failed. Please try again.';
  }

  /// User-friendly message for Apple/Google sign-in (no raw exception text).
  String _socialSignInErrorMessage(String provider, dynamic e) {
    return 'Could not sign in with $provider. Please try again.';
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
}
