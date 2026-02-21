import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/pages/auth/auth_theme.dart';
import '/services/supabase_service.dart' show SupabaseService, OAuthProvider;
import '/flutter_flow/nav/nav.dart';
import 'sign_up_model.dart';
export 'sign_up_model.dart';

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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SignUpModel());
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
              const AuthStatusBar(),
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
                            const TextSpan(text: 'Your dream life.\n'),
                            TextSpan(text: 'Already', style: AuthTheme.welcomeTitleItalicStyle),
                            const TextSpan(text: ' here.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
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
                        hint: 'At least 8 characters',
                        obscureText: true,
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

  Widget _input({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
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
                  TextSpan(text: 'Terms of Service', style: AuthTheme.checkboxLabelStyle.copyWith(color: AuthTheme.gold, decoration: TextDecoration.underline)),
                  const TextSpan(text: ' and '),
                  TextSpan(text: 'Privacy Policy', style: AuthTheme.checkboxLabelStyle.copyWith(color: AuthTheme.gold, decoration: TextDecoration.underline)),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service and Privacy Policy')),
      );
      return;
    }

    final name = _model.nameTextController.text.trim();
    final email = _model.emailTextController.text.trim();
    final password = _model.passwordTextController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters')),
      );
      return;
    }

    setState(() => _model.isLoading = true);

    try {
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        fullName: name,
      );

      if (response.user != null) {
        if (mounted) {
          // Check if user is authenticated (email confirmation disabled) or needs email verification
          if (SupabaseService.isAuthenticated) {
            // Email confirmation disabled - user is immediately authenticated
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created successfully! Welcome!')),
            );
            context.go('/');
          } else {
            // Email confirmation enabled - user needs to verify email
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Account created! Please check your email to verify your account.')),
            );
            context.go('/login');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
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
          GestureDetector(onTap: onTap, child: Text(linkText, style: AuthTheme.footerLinkStyle)),
        ],
      ),
    );
  }

  Future<void> _handleAppleSignIn() async {
    try {
      await SupabaseService.signInWithOAuth(provider: OAuthProvider.apple);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Apple sign in error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      await SupabaseService.signInWithOAuth(provider: OAuthProvider.google);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign in error: ${e.toString()}')),
        );
      }
    }
  }
}
