import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Owns the app's long-lived [AudioPlayer]s and mirrors their state into the
/// OS media session, so story playback shows up on the iOS lock screen /
/// Control Center and in the Android notification shade.
///
/// Pages must not create their own [AudioPlayer] for story audio: only the
/// player wired into this handler can drive the media session. Pages also must
/// never dispose these players — the handler outlives every widget.
class StoryAudioHandler extends BaseAudioHandler with SeekHandler {
  StoryAudioHandler._() {
    _wireStreams();
  }

  static StoryAudioHandler? _instance;

  /// Always available, even when [initStoryAudio] failed or ran on a platform
  /// without a media session. Only the lock-screen mirroring is best-effort.
  static StoryAudioHandler get instance => _instance ??= StoryAudioHandler._();

  /// Narration player. Every page plays story audio through this instance.
  final AudioPlayer voicePlayer = AudioPlayer();

  /// Looping theta bed mixed under the narration during Sleep Mode.
  final AudioPlayer thetaPlayer = AudioPlayer();

  /// Which page started the current playback ('player', 'home', …). Pages
  /// listen to the same shared streams, so they use this to ignore events for
  /// audio they did not start.
  String? currentOwner;

  /// Registered by the visible player page so the lock-screen buttons run the
  /// same code as the on-screen controls (sleep-mode volumes, story switching).
  /// When a callback is null the handler falls back to driving [voicePlayer].
  Future<void> Function()? onPlayRequested;
  Future<void> Function()? onPauseRequested;
  Future<void> Function()? onSkipNextRequested;
  Future<void> Function()? onSkipPreviousRequested;
  Future<void> Function(Duration position)? onSeekRequested;

  Duration _position = Duration.zero;
  double _speed = 1.0;
  bool _hasStoryNav = false;
  AudioProcessingState _processingState = AudioProcessingState.idle;
  int _lastBroadcastSecond = -1;

  /// iOS must NOT use `mixWithOthers`: that option makes the app ineligible to
  /// become the system "Now Playing" app, which silently kills all lock-screen
  /// controls. Two players inside one app already mix without it.
  ///
  /// Android keeps [AndroidAudioFocus.none] so the narration and the theta bed
  /// don't steal audio focus from each other, and [stayAwake] so playback
  /// survives the screen turning off.
  AudioContext buildAudioContext() => AudioContext(
        android: const AudioContextAndroid(
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.none,
        ),
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {},
        ),
      );

  Future<void> applyAudioContext() async {
    final ctx = buildAudioContext();
    await voicePlayer.setAudioContext(ctx);
    await thetaPlayer.setAudioContext(ctx);
  }

  /// Publishes what the lock screen shows. Call whenever the loaded story
  /// changes. [id] must be stable and non-empty (the play URL works well).
  void setNowPlaying({
    required String id,
    required String title,
    String? album,
    String? artist,
    Duration? duration,
    bool hasStoryNav = false,
  }) {
    if (id.isEmpty) return;
    _hasStoryNav = hasStoryNav;
    mediaItem.add(
      MediaItem(
        id: id,
        title: title,
        album: album,
        artist: artist,
        duration: duration,
        playable: true,
      ),
    );
    _broadcast(force: true);
  }

  /// Updates only the duration once the real value is known, keeping the rest
  /// of the now-playing metadata intact.
  void updateDuration(Duration duration) {
    final current = mediaItem.value;
    if (current == null || duration <= Duration.zero) return;
    if (current.duration == duration) return;
    mediaItem.add(current.copyWith(duration: duration));
  }

  /// Mirrors the app's chosen speed into the media session without touching
  /// the player — the page decides when the new rate actually applies.
  void updateSpeed(double speed) {
    _speed = speed;
    _broadcast(force: true);
  }

  /// Speed change requested by the OS rather than by the app.
  @override
  Future<void> setSpeed(double speed) async {
    updateSpeed(speed);
    await voicePlayer.setPlaybackRate(speed);
  }

  /// Clears the lock-screen item. Call when playback is genuinely finished
  /// rather than merely paused.
  Future<void> clearNowPlaying() async {
    _processingState = AudioProcessingState.idle;
    _position = Duration.zero;
    currentOwner = null;
    mediaItem.add(null);
    _broadcast(force: true);
  }

  void _wireStreams() {
    voicePlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
        case PlayerState.paused:
          _processingState = AudioProcessingState.ready;
        case PlayerState.completed:
          _processingState = AudioProcessingState.completed;
        case PlayerState.stopped:
        case PlayerState.disposed:
          _processingState = AudioProcessingState.idle;
      }
      _broadcast(force: true);
    });

    voicePlayer.onPositionChanged.listen((position) {
      _position = position;
      _broadcast();
    });

    voicePlayer.onDurationChanged.listen(updateDuration);

    voicePlayer.onPlayerComplete.listen((_) {
      _position = Duration.zero;
      _processingState = AudioProcessingState.completed;
      _broadcast(force: true);
    });
  }

  /// Position events arrive several times a second; the media session only
  /// needs one update per second because it extrapolates between them.
  void _broadcast({bool force = false}) {
    if (!force && _position.inSeconds == _lastBroadcastSecond) return;
    _lastBroadcastSecond = _position.inSeconds;

    final playing = voicePlayer.state == PlayerState.playing;
    final controls = <MediaControl>[
      if (_hasStoryNav) MediaControl.skipToPrevious,
      if (playing) MediaControl.pause else MediaControl.play,
      if (_hasStoryNav) MediaControl.skipToNext,
    ];

    playbackState.add(
      playbackState.value.copyWith(
        controls: controls,
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices:
            List<int>.generate(controls.length, (i) => i),
        processingState: _processingState,
        playing: playing,
        updatePosition: _position,
        speed: _speed,
      ),
    );
  }

  @override
  Future<void> play() async {
    final callback = onPlayRequested;
    if (callback != null) {
      await callback();
      return;
    }
    await voicePlayer.resume();
  }

  @override
  Future<void> pause() async {
    final callback = onPauseRequested;
    if (callback != null) {
      await callback();
      return;
    }
    await voicePlayer.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    final callback = onSeekRequested;
    if (callback != null) {
      await callback(position);
      return;
    }
    await voicePlayer.seek(position);
  }

  @override
  Future<void> skipToNext() async => onSkipNextRequested?.call();

  @override
  Future<void> skipToPrevious() async => onSkipPreviousRequested?.call();

  @override
  Future<void> stop() async {
    await voicePlayer.stop();
    await thetaPlayer.stop();
    await clearNowPlaying();
    await super.stop();
  }
}

/// Convenience accessor used across pages.
StoryAudioHandler get storyAudio => StoryAudioHandler.instance;

bool _audioServiceStarted = false;

/// Registers the media session. Safe to call more than once, and safe to fail:
/// playback still works without a lock-screen item.
Future<void> initStoryAudio() async {
  if (_audioServiceStarted) return;
  _audioServiceStarted = true;
  try {
    await AudioService.init(
      builder: () => StoryAudioHandler.instance,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.alreadydone.myapp.playback',
        androidNotificationChannelName: 'Story playback',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
    await StoryAudioHandler.instance.applyAudioContext();
  } catch (e, st) {
    debugPrint('AudioService init failed: $e');
    debugPrint('$st');
  }
}
