import 'package:flutter/widgets.dart';

/// Global key on the Done tab (index 2) for measuring the library coachmark target.
final GlobalKey doneLibraryCoachmarkTabKey = GlobalKey();

/// Highlights the Done tab while the library coachmark is visible.
final ValueNotifier<bool> doneLibraryCoachmarkVisible = ValueNotifier(false);

/// [PlayerWidget] registers this so a tap on Done dismisses the coachmark (prefs) before navigating.
Future<void> Function()? doneLibraryCoachmarkOnDoneTabDismiss;
