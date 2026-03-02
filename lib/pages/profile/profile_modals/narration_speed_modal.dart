import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/backend_client.dart';
import 'shared.dart';

/// Narration Speed modal. Calls PATCH /api/users/{user_id} with the selected speed on Save.
Future<T?> showNarrationSpeedModal<T>(
  BuildContext context, {
  required int userId,
  required String currentSpeed,
  ValueChanged<String>? onSave,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => NarrationSpeedSheet(
      userId: userId,
      currentSpeed: currentSpeed,
      onSave: onSave,
    ),
  );
}

class NarrationSpeedSheet extends StatefulWidget {
  const NarrationSpeedSheet({
    super.key,
    required this.userId,
    required this.currentSpeed,
    this.onSave,
  });

  final int userId;
  final String currentSpeed;
  final ValueChanged<String>? onSave;

  @override
  State<NarrationSpeedSheet> createState() => _NarrationSpeedSheetState();
}

class _NarrationSpeedSheetState extends State<NarrationSpeedSheet> {
  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSpeed.toLowerCase();
    if (_selected != 'slow' && _selected != 'normal' && _selected != 'fast' && _selected != 'very_fast') {
      _selected = 'normal';
    }
  }

  @override
  Widget build(BuildContext context) {
    const options = [
      ('slow', 'Slow (0.85x)', 'Best for deep absorption and relaxation'),
      ('normal', 'Normal (1.0x)', 'Recommended for most users'),
      ('fast', 'Fast (1.15x)', 'Time-efficient manifestation'),
      ('very_fast', 'Very Fast (1.35x)', 'Quick daily practice'),
    ];
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 40),
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
            title: 'Narration Speed',
            subtitle: 'Choose your playback speed',
          ),
          const SizedBox(height: 20),
          ...options.map((o) {
            final (value, title, desc) = o;
            final isSelected = _selected == value;
            final isCurrent = value == widget.currentSpeed.toLowerCase();
            return AbsorbPointer(
              absorbing: _saving,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _selected = value),
                child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSelected ? ModalColors.goldPale : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? ModalColors.gold : ModalColors.stoneMid,
                          width: 2,
                        ),
                        color: isSelected ? ModalColors.gold : Colors.transparent,
                      ),
                      child: isSelected
                          ? Center(
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? ModalColors.goldDark : ModalColors.ink,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            desc,
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              color: ModalColors.inkSoft,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: ModalColors.goldPale,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Current',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: ModalColors.gold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            );
          }),
          const SizedBox(height: 20),
          buildActionButtons(
            onCancel: () => Navigator.of(context).pop(),
            onSave: () async {
                    setState(() => _saving = true);
                    try {
                      await BackendClient.updateUserProfile(
                        widget.userId,
                        speed: _selected,
                      );
                      if (!mounted) return;
                      widget.onSave?.call(_selected);
                      Navigator.of(context).pop(_selected);
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _saving = false);
                      AppToast.error(
                        context,
                        'Failed to update speed: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
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
    );
  }
}
