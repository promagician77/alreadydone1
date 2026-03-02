import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:mp_audio_stream/mp_audio_stream.dart';

/// Generates a soft, sleep-inducing sound: gentle binaural theta waves
/// (4–8 Hz) plus very low-level brown noise for a soothing background.
/// Designed to be barely perceptible—soft enough for sleep.
///
/// How it works:
/// - Left channel: base frequency (e.g., 150 Hz) + soft brown noise
/// - Right channel: base + theta frequency (e.g., 156 Hz) + soft brown noise
/// - Brain perceives the difference as theta state (relaxation, light sleep)
class ThetaWaveGenerator {
  ThetaWaveGenerator({
    this.frequency = 6.0,
    this.baseFrequency = 150.0,
    this.volume = 0.05,
    this.sampleRate = 44100,
    this.bufferSizeSeconds = 0.5,
  });

  /// Theta frequency in Hz (4–8 recommended; 6 = light sleep/meditation).
  double frequency;

  /// Carrier frequency in Hz (default 150 — softer than 200 Hz).
  double baseFrequency;

  /// Volume level 0.0 to 1.0 (default 0.05 = 5% — very soft for sleep).
  double volume;

  /// Sample rate in Hz.
  int sampleRate;

  /// Seconds of audio per buffer for smooth playback.
  double bufferSizeSeconds;

  final AudioStream _stream = getAudioStream();

  bool _isPlaying = false;
  Future<void>? _playbackFuture;
  int _globalSampleIndex = 0;
  double _brownNoise = 0.0;

  /// Whether theta waves are currently playing.
  bool get isPlaying => _isPlaying;

  /// Initialize the audio stream. Call once before [start].
  void init() {
    _stream.init(channels: 2);
  }

  /// Resume playback (required on web after user interaction).
  void resume() {
    _stream.resume();
  }

  /// Start generating theta waves.
  void start() {
    if (_isPlaying) return;
    init();
    resume();
    _isPlaying = true;
    _globalSampleIndex = 0;
    _playbackFuture = _runPlayback();
  }

  /// Stop theta waves immediately.
  void stop() {
    _isPlaying = false;
    _playbackFuture = null;
    _stream.uninit();
  }

  /// Set volume (0.0 to 1.0). Takes effect on next buffer.
  void setVolume(double vol) {
    volume = vol.clamp(0.0, 1.0);
  }

  /// Set theta frequency in Hz (4–8). Takes effect on next buffer.
  void changeFrequency(double newFrequency) {
    frequency = newFrequency.clamp(4.0, 8.0);
  }

  Future<void> _runPlayback() async {
    final rate = sampleRate;
    final samplesPerBuffer = (rate * bufferSizeSeconds).round();
    final sampleCount = samplesPerBuffer * 2; // stereo
    final buffer = Float32List(sampleCount);

    final rand = math.Random();
    while (_isPlaying) {
      final freqL = baseFrequency;
      final freqR = baseFrequency + frequency;
      final vol = volume.clamp(0.0, 1.0);
      // Very soft brown noise (1/f²) mixed in — soothing, helps mask harshness.
      const brownNoiseLevel = 0.015;

      for (int i = 0; i < samplesPerBuffer; i++) {
        final t = (_globalSampleIndex + i) / rate;
        _brownNoise = 0.98 * _brownNoise + 0.02 * (rand.nextDouble() * 2 - 1);
        final brown = _brownNoise * brownNoiseLevel;
        buffer[i * 2] = (math.sin(2 * math.pi * freqL * t) * vol + brown).clamp(-1.0, 1.0);
        buffer[i * 2 + 1] = (math.sin(2 * math.pi * freqR * t) * vol + brown).clamp(-1.0, 1.0);
      }
      _globalSampleIndex += samplesPerBuffer;

      _stream.push(buffer);
      await Future<void>.delayed(Duration(
        milliseconds: (bufferSizeSeconds * 1000).round().clamp(1, 500),
      ));
    }
  }
}
