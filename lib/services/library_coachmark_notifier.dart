import 'package:flutter/foundation.dart';

/// Set to `true` to ask [NavBarPage] to show the Done-tab library coachmark.
/// The listener consumes the flag (sets it back to `false`) when showing.
final ValueNotifier<bool> libraryCoachmarkRequestNotifier =
    ValueNotifier<bool>(false);
