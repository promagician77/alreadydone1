import 'dart:async';
import 'dart:math' as math;
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/services/voice_service.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'player_model.dart';
export 'player_model.dart';

class PlayerWidget extends StatefulWidget {
  const PlayerWidget({
    super.key,
    this.categoryLabel,
    this.title,
    this.subtitle,
    this.durationLabel,
    this.storyId,
    this.audioUrl,
  });

  final String? categoryLabel;
  final String? title;
  final String? subtitle;
  final String? durationLabel;
  final int? storyId;
  final String? audioUrl;

  static String routeName = 'Player';
  static String routePath = '/player';

  @override
  State<PlayerWidget> createState() => _PlayerWidgetState();
}

class _PlayerWidgetState extends State<PlayerWidget> {
  late PlayerModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<double> _staticWaveHeights = [
    10, 20, 30, 16, 36, 24, 32, 12, 40, 22, 28, 38, 14, 24, 34,
  ];
  static const int _maxWaveBars = 32;
  static const int _barWidth = 5;
  static const double _barGap = 2.0;

  bool _isWavePlaying = false;
  List<double> _waveBars = List.from(_staticWaveHeights);
  Timer? _waveTimer;
  final math.Random _random = math.Random();

  late AudioPlayer _audioPlayer;
  String? _currentAudioUrl;
  bool _isLoadingAudio = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatDurationFull(Duration d) {
    final hours = d.inHours.toString().padLeft(2, '0');
    final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  Future<void> _togglePlayPause() async {
    final url = widget.audioUrl ?? _currentAudioUrl;
    if (url != null) {
      if (_isWavePlaying) {
        await _audioPlayer.pause();
        _stopWaveStream();
      } else {
        await _audioPlayer.play(UrlSource(url, mimeType: 'audio/mpeg'));
        _startWaveStream();
      }
      return;
    }
    if (widget.storyId == null) return;
    if (_isLoadingAudio) return;
    setState(() => _isLoadingAudio = true);
    try {
      final newUrl = await VoiceService.speak(storyId: widget.storyId!);
      if (!mounted) return;
      setState(() {
        _isLoadingAudio = false;
        _currentAudioUrl = newUrl;
      });
      if (newUrl != null) {
        await _audioPlayer.play(UrlSource(newUrl, mimeType: 'audio/mpeg'));
        _startWaveStream();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not generate audio')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load voice: $e')),
      );
    }
  }

  void _startWaveStream() {
    _waveTimer?.cancel();
    setState(() {
      _isWavePlaying = true;
      _waveBars = List.from(_staticWaveHeights);
    });
    _waveTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted || !_isWavePlaying) return;
      setState(() {
        final h = 8.0 + _random.nextDouble() * 32.0;
        _waveBars.add(h.clamp(8.0, 40.0));
        if (_waveBars.length > _maxWaveBars) {
          _waveBars.removeAt(0);
        }
      });
    });
  }

  void _stopWaveStream() {
    _waveTimer?.cancel();
    _waveTimer = null;
    setState(() {
      _isWavePlaying = false;
      _waveBars = List.from(_staticWaveHeights);
    });
  }

  List<Widget> _buildWaveBars() {
    return [
      for (int i = 0; i < _waveBars.length; i++) ...[
        if (i > 0) SizedBox(width: _barGap),
        Container(
          width: _barWidth.toDouble(),
          height: _waveBars[i].clamp(8.0, 54.0),
          decoration: BoxDecoration(
            color: Color(
              i % 2 == 0 ? 0xFF1C1917 : 0xFFE8E2DA,
            ),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ],
    ];
  }

  List<Widget> _buildFullWidthWaveBars(double availableWidth) {
    final barCount = ((availableWidth + _barGap) / (_barWidth + _barGap))
        .floor()
        .clamp(1, 200);
    return [
      for (int i = 0; i < barCount; i++) ...[
        if (i > 0) SizedBox(width: _barGap),
        Container(
          width: _barWidth.toDouble(),
          height: _staticWaveHeights[i % _staticWaveHeights.length]
              .clamp(8.0, 54.0),
          decoration: BoxDecoration(
            color: Color(
              i % 2 == 0 ? 0xFF1C1917 : 0xFFE8E2DA,
            ),
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
      ],
    ];
  }

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PlayerModel());
    _audioPlayer = AudioPlayer();
    _currentAudioUrl = widget.audioUrl;
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (mounted) {
          _stopWaveStream();
          setState(() => _currentPosition = Duration.zero);
        }
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration);
    });
    if (widget.audioUrl != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _audioPlayer.play(UrlSource(widget.audioUrl!, mimeType: 'audio/mpeg'));
        _startWaveStream();
      });
    }
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    _audioPlayer.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: FlutterFlowTheme.of(context).secondaryBackground,
              border: Border.all(
                color: Color(0xFFE9E5DF),
              ),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(20.0, 0.0, 20.0, 0.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Padding(
                        padding:
                            EdgeInsetsDirectional.fromSTEB(0.0, 6.0, 0.0, 14.0),
                        child: Text(
                          '← Back',
                          style:
                              FlutterFlowTheme.of(context).bodyMedium.override(
                                    font: GoogleFonts.inter(
                                      fontWeight: FontWeight.w500,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF6B6460),
                                    fontSize: 12.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FontWeight.w500,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFF5EDD8),
                              Color(0xFFFDF0EE),
                              Color(0xFFF9F7F4)
                            ],
                            stops: [0.0, 0.6, 1.0],
                            begin: AlignmentDirectional(0.87, 1.0),
                            end: AlignmentDirectional(-0.87, -1.0),
                          ),
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(
                            color: Color(0x19C9972A),
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 22.0, 0.0, 9.0),
                              child: Text(
                                widget.categoryLabel ?? '♡ Love · Today',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFFB8861E),
                                      fontSize: 9.0,
                                      letterSpacing: 2.0,
                                      fontWeight: FontWeight.bold,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                            Text(
                              widget.title ?? 'A Love That Was',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.cormorantGaramond(
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF1C1917),
                                    fontSize: 22.0,
                                    letterSpacing: 1.3,
                                    fontWeight: FontWeight.w600,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 7.0),
                              child: Text(
                                widget.subtitle ?? 'Always Yours',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.cormorantGaramond(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FontStyle.italic,
                                      ),
                                      color: Color(0xFFC9972A),
                                      fontSize: 22.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FontStyle.italic,
                                    ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  0.0, 0.0, 0.0, 22.0),
                              child: Text(
                                _totalDuration > Duration.zero
                                    ? _formatDurationFull(_totalDuration)
                                    : (widget.durationLabel ?? '00:00:00'),
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.dmMono(
                                        fontWeight: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontWeight,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF9E9189),
                                      fontSize: 10.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 9.0),
                      child: Container(
                        width: double.infinity,
                        height: 54.0,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: Color(0x141C1917),
                          ),
                        ),
                        padding: EdgeInsetsDirectional.fromSTEB(
                            14.0, 0.0, 14.0, 0.0),
                        alignment: Alignment.center,
                        child: _isWavePlaying
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: _buildWaveBars(),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final w = constraints.maxWidth;
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: _buildFullWidthWaveBars(w),
                                  );
                                },
                              ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        height: 14.0,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_currentPosition),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmMono(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF9E9189),
                                    fontSize: 10.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                            Text(
                              _formatDuration(_totalDuration),
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.dmMono(
                                      fontWeight: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontWeight,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                                    color: Color(0xFF9E9189),
                                    fontSize: 10.0,
                                    letterSpacing: 0.0,
                                    fontWeight: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontWeight,
                                    fontStyle: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .fontStyle,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '⏮',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '⏪',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 58.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFF1C1917),
                                borderRadius: BorderRadius.circular(29.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(29.0),
                                  onTap: _togglePlayPause,
                                  child: Center(
                                    child: _isLoadingAudio
                                        ? SizedBox(
                                            width: 18.0,
                                            height: 18.0,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.0,
                                              color: Colors.white,
                                            ),
                                          )
                                        : Text(
                                      _isWavePlaying ? '⏸' : '▶',
                                      style: TextStyle(
                                        fontSize: 24.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '⏩',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              width: 38.0,
                              height: 38.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF2EEE9),
                                borderRadius: BorderRadius.circular(19.0),
                                border: Border.all(
                                  color: Color(0xFF1C1917),
                                  width: 1.0,
                                ),
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(19.0),
                                  onTap: () {
                                    print('IconButton pressed ...');
                                  },
                                  child: Center(
                                    child: Text(
                                      '↻',
                                      style: TextStyle(
                                        fontSize: 17.0,
                                        color: Color(0xFF3D3530),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                          EdgeInsetsDirectional.fromSTEB(0.0, 0.0, 0.0, 18.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color:
                              FlutterFlowTheme.of(context).secondaryBackground,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: 72.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF9F7F4),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0x151C1917),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 10.0, 0.0, 3.0),
                                    child: Text(
                                      '☀️',
                                      style: const TextStyle(
                                        fontSize: 15.0,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Standard',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF3D3530),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 72.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFFBF4E6),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0x151C1917),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 10.0, 0.0, 3.0),
                                    child: Text(
                                      '🌙',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 15.0,
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
                                  Text(
                                    'Sleep',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFFB8861E),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 72.0,
                              height: 58.0,
                              decoration: BoxDecoration(
                                color: Color(0xFFF9F7F4),
                                borderRadius: BorderRadius.circular(12.0),
                                border: Border.all(
                                  color: Color(0x151C1917),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.max,
                                children: [
                                  Padding(
                                    padding: EdgeInsetsDirectional.fromSTEB(
                                        0.0, 10.0, 0.0, 3.0),
                                    child: Text(
                                      '🔁',
                                      style: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .override(
                                            font: GoogleFonts.inter(
                                              fontWeight:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontWeight,
                                              fontStyle:
                                                  FlutterFlowTheme.of(context)
                                                      .bodyMedium
                                                      .fontStyle,
                                            ),
                                            fontSize: 15.0,
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
                                  Text(
                                    'Loop',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          fontSize: 10.0,
                                          letterSpacing: 0.0,
                                          fontWeight: FontWeight.w600,
                                          fontStyle:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontStyle,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                          0.0, 0.0, 0.0, 14.0),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xFFF9F7F4),
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(
                            color: Color(0x1A1C1917),
                            width: 1.0,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(
                              13.0, 13.0, 0.0, 0.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              Align(
                                alignment: AlignmentDirectional(-1.0, 0.0),
                                child: Padding(
                                  padding: EdgeInsetsDirectional.fromSTEB(
                                      0.0, 0.0, 0.0, 7.0),
                                  child: Text(
                                    'Story Preview',
                                    style: FlutterFlowTheme.of(context)
                                        .bodyMedium
                                        .override(
                                          font: GoogleFonts.outfit(
                                            fontWeight: FontWeight.w600,
                                            fontStyle:
                                                FlutterFlowTheme.of(context)
                                                    .bodyMedium
                                                    .fontStyle,
                                          ),
                                          color: Color(0xFF9E9189),
                                          fontSize: 9.0,
                                          letterSpacing: 2.0,
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
                                child: Text(
                                  '\"You wake beside someone who looks at you like you\'re the whole world. The morning light is warm, and Jordan, you feel it — this easy, certain love…\"',
                                  style: FlutterFlowTheme.of(context)
                                      .bodyMedium
                                      .override(
                                        font: GoogleFonts.cormorantGaramond(
                                          fontWeight:
                                              FlutterFlowTheme.of(context)
                                                  .bodyMedium
                                                  .fontWeight,
                                          fontStyle: FontStyle.italic,
                                        ),
                                        color: Color(0xFF3D3530),
                                        letterSpacing: 0.0,
                                        fontWeight:
                                            FlutterFlowTheme.of(context)
                                                .bodyMedium
                                                .fontWeight,
                                        fontStyle: FontStyle.italic,
                                        lineHeight: 1.72,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: FlutterFlowTheme.of(context).secondaryBackground,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  6.0, 10.0, 6.0, 10.0),
                              child: Text(
                                '♡ Save',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3D3530),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  6.0, 10.0, 6.0, 10.0),
                              child: Text(
                                '↗ Share',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3D3530),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFFF9F7F4),
                              borderRadius: BorderRadius.circular(12.0),
                              border: Border.all(
                                color: Color(0x1A1C1917),
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsetsDirectional.fromSTEB(
                                  6.0, 10.0, 6.0, 10.0),
                              child: Text(
                                '✦ New',
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        fontStyle: FlutterFlowTheme.of(context)
                                            .bodyMedium
                                            .fontStyle,
                                      ),
                                      color: Color(0xFF3D3530),
                                      fontSize: 11.0,
                                      letterSpacing: 0.0,
                                      fontWeight: FontWeight.w600,
                                      fontStyle: FlutterFlowTheme.of(context)
                                          .bodyMedium
                                          .fontStyle,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
