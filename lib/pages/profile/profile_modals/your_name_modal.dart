import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/backend_client.dart';
import 'shared.dart';

/// Your Name modal. Calls PATCH /api/users/{user_id} with the name on Save.
Future<T?> showYourNameModal<T>(
  BuildContext context, {
  required int userId,
  required String currentName,
  ValueChanged<String>? onSave,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => YourNameSheet(
      userId: userId,
      currentName: currentName,
      onSave: onSave,
    ),
  );
}

class YourNameSheet extends StatefulWidget {
  const YourNameSheet({
    super.key,
    required this.userId,
    required this.currentName,
    this.onSave,
  });

  final int userId;
  final String currentName;
  final ValueChanged<String>? onSave;

  @override
  State<YourNameSheet> createState() => _YourNameSheetState();
}

class _YourNameSheetState extends State<YourNameSheet> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName == '—' ? '' : widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
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
                      title: 'Your First Name',
                      subtitle: 'Used to personalize your stories',
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controller,
                      enabled: !_saving,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ModalColors.warmWhite,
                        hintText: 'Your first name',
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
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: ModalColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "This is how you'll be addressed in your manifestation stories",
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
                        final name = _controller.text.trim();
                        if (name.isEmpty) {
                          AppToast.info(context, 'Please enter your name');
                          return;
                        }
                        setState(() => _saving = true);
                        try {
                          await BackendClient.updateUserProfile(
                            widget.userId,
                            name: name,
                          );
                          if (!mounted) return;
                          widget.onSave?.call(name);
                          Navigator.of(context).pop(name);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _saving = false);
                          AppToast.error(
                            context,
                            'Failed to update name: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
                          );
                        }
                      },
                      saveLabel: 'Save',
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
