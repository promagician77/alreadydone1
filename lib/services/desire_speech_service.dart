import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Native STT: SFSpeechRecognizer (iOS) and SpeechRecognizer (Android).
class DesireSpeechService {
  DesireSpeechService() : _speech = SpeechToText();

  final SpeechToText _speech;
  bool _initialized = false;
  void Function(String status)? onStatus;
  void Function(String message)? onError;

  bool get isAvailable => _speech.isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_initialized) return _speech.isAvailable;
    _initialized = true;
    return _speech.initialize(
      onStatus: (status) => onStatus?.call(status),
      onError: (error) => onError?.call(error.errorMsg),
      debugLogging: kDebugMode,
    );
  }

  Future<bool> startListening({
    required void Function(String transcript) onTranscript,
    String localeId = 'en_US',
  }) async {
    if (!_speech.isAvailable) return false;
    if (_speech.isListening) return true;

    final result = await _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onTranscript(result.recognizedWords);
      },
      localeId: localeId,
      listenMode: ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(minutes: 10),
      pauseFor: const Duration(seconds: 5),
    );
    if (result is bool) return result;
    return true;
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
