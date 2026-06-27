import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:go_router/go_router.dart';

import '/flutter_flow/nav/nav.dart';
import '/services/app_toast.dart';
import '/core/di/auth_locator.dart';
import '/shared/widgets/modal_kit.dart';
import 'verify_email_otp_modal.dart';

/// Change Email modal. Uses Supabase Auth updateUser to send verification to new email.
Future<T?> showChangeEmailModal<T>(
  BuildContext context, {
  required int userId,
  required String currentEmail,
  ValueChanged<String>? onSave,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => ChangeEmailSheet(
      userId: userId,
      currentEmail: currentEmail,
      onSave: onSave,
    ),
  );
}

class ChangeEmailSheet extends StatefulWidget {
  const ChangeEmailSheet({
    super.key,
    required this.userId,
    required this.currentEmail,
    this.onSave,
  });

  final int userId;
  final String currentEmail;
  final ValueChanged<String>? onSave;

  @override
  State<ChangeEmailSheet> createState() => _ChangeEmailSheetState();
}

class _ChangeEmailSheetState extends State<ChangeEmailSheet> {
  final _newEmailController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _newEmailController.dispose();
    super.dispose();
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
                absorbing: _saving,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildSheetHeader(
                      title: 'Change Email',
                      subtitle: 'Update your account email address',
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Current Email',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: ModalColors.stone,
                        border: Border.all(color: ModalColors.stoneMid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.currentEmail,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: ModalColors.inkSoft,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Email Address',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newEmailController,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ModalColors.warmWhite,
                        hintText: 'your.new@email.com',
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
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ModalColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "We'll send an 8-digit verification code to your new email address",
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: ModalColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildActionButtons(
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: () async {
                        final email = _newEmailController.text.trim();
                        if (email.isEmpty) {
                          AppToast.info(context, 'Please enter a new email address');
                          return;
                        }
                        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(email)) {
                          AppToast.info(context, 'Please enter a valid email address');
                          return;
                        }
                        if (widget.currentEmail.isNotEmpty &&
                            email.toLowerCase() ==
                                widget.currentEmail.toLowerCase()) {
                          AppToast.info(
                              context, 'New email must be different from current');
                          return;
                        }
                        setState(() => _saving = true);
                        try {
                          await authRepository.updateUserEmail(email);
                          if (!mounted) return;
                          final overlayCtx = Navigator.of(context).overlay?.context;
                          final userId = widget.userId;
                          final onSave = widget.onSave;
                          Navigator.of(context).pop();
                          if (overlayCtx != null && overlayCtx.mounted) {
                            await showVerifyEmailOtpModal(
                              overlayCtx,
                              newEmail: email,
                              userId: userId,
                              onSuccess: onSave,
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _saving = false);
                          final msg = e
                              .toString()
                              .replaceFirst(RegExp(r'^Exception:?\s*'), '');
                          AppToast.error(
                            context,
                            msg.isEmpty ? 'Failed to send verification' : msg,
                          );
                        }
                      },
                      saveLabel: 'Send Verification',
                      saving: _saving,
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
