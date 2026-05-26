import 'package:flutter/foundation.dart';
import 'package:upgrader/upgrader.dart';

final Upgrader appUpgrader = Upgrader(
  debugLogging: kDebugMode,
  durationUntilAlertAgain: const Duration(hours: 24),
);
