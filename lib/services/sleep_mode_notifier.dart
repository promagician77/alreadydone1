import 'package:flutter/foundation.dart';

/// Global notifier for player sleep mode.
/// Used by NavBarPage to update navbar styling when sleep mode is active.
final ValueNotifier<bool> sleepModeNotifier = ValueNotifier<bool>(false);
