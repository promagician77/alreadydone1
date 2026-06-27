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
  String? userName;
  int dayStreak = 0;

  String? voiceId;
  Map<int, String> voicePlayUrlCache = {};

  List<Map<String, dynamic>> desires = [];
  bool desiresLoading = true;

  String? selectedDesireFilter;

  List<Map<String, dynamic>> stories = [];
  bool storiesLoading = true;

  int? playingStoryId;
  bool isPlaying = false;

  Map<int, int> durationCache = {};

  Duration playbackPosition = Duration.zero;
  Duration playbackDuration = Duration.zero;

  bool isSubscribed = false;

  bool subscriptionStatusLoaded = false;

  String? rcSubscriptionStatus;

  String? rcSubscriptionPlan;
  bool profileSubscriptionReady = false;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
