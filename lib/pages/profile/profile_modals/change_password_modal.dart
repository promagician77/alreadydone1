import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/supabase_service.dart';
import 'shared.dart';

/// Change Password modal. If [verifiedPassword] is provided, skips current password field.
void showChangePasswordModal(
  BuildContext context, {
  String? verifiedPassword,
  ValueChanged<Map<String, String>>? onUpdate,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _ChangePasswordSheet(
      verifiedPassword: verifiedPassword,
      onUpdate: onUpdate ?? (_) {},
    ),
  );
}

bool _isValidPassword(String pw) {
  if (pw.length < 8) return false;
  final hasLetter = pw.contains(RegExp(r'[a-zA-Z]'));
  final hasDigit = pw.contains(RegExp(r'[0-9]'));
  return hasLetter && hasDigit;
}

class _ChangePasswordSheet extends StatefulWidget {
  final String? verifiedPassword;
  final ValueChanged<Map<String, String>> onUpdate;

  const _ChangePasswordSheet({
    required this.onUpdate,
    this.verifiedPassword,
  });

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool get _hasVerifiedPassword => widget.verifiedPassword != null && widget.verifiedPassword!.isNotEmpty;

  Future<void> _handleUpdate() async {
    final current = _hasVerifiedPassword ? widget.verifiedPassword! : _currentController.text.trim();
    final newPw = _newController.text;
    final confirm = _confirmController.text;

    if (current.isEmpty && !_hasVerifiedPassword) {
      AppToast.error(context, 'Enter your current password');
      return;
    }
    if (newPw.isEmpty) {
      AppToast.error(context, 'Enter a new password');
      return;
    }
    if (!_isValidPassword(newPw)) {
      AppToast.error(context, 'New password must be at least 8 characters with letters and numbers');
      return;
    }
    if (newPw != confirm) {
      AppToast.error(context, 'New passwords do not match');
      return;
    }

    setState(() => _saving = true);
    try {
      await SupabaseService.updatePassword(
        currentPassword: current,
        newPassword: newPw,
      );
      if (!mounted) return;
      widget.onUpdate({'current': current, 'new': newPw});
      AppToast.success(context, 'Password updated successfully');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst(RegExp(r'^Exception: '), '');
      if (msg.toLowerCase().contains('invalid') && msg.toLowerCase().contains('credentials')) {
        AppToast.error(context, 'Current password is incorrect');
      } else if (msg.toLowerCase().contains('email') || msg.contains('signed in')) {
        AppToast.error(context, 'You must be signed in to change your password');
      } else {
        AppToast.error(context, msg.isEmpty ? 'Failed to update password' : msg);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static InputDecoration _inputDecoration({bool gold = false}) => InputDecoration(
        filled: true,
        fillColor: ModalColors.warmWhite,
        hintText: '••••••••',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold ? ModalColors.gold : ModalColors.stone, width: gold ? 2 : 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: gold ? ModalColors.gold : ModalColors.stone, width: gold ? 2 : 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return Container(
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
                      title: 'Change Password',
                      subtitle: 'Enter your new password',
                    ),
                    const SizedBox(height: 20),
                    if (!_hasVerifiedPassword) ...[
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
                        controller: _currentController,
                        obscureText: true,
                        enabled: !_saving,
                        decoration: _inputDecoration(),
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ModalColors.ink,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'New Password',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newController,
                      obscureText: true,
                      enabled: !_saving,
                      decoration: _inputDecoration(gold: true),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ModalColors.ink,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Confirm New Password',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: ModalColors.inkMid,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmController,
                      obscureText: true,
                      enabled: !_saving,
                      decoration: _inputDecoration(gold: true),
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ModalColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Must be at least 8 characters with a mix of letters and numbers',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: ModalColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildActionButtons(
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: _handleUpdate,
                      saveLabel: 'Update Password',
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
