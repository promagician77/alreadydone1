import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/backend_client.dart';
import '/widgets/pressable.dart';
import 'shared.dart';

/// Energy Word modal. Calls PATCH /api/users/{user_id} with the energyWord on Save.
Future<T?> showEnergyWordModal<T>(
  BuildContext context, {
  required int userId,
  required String currentWord,
  ValueChanged<String>? onSave,
}) {
  const options = [
    ('Powerful', 'Unstoppable, in control, commanding'),
    ('Peaceful', 'Calm, certain, at ease with life'),
    ('Abundant', 'Overflowing, blessed, rich in all ways'),
    ('Grateful', 'Thankful, present, appreciative'),
    ('Confident', 'Assured, radiant, self-believing'),
  ];
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => EnergyWordSheet(
      userId: userId,
      currentWord: currentWord,
      options: options,
      onSave: onSave,
    ),
  );
}

class EnergyWordSheet extends StatefulWidget {
  const EnergyWordSheet({
    super.key,
    required this.userId,
    required this.currentWord,
    required this.options,
    this.onSave,
  });

  final int userId;
  final String currentWord;
  final List<(String, String)> options;
  final ValueChanged<String>? onSave;

  @override
  State<EnergyWordSheet> createState() => _EnergyWordSheetState();
}

class _EnergyWordSheetState extends State<EnergyWordSheet> {
  late String _selected;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentWord;
    if (!widget.options.any((o) => o.$1 == _selected)) {
      _selected = widget.options.first.$1;
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: SingleChildScrollView(
          child: AbsorbPointer(
            absorbing: _saving,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                buildSheetHeader(
                title: 'Energy Word',
                subtitle: 'How you want to feel in your stories',
              ),
          const SizedBox(height: 20),
          ...widget.options.map((o) {
            final (word, desc) = o;
            final isSelected = _selected == word;
            final isCurrent = word == widget.currentWord;
            return Pressable(
              onTap: _saving ? null : () => setState(() => _selected = word),
              borderRadius: BorderRadius.circular(12),
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
                            word,
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
                        energyWord: _selected,
                      );
                      if (!mounted) return;
                      widget.onSave?.call(_selected);
                      Navigator.of(context).pop(_selected);
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => _saving = false);
                      AppToast.error(
                        context,
                        'Failed to update energy word: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
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
    );
  }
}
