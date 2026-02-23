import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'dart:ui';
import '/index.dart';
import '/models/story.dart';
import '/services/story_service.dart';
import '/services/voice_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'desires_model.dart';
export 'desires_model.dart';

class DesiresWidget extends StatefulWidget {
  const DesiresWidget({super.key});

  static String routeName = 'Desires';
  static String routePath = '/desires';

  @override
  State<DesiresWidget> createState() => _DesiresWidgetState();
}

class _DesiresWidgetState extends State<DesiresWidget> {
  late DesiresModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  int? _loadingStoryId;

  Future<void> _playStory(String desireName, Story s) async {
    if (_loadingStoryId == s.id) return;
    setState(() => _loadingStoryId = s.id);
    try {
      final url = await VoiceService.speak(storyId: s.id);
      if (!mounted) return;
      setState(() => _loadingStoryId = null);
      if (url != null) {
        context.pushNamed(
          PlayerWidget.routeName,
          extra: {
            'categoryLabel': desireName,
            'title': s.title,
            'subtitle': s.desireName,
            'durationLabel': s.playLength ?? 'In your voice',
            'storyId': s.id,
            'audioUrl': url,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate audio')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStoryId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load voice: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => DesiresModel());
    _loadStories();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    setState(() => _model.isLoading = true);
    try {
      final stories = await StoryService.fetchStories();
      if (mounted) {
        setState(() {
          _model.stories = stories;
          _model.isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _model.errorMessage = e.toString();
          _model.isLoading = false;
        });
      }
    }
  }

  String _relativeDate(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  Widget _buildDesireCard(String desireName, List<Story> stories, int index) {
    const badgeBgs   = [Color(0xFFFDF0EE), Color(0xFFEEF4EE), Color(0xFFEEF0F4), Color(0xFFF4EEEE)];
    const badgeTexts = [Color(0xFFD98B80), Color(0xFF7FA882), Color(0xFF7F8FA8), Color(0xFFA87F7F)];
    const dots       = [Color(0xFFD98B80), Color(0xFF7FA882), Color(0xFF7F8FA8), Color(0xFFA87F7F)];
    const symbols    = ['♡', '\$', '✦', '✦'];
    final i         = index % 4;
    final badgeBg   = badgeBgs[i];
    final badgeText = badgeTexts[i];
    final dot       = dots[i];
    final symbol    = symbols[i];

    final count = stories.length;
    final sorted = [...stories]..sort((a, b) {
        if (a.lastPlayed == null && b.lastPlayed == null) return 0;
        if (a.lastPlayed == null) return 1;
        if (b.lastPlayed == null) return -1;
        return b.lastPlayed!.compareTo(a.lastPlayed!);
      });
    final latestDate = sorted.isNotEmpty ? sorted.first.lastPlayed : null;
    final lastLabel = latestDate != null
        ? 'Last played ${_relativeDate(latestDate)}'
        : 'Not yet played';
    final preview = sorted.take(2).toList();

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(14.0, 10.0, 14.0, 0.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: Color(0x1A1C1917)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(14.0, 12.0, 0.0, 5.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(20.0),
                      border: Border.all(
                          color: badgeText.withOpacity(0.2)),
                    ),
                    child: Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          8.0, 4.0, 8.0, 4.0),
                      child: Text(
                        '$symbol ${desireName.toUpperCase()}',
                        style: GoogleFonts.outfit(
                          color: badgeText,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 14.0, 0.0),
                  child: Text(
                    '›',
                    style: TextStyle(
                        color: Color(0xFFC4BAB0), fontSize: 20.0),
                  ),
                ),
              ],
            ),
            // Title + count
            Padding(
              padding:
                  EdgeInsetsDirectional.fromSTEB(14.0, 2.0, 14.0, 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: AlignmentDirectional(-1.0, 0.0),
                    child: Text(
                      sorted.isNotEmpty ? sorted.first.title : desireName,
                      style: GoogleFonts.cormorantGaramond(
                        fontWeight: FontWeight.w600,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '$count ${count == 1 ? 'story' : 'stories'} · $lastLabel',
                    style: GoogleFonts.dmMono(
                      color: Color(0xFF9E9189),
                      fontSize: 10.0,
                    ),
                  ),
                ],
              ),
            ),
            // Story preview rows
            if (preview.isNotEmpty) ...[
              Container(
                  width: double.infinity,
                  height: 1.0,
                  color: Color(0x191C1917)),
              Padding(
                padding:
                    EdgeInsetsDirectional.fromSTEB(14.0, 9.0, 14.0, 9.0),
                child: Column(
                  children: preview.asMap().entries.map((e) {
                    final s = e.value;
                    return Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          0.0, e.key == 0 ? 0.0 : 5.0, 0.0, 0.0),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _playStory(desireName, s),
                          borderRadius: BorderRadius.circular(10.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  10.0, 8.0, 10.0, 8.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 6.0,
                                        height: 6.0,
                                        decoration: BoxDecoration(
                                          color: dot,
                                          borderRadius:
                                              BorderRadius.circular(50.0),
                                        ),
                                      ),
                                      const SizedBox(width: 8.0),
                                      SizedBox(
                                        width: 160.0,
                                        child: Text(
                                          s.title,
                                          style: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 11.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        _relativeDate(s.lastPlayed),
                                        style: GoogleFonts.dmMono(
                                          color: Color(0xFF9E9189),
                                          fontSize: 10.0,
                                        ),
                                      ),
                                      const SizedBox(width: 6.0),
                                      _loadingStoryId == s.id
                                          ? SizedBox(
                                              width: 12.0,
                                              height: 12.0,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1.5,
                                                color: Color(0xFF9E9189),
                                              ),
                                            )
                                          : Text(
                                        '▶',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Color(0xFF9E9189),
                                          fontSize: 10.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desireGroups = _model.storiesByDesire;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Padding(
                  padding:
                      EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 10.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        // ── Header bar ──────────────────────────────────
                        Container(
                          width: double.infinity,
                          height: 70.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(0.0),
                              bottomRight: Radius.circular(0.0),
                              topLeft: Radius.circular(0.0),
                              topRight: Radius.circular(0.0),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      18.0, 12.0, 0.0, 2.0),
                                  child: Text(
                                    'My Desires',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font:
                                              GoogleFonts.cormorantGaramond(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          fontSize: 22.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      18.0, 0.0, 0.0, 0.0),
                                  child: Text(
                                    '${desireGroups.length} active · ${_model.stories.length} stories generated',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontWeight,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF9E9189),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Divider ──────────────────────────────────────
                        Container(
                          width: double.infinity,
                          height: 1.0,
                          decoration: BoxDecoration(
                            color: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            border: Border.all(
                              color: Color(0x1A1C1917),
                            ),
                          ),
                        ),
                        // ── Filter chips ─────────────────────────────────
                        Container(
                          width: double.infinity,
                          height: 49.0,
                          decoration: BoxDecoration(),
                          child: ListView(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            scrollDirection: Axis.horizontal,
                            children: [
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    14.0, 12.0, 0.0, 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Color(0xFF1C1917),
                                    borderRadius:
                                        BorderRadius.circular(20.0),
                                  ),
                                  child: Align(
                                    alignment:
                                        AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              13.0, 5.0, 13.0, 5.0),
                                      child: Text(
                                        'All',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Colors.white,
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    6.0, 12.0, 0.0, 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(20.0),
                                    border: Border.all(
                                      color: Color(0x1B1C1917),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Align(
                                    alignment:
                                        AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              13.0, 5.0, 13.0, 5.0),
                                      child: Text(
                                        '♡ Love',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF9E9189),
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    6.0, 12.0, 0.0, 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(20.0),
                                    border: Border.all(
                                      color: Color(0x1B1C1917),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Align(
                                    alignment:
                                        AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              13.0, 5.0, 13.0, 5.0),
                                      child: Text(
                                        '\$ Money',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF9E9189),
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsetsDirectional.fromSTEB(
                                    6.0, 12.0, 0.0, 12.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(20.0),
                                    border: Border.all(
                                      color: Color(0x1B1C1917),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Align(
                                    alignment:
                                        AlignmentDirectional(0.0, 0.0),
                                    child: Padding(
                                      padding:
                                          EdgeInsetsDirectional.fromSTEB(
                                              13.0, 5.0, 13.0, 5.0),
                                      child: Text(
                                        '✦ Career',
                                        style: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .override(
                                              font: GoogleFonts.outfit(
                                                fontWeight: FontWeight.w600,
                                                fontStyle:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .bodyMedium
                                                        .fontStyle,
                                              ),
                                              color: Color(0xFF9E9189),
                                              fontSize: 10.0,
                                              letterSpacing: 0.0,
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // ── Dynamic desire cards ─────────────────────────
                        if (_model.isLoading)
                          const Padding(
                            padding: EdgeInsets.all(24.0),
                            child: CircularProgressIndicator(),
                          )
                        else if (_model.errorMessage != null)
                          Padding(
                            padding: EdgeInsetsDirectional.fromSTEB(
                                14.0, 20.0, 14.0, 0.0),
                            child: Text(
                              _model.errorMessage!,
                              style: GoogleFonts.outfit(
                                  color: Colors.red, fontSize: 12.0),
                            ),
                          )
                        else
                          ...desireGroups.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((indexedEntry) => _buildDesireCard(
                                    indexedEntry.value.key,
                                    indexedEntry.value.value,
                                    indexedEntry.key,
                                  )),
                        // ── Add New Desire button ────────────────────────
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              14.0, 10.0, 14.0, 0.0),
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(0xFF1C1917),
                              borderRadius: BorderRadius.circular(18.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  13.0, 13.0, 13.0, 13.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.max,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Align(
                                    alignment:
                                        AlignmentDirectional(0.0, 0.0),
                                    child: Container(
                                      width: 22.0,
                                      height: 22.0,
                                      decoration: BoxDecoration(
                                        color: const Color(0x19FFFFFF),
                                        borderRadius:
                                            BorderRadius.circular(11.0),
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius:
                                              BorderRadius.circular(11.0),
                                          onTap: () {
                                            print('IconButton pressed ...');
                                          },
                                          child: Center(
                                            child: Text(
                                              '✦',
                                              style: TextStyle(
                                                fontSize: 11.0,
                                                color:
                                                    FlutterFlowTheme.of(
                                                            context)
                                                        .info,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        EdgeInsetsDirectional.fromSTEB(
                                            8.0, 0.0, 0.0, 0.0),
                                    child: Text(
                                      'Add New Desire',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.outfit(
                                              fontWeight: FontWeight.w600,
                                              fontStyle:
                                                  FlutterFlowTheme.of(
                                                          context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            color: Colors.white,
                                            fontSize: 13.0,
                                            letterSpacing: 0.0,
                                            fontWeight: FontWeight.w600,
                                            fontStyle: FlutterFlowTheme.of(
                                                    context)
                                                .bodyMedium
                                                .fontStyle,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
