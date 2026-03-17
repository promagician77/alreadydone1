import 'package:flutter/foundation.dart';

/// Global UI lock for bottom navigation interactions.
///
/// When `true`, the bottom navigation bar ignores taps (e.g. while a long-running
/// operation like "Deepening your manifestation..." is in progress).
final ValueNotifier<bool> navLockNotifier = ValueNotifier<bool>(false);

