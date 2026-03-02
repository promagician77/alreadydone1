import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/services/backend_client.dart';
import 'shared.dart';

/// Dream Location modal. Calls PATCH /api/users/{user_id} with the location on Save.
Future<T?> showDreamLocationModal<T>(
  BuildContext context, {
  required int userId,
  required String currentLocation,
  ValueChanged<String>? onSave,
}) {
  const popular = [
    'New York City', 'Paris', 'Bali', 'Tokyo', 'Miami', 'London',
    'Los Angeles', 'Dubai', 'Sydney', 'Toronto', 'Munich', 'Zurich',
    'Barcelona', 'Amsterdam', 'Copenhagen',
  ];
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => DreamLocationSheet(
      userId: userId,
      currentLocation: currentLocation,
      popular: popular,
      onSave: onSave,
    ),
  );
}

class DreamLocationSheet extends StatefulWidget {
  const DreamLocationSheet({
    super.key,
    required this.userId,
    required this.currentLocation,
    required this.popular,
    this.onSave,
  });

  final int userId;
  final String currentLocation;
  final List<String> popular;
  final ValueChanged<String>? onSave;

  @override
  State<DreamLocationSheet> createState() => _DreamLocationSheetState();
}

class _DreamLocationSheetState extends State<DreamLocationSheet> {
  late TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentLocation == '—' ? '' : widget.currentLocation);
  }

  List<List<T>> _chunked<T>(List<T> list, int size) {
    final result = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      result.add(list.sublist(i, (i + size).clamp(0, list.length)));
    }
    return result;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                title: 'Dream Location',
                subtitle: 'Where does your dream life take place?',
              ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              enabled: !_saving,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                filled: true,
                fillColor: ModalColors.warmWhite,
                hintText: 'City or country',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ModalColors.gold, width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: ModalColors.gold, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: ModalColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"You woke up in ${_controller.text.isEmpty ? "..." : _controller.text}..." - where your manifestations take place',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: ModalColors.inkSoft,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'POPULAR LOCATIONS',
              style: GoogleFonts.outfit(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ModalColors.inkMid,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            ..._chunked(widget.popular, 3).map((row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: row.asMap().entries.map((e) {
                  final loc = e.value;
                  final isSelected = _controller.text.trim() == loc;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: e.key < row.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: _saving ? null : () {
                          _controller.text = loc;
                          setState(() {});
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? ModalColors.ink : ModalColors.surface,
                            border: Border.all(
                              color: isSelected ? ModalColors.ink : ModalColors.stone,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              loc,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : ModalColors.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            )),
            const SizedBox(height: 20),
            buildActionButtons(
              onCancel: () => Navigator.of(context).pop(),
              onSave: () async {
                      final location = _controller.text.trim().isEmpty ? '—' : _controller.text.trim();
                      setState(() => _saving = true);
                      try {
                        await BackendClient.updateUserProfile(
                          widget.userId,
                          location: location,
                        );
                        if (!mounted) return;
                        widget.onSave?.call(location);
                        Navigator.of(context).pop(location);
                      } catch (e) {
                        if (!mounted) return;
                        setState(() => _saving = false);
                        AppToast.error(
                          context,
                          'Failed to update location: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
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
