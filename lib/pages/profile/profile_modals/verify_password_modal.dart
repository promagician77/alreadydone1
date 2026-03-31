import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/supabase_service.dart';
import 'shared.dart';

/// Verify current password before allowing email or password update.
/// On success, calls [onVerified] with the password and pops.
Future<T?> showVerifyPasswordModal<T>(
  BuildContext context, {
  required String purpose,
  required Future<void> Function(String verifiedPassword) onVerified,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _VerifyPasswordSheet(
      purpose: purpose,
      onVerified: onVerified,
    ),
  );
}

class _VerifyPasswordSheet extends StatefulWidget {
  final String purpose;
  final Future<void> Function(String verifiedPassword) onVerified;

  const _VerifyPasswordSheet({
    required this.purpose,
    required this.onVerified,
  });

  @override
  State<_VerifyPasswordSheet> createState() => _VerifyPasswordSheetState();
}

class _VerifyPasswordSheetState extends State<_VerifyPasswordSheet> {
  final _passwordController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      AppToast.info(context, 'Please enter your current password');
      return;
    }

    final email = SupabaseService.currentUser?.email;
    if (email == null || email.isEmpty) {
      AppToast.error(context, 'You must be signed in');
      return;
    }

    setState(() => _verifying = true);
    try {
      await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      await widget.onVerified(password);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid') && msg.contains('credentials')) {
        AppToast.error(context, 'Current password is incorrect');
      } else if (msg.contains('email') || msg.contains('signed in')) {
        AppToast.error(context, 'You must be signed in');
      } else {
        AppToast.error(context, 'Verification failed. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Material(
      color: Colors.transparent,
      child: AnimatedPadding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, media.padding.bottom + 40),
              decoration: const BoxDecoration(
                color: ModalColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x261C1917),
                    blurRadius: 20,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: AbsorbPointer(
                absorbing: _verifying,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSheetHeader(
                      title: 'Verify Identity',
                      subtitle:
                          'Enter your current password to ${widget.purpose}',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Current Password',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !_verifying,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ModalColors.warmWhite,
                        hintText: '••••••••',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: ModalColors.stone, width: 1.5),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: ModalColors.stone, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ModalColors.ink,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildActionButtons(
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: _handleVerify,
                      saveLabel: 'Continue',
                      saving: _verifying,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
