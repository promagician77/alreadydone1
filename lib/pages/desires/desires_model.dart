import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/models/story.dart';
import 'desires_widget.dart' show DesiresWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class DesiresModel extends FlutterFlowModel<DesiresWidget> {
  List<Story> stories = [];
  bool isLoading = false;
  String? errorMessage;

  /// Groups stories by their desireName.
  Map<String, List<Story>> get storiesByDesire {
    final map = <String, List<Story>>{};
    for (final s in stories) {
      if (s.desireName.isNotEmpty) {
        map.putIfAbsent(s.desireName, () => []).add(s);
      }
    }
    return map;
  }

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {}
}
