import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class VoiceRecordingService {
  VoiceRecordingService() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  String? _currentPath;

  Future<bool> isRecording() => _recorder.isRecording();

  Future<bool> requestPermission() async {
    final has = await _recorder.hasPermission();
    return has == true;
  }

  Future<String> start() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Voice recording is not supported on web. Please use the iOS or Android app.',
      );
    }
    if (await _recorder.isRecording()) throw StateError('Already recording');
    final granted = await requestPermission();
    if (!granted) {
      throw Exception('Microphone permission is required to record your voice.');
    }
    final dir = await getTemporaryDirectory();
    _currentPath = '${dir.path}/voice_clone_${DateTime.now().millisecondsSinceEpoch}.m4a';

    // Pick explicit input device (built-in mic) — default can route to wrong mic on some devices.
    InputDevice? device;
    try {
      final devices = await _recorder.listInputDevices();
      if (devices.isNotEmpty) {
        // Prefer device with "default", "mic", "built-in", or "voice" in name; else first.
        final preferred = devices.where((d) {
          final n = d.label.toLowerCase();
          return n.contains('default') ||
              n.contains('mic') ||
              n.contains('builtin') ||
              n.contains('built-in') ||
              n.contains('voice') ||
              n.contains('internal');
        }).toList();
        device = preferred.isNotEmpty ? preferred.first : devices.first;
      }
    } catch (_) {}

    // mic + useLegacy:false (AudioRecord). Enable noiseSuppress to reduce wind; some devices need it.
    final config = RecordConfig(
      encoder: AudioEncoder.aacLc,
      sampleRate: 44100,
      numChannels: 1,
      bitRate: 128000,
      autoGain: true,
      echoCancel: false,
      noiseSuppress: true,
      device: device,
      androidConfig: const AndroidRecordConfig(
        audioSource: AndroidAudioSource.mic,
        useLegacy: false,
      ),
    );

    await _recorder.start(config, path: _currentPath!);
    return _currentPath!;
  }

  Future<File?> stop() async {
    if (!await _recorder.isRecording()) return null;
    final path = await _recorder.stop();
    _currentPath = null;
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file;
  }

  Future<void> cancel() async {
    if (await _recorder.isRecording()) await _recorder.cancel();
    if (_currentPath != null) {
      try {
        final f = File(_currentPath!);
        if (await f.exists()) await f.delete();
      } catch (_) {}
      _currentPath = null;
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
