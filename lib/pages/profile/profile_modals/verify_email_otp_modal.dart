import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/backend_client.dart';
import '/services/supabase_service.dart';
import 'shared.dart';

/// Verify 8-digit OTP for email change. On success, updates Supabase Auth and backend Users table.
Future<T?> showVerifyEmailOtpModal<T>(
  BuildContext context, {
  required String newEmail,
  required int userId,
  ValueChanged<String>? onSuccess,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    isDismissible: false,
    builder: (ctx) => _VerifyEmailOtpSheet(
      newEmail: newEmail,
      userId: userId,
      onSuccess: onSuccess,
    ),
  );
}

class _VerifyEmailOtpSheet extends StatefulWidget {
  final String newEmail;
  final int userId;
  final ValueChanged<String>? onSuccess;

  const _VerifyEmailOtpSheet({
    required this.newEmail,
    required this.userId,
    this.onSuccess,
  });

  @override
  State<_VerifyEmailOtpSheet> createState() => _VerifyEmailOtpSheetState();
}

class _VerifyEmailOtpSheetState extends State<_VerifyEmailOtpSheet> {
  final _otpController = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim().replaceAll(RegExp(r'\s'), '');
    if (otp.length < 6 || otp.length > 8) {
      AppToast.info(context, 'Please enter the 8-digit code from your email');
      return;
    }

    setState(() => _verifying = true);
    try {
      await SupabaseService.verifyEmailChangeOtp(
        email: widget.newEmail,
        token: otp,
      );
      if (!mounted) return;

      try {
        await BackendClient.updateUserProfile(widget.userId, email: widget.newEmail);
      } catch (_) {}

      if (!mounted) return;
      widget.onSuccess?.call(widget.newEmail);
      Navigator.of(context).pop(widget.newEmail);
      AppToast.success(context, 'Email updated successfully!');
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '');
      AppToast.error(context, msg.isEmpty ? 'Invalid or expired code' : msg);
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
                      title: 'Verify Your Email',
                      subtitle:
                          'Enter the 8-digit code sent to ${widget.newEmail}',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Verification Code',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _otpController,
                      enabled: !_verifying,
                      maxLength: 8,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ModalColors.warmWhite,
                        hintText: '00000000',
                        counterText: '',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: ModalColors.gold, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: ModalColors.gold, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.ink,
                        letterSpacing: 4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check your inbox at ${widget.newEmail} for the code',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: ModalColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildActionButtons(
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: _handleVerify,
                      saveLabel: 'Verify',
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
