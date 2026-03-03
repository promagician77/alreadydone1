import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'home_dashboard_widget.dart' show HomeDashboardWidget;

class HomeDashboardModel extends FlutterFlowModel<HomeDashboardWidget> {
  /// Current user name from backend profile.
  String? userName;

  /// Day streak from backend profile (number).
  int dayStreak = 0;

  /// Voice ID from backend profile (for api/voice/speak).
  String? voiceId;

  /// Cached voice play URL per story ID (from api/voice/speak).
  Map<int, String> voicePlayUrlCache = {};

  /// Desire categories from GET /api/desires. [ { id, name }, ... ]
  List<Map<String, dynamic>> desires = [];
  bool desiresLoading = true;

  /// Selected desire filter. Null = "All Stories", else desire name.
  String? selectedDesireFilter;

  /// Stories from GET /api/stories, ordered (e.g. by last_played / created_at).
  List<Map<String, dynamic>> stories = [];
  bool storiesLoading = true;

  /// Story currently playing in the dashboard card (by id). Null when none.
  int? playingStoryId;
  /// Whether the main card's story is currently playing.
  bool isPlaying = false;

  /// Cached duration (seconds) per story ID. Populated when audio loads during playback.
  Map<int, int> durationCache = {};

  /// Current playback position/duration for the playing story.
  Duration playbackPosition = Duration.zero;
  Duration playbackDuration = Duration.zero;

  /// True when user has an active subscription (stripe_subscription_id present).
  /// When true, the "Sleep Mode" premium card on home is hidden.
  bool isSubscribed = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
