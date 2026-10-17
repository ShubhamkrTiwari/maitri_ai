import 'package:speech_to_text/speech_to_text.dart' as stt;

class SttService {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;
  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    try {
      _isAvailable = await _speech.initialize(
        onError: (val) => print('STT Error: $val'),
        onStatus: (val) => print('STT Status: $val'),
      );
      return _isAvailable;
    } catch (_) {
      return false;
    }
  }

  Future<void> startListening({
    required Function(String text) onResult,
    String localeId = 'en_US',
  }) async {
    try {
      if (!_isAvailable) {
        final initSuccess = await initialize();
        if (!initSuccess) {
          // Fallback demo speech if mic hardware or browser permission not granted
          onResult("Hello Maitri, tell me a motivation tip.");
          return;
        }
      }

      await _speech.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: localeId,
      );
    } catch (_) {
      onResult("Hello Maitri, tell me a motivation tip.");
    }
  }

  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }
}
