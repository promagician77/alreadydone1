import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'shared.dart';

/// Reusable text input bottom sheet (used by Your Name modal).
class TextInputSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String initialValue;
  final String placeholder;
  final String hint;
  final ValueChanged<String> onSave;

  const TextInputSheet({
    super.key,
    required this.title,
    required this.subtitle,
    required this.initialValue,
    required this.placeholder,
    required this.hint,
    required this.onSave,
  });

  @override
  State<TextInputSheet> createState() => _TextInputSheetState();
}

class _TextInputSheetState extends State<TextInputSheet> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnimatedPadding(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSheetHeader(
                  title: widget.title,
                  subtitle: widget.subtitle,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: ModalColors.warmWhite,
                    hintText: widget.placeholder,
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
                  widget.hint,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: ModalColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                buildActionButtons(
                  onCancel: () => Navigator.of(context).pop(),
                  onSave: () {
                    widget.onSave(_controller.text.trim());
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
