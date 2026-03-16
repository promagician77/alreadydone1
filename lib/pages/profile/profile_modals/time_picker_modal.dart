import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:google_fonts/google_fonts.dart';

import '/services/app_toast.dart';
import '/widgets/pressable.dart';
import '/services/backend_client.dart';
import 'shared.dart';

/// Time picker modal (Quick Select). When userId and fieldType are provided, calls API on save.
Future<T?> showTimePickerModal<T>(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String currentTime,
  int? userId,
  TimeFieldType? fieldType,
  ValueChanged<String>? onSave,
}) {
  const presets = ['6:00 AM', '7:00 AM', '8:00 AM', '9:00 AM', '10:00 AM'];
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) => _TimePickerSheet(
      title: title,
      subtitle: subtitle,
      currentTime: currentTime,
      presets: presets,
      userId: userId,
      fieldType: fieldType,
      onSave: onSave,
    ),
  );
}

enum TimeFieldType { morning, bedtime }

String _timeDisplayToIso(String display) {
  final m = RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false).firstMatch(display);
  if (m == null) return DateTime.utc(2000, 1, 1, 8, 0, 0, 0).toIso8601String();
  int h = int.tryParse(m.group(1) ?? '8') ?? 8;
  int min = int.tryParse(m.group(2) ?? '0') ?? 0;
  final isPM = (m.group(3) ?? 'AM').toUpperCase() == 'PM';
  if (isPM && h < 12) h += 12;
  if (!isPM && h == 12) h = 0;
  return DateTime.utc(2000, 1, 1, h, min, 0, 0).toIso8601String();
}

/// Parse ISO datetime to display string (e.g. "09:00 AM").
String formatTimeFromIso(dynamic value) {
  if (value == null) return '8:00 AM';
  final s = value.toString().trim();
  if (s.isEmpty) return '8:00 AM';
  // Already in display format "9:00 AM" or "10:30 PM"
  if (RegExp(r'^\d{1,2}:\d{2}\s*(AM|PM)$', caseSensitive: false).hasMatch(s)) return s;
  try {
    final dt = DateTime.parse(s);
    final h = dt.hour;
    final m = dt.minute;
    final h12 = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    final ampm = h >= 12 ? 'PM' : 'AM';
    return '${h12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $ampm';
  } catch (_) {}
  return '8:00 AM';
}

class _TimePickerSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String currentTime;
  final List<String> presets;
  final int? userId;
  final TimeFieldType? fieldType;
  final ValueChanged<String>? onSave;

  const _TimePickerSheet({
    required this.title,
    required this.subtitle,
    required this.currentTime,
    required this.presets,
    this.userId,
    this.fieldType,
    this.onSave,
  });

  @override
  State<_TimePickerSheet> createState() => _TimePickerSheetState();
}

class _TimePickerSheetState extends State<_TimePickerSheet> {
  late String _selected;
  bool _customMode = false;
  bool _saving = false;

  /// Current device timezone as IANA identifier (e.g. "America/New_York", "Asia/Kolkata").
  /// Falls back to UTC offset string if the plugin fails (e.g. unsupported platform).
  static Future<String> _getCurrentTimezoneIana() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      final id = info.identifier?.trim();
      if (id != null && id.isNotEmpty) return id;
    } catch (_) {}
    final offset = DateTime.now().timeZoneOffset;
    final hours = offset.inHours;
    final minutes = offset.inMinutes.abs() % 60;
    final sign = hours >= 0 ? '+' : '-';
    final h = hours.abs();
    final m = minutes.toString().padLeft(2, '0');
    return 'UTC$sign${h.toString().padLeft(2, '0')}:$m';
  }

  Future<void> _handleSave(String timeDisplay) async {
    if (widget.userId != null && widget.fieldType != null) {
      setState(() => _saving = true);
      try {
        final iso = _timeDisplayToIso(timeDisplay);
        final timezone = await _getCurrentTimezoneIana();
        await BackendClient.updateUserProfile(
          widget.userId!,
          morningTimeReminder: widget.fieldType == TimeFieldType.morning ? iso : null,
          bedtimeReminder: widget.fieldType == TimeFieldType.bedtime ? iso : null,
          timezone: timezone,
        );
        if (!mounted) return;
        widget.onSave?.call(timeDisplay);
        Navigator.of(context).pop(timeDisplay);
      } catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);
        AppToast.error(
          context,
          'Failed to update: ${e.toString().replaceFirst(RegExp(r'^Exception:?\s*'), '')}',
        );
      }
    } else {
      widget.onSave?.call(timeDisplay);
      Navigator.of(context).pop(timeDisplay);
    }
  }

  @override
  void initState() {
    super.initState();
    _selected = widget.currentTime;
    if (!widget.presets.contains(_selected)) {
      _selected = widget.presets.contains('8:00 AM') ? '8:00 AM' : widget.presets.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_customMode) {
      return _CustomTimeSheet(
        title: 'Choose Exact Time',
        subtitle: 'Scroll to select your preferred time',
        currentTime: _selected,
        isSaving: _saving,
        onBack: () => setState(() => _customMode = false),
        onSave: (t) => _handleSave(t),
        onCancel: () => Navigator.of(context).pop(),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
              title: widget.title,
              subtitle: widget.subtitle,
            ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: ModalColors.warmWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  _selected,
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 56,
                    fontWeight: FontWeight.w300,
                    color: ModalColors.gold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to change time',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: ModalColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'QUICK SELECT',
            style: GoogleFonts.outfit(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ModalColors.inkMid,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ...widget.presets.map((t) {
                final isSelected = _selected == t;
                return Pressable(
                  onTap: _saving ? null : () => setState(() => _selected = t),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? ModalColors.goldPale : ModalColors.surface,
                      border: Border.all(
                        color: isSelected ? ModalColors.gold : ModalColors.stone,
                        width: isSelected ? 2 : 1.5,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      t,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? ModalColors.goldDark : ModalColors.ink,
                      ),
                    ),
                  ),
                );
              }),
              Pressable(
                onTap: _saving ? null : () => setState(() => _customMode = true),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: ModalColors.surface,
                    border: Border.all(color: ModalColors.stone, width: 1.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Custom',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ModalColors.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          buildActionButtons(
            onCancel: () => Navigator.of(context).pop(),
            onSave: () => _handleSave(_selected),
            saveLabel: 'Save',
            saving: _saving,
          ),
          ],
        ),
      ),
    );
  }
}

