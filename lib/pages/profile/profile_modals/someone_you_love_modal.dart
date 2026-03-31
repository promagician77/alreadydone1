import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/backend_client.dart';
import 'shared.dart';

/// Someone You Love modal. Calls PATCH /api/users/{user_id} with lovedOne on Save.
Future<T?> showSomeoneYouLoveModal<T>(
  BuildContext context, {
  required int userId,
  required String currentValue,
  ValueChanged<String>? onSave,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => SomeoneYouLoveSheet(
      userId: userId,
      currentValue: currentValue,
      onSave: onSave,
    ),
  );
}

class SomeoneYouLoveSheet extends StatefulWidget {
  const SomeoneYouLoveSheet({
    super.key,
    required this.userId,
    required this.currentValue,
    this.onSave,
  });

  final int userId;
  final String currentValue;
  final ValueChanged<String>? onSave;

  @override
  State<SomeoneYouLoveSheet> createState() => _SomeoneYouLoveSheetState();
}

class _SomeoneYouLoveSheetState extends State<SomeoneYouLoveSheet> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue == '—' ? '' : widget.currentValue);
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
                      title: 'Someone You Love',
                      subtitle:
                          'A special person to include in your stories (optional)',
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _controller,
                      enabled: !_saving,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: ModalColors.warmWhite,
                        hintText: 'First name (optional)',
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
                      '"...and ${_controller.text.isEmpty ? "..." : _controller.text} was there, smiling..." — adds emotional depth to your manifestations',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        color: ModalColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: GestureDetector(
                        onTap: _saving
                            ? null
                            : () {
                                _controller.clear();
                                setState(() {});
                              },
                        child: Text(
                          'Clear (leave empty)',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: ModalColors.inkSoft,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    buildActionButtons(
                      onCancel: () => Navigator.of(context).pop(),
                      onSave: () async {
                        final value = _controller.text.trim().isEmpty
                            ? '—'
                            : _controller.text.trim();
                        setState(() => _saving = true);
                        try {
                          await BackendClient.updateUserProfile(
                            widget.userId,
                            someoneYouLove: value,
                          );
                          if (!mounted) return;
                          widget.onSave?.call(value);
                          Navigator.of(context).pop(value);
                        } catch (e) {
                          if (!mounted) return;
                          setState(() => _saving = false);
                          AppToast.error(
                            context,
                            'Failed to update: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
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