class _CustomTimeSheet extends StatefulWidget {
  final String title;
  final String subtitle;
  final String currentTime;
  final bool isSaving;
  final VoidCallback onBack;
  final ValueChanged<String> onSave;
  final VoidCallback onCancel;

  const _CustomTimeSheet({
    required this.title,
    required this.subtitle,
    required this.currentTime,
    this.isSaving = false,
    required this.onBack,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_CustomTimeSheet> createState() => _CustomTimeSheetState();
}

class _CustomTimeSheetState extends State<_CustomTimeSheet> {
  late int _hour;
  late int _minute;
  late bool _isPM;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;
  late FixedExtentScrollController _ampmController;

  @override
  void initState() {
    super.initState();
    _parseTime(widget.currentTime);
    final hour12 = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);
    _hourController = FixedExtentScrollController(initialItem: (hour12 - 1).clamp(0, 11));
    _minuteController = FixedExtentScrollController(initialItem: (_minute / 5).round().clamp(0, 11));
    _ampmController = FixedExtentScrollController(initialItem: _isPM ? 1 : 0);
  }

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    _ampmController.dispose();
    super.dispose();
  }

  void _parseTime(String t) {
    final m = RegExp(r'(\d+):(\d+)\s*(AM|PM)?', caseSensitive: false).firstMatch(t);
    if (m != null) {
      _hour = int.tryParse(m.group(1) ?? '8') ?? 8;
      _minute = int.tryParse(m.group(2) ?? '0') ?? 0;
      _isPM = (m.group(3) ?? 'AM').toUpperCase() == 'PM';
    } else {
      _hour = 8;
      _minute = 0;
      _isPM = false;
    }
  }

  String _formatTime() {
    final h = _hour > 12 ? _hour - 12 : (_hour == 0 ? 12 : _hour);
    final m = _minute.toString().padLeft(2, '0');
    return '${h.toString().padLeft(2, '0')}:$m ${_isPM ? 'PM' : 'AM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
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
        absorbing: widget.isSaving,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            buildSheetHeader(
              title: widget.title,
              subtitle: widget.subtitle,
            ),
            const SizedBox(height: 20),
            SizedBox(
            height: 200,
            child: CupertinoTheme(
              data: CupertinoThemeData(
                brightness: Brightness.light,
                primaryColor: ModalColors.gold,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AbsorbPointer(
                    absorbing: widget.isSaving,
                    child: SizedBox(
                      width: 60,
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => setState(() => _hour = i + 1),
                        children: List.generate(12, (i) => Center(child: Text('${i + 1}'))),
                      ),
                    ),
                  ),
                  const Text(' : ', style: TextStyle(fontSize: 24, color: ModalColors.ink)),
                  AbsorbPointer(
                    absorbing: widget.isSaving,
                    child: SizedBox(
                      width: 60,
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => setState(() => _minute = i * 5),
                        children: List.generate(12, (i) => Center(child: Text('${(i * 5).toString().padLeft(2, '0')}'))),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AbsorbPointer(
                    absorbing: widget.isSaving,
                    child: SizedBox(
                      width: 50,
                      child: CupertinoPicker(
                        scrollController: _ampmController,
                        itemExtent: 40,
                        onSelectedItemChanged: (i) => setState(() => _isPM = i == 1),
                        children: const [
                          Center(child: Text('AM')),
                          Center(child: Text('PM')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Swipe up or down to change',
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: ModalColors.inkSoft,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Pressable(
              onTap: widget.isSaving ? null : widget.onBack,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Text(
                  '← Back to Quick Select',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: ModalColors.gold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          buildActionButtons(
            onCancel: widget.onCancel,
            onSave: () => widget.onSave(_formatTime()),
            saveLabel: 'Save',
            saving: widget.isSaving,
          ),
          ],
        ),
      ),
    );
  }
}
