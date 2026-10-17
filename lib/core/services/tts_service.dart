import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;

  final FlutterTts _tts = FlutterTts();
  String _currentLang = 'en-US';

  TtsService._internal() {
    _initTts();
  }

  void _initTts() async {
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
    } catch (_) {}
  }

  Future<void> speak(String text, {double pitch = 1.0, double rate = 0.5, String language = 'English'}) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    try {
      final targetLang = (language == 'Hindi') ? 'hi-IN' : 'en-US';
      if (_currentLang != targetLang) {
        _currentLang = targetLang;
        await _tts.setLanguage(targetLang);
      }

      await _tts.setPitch(pitch);
      await _tts.setSpeechRate(rate);

      await _tts.speak(cleanText);
    } catch (_) {}
  }

  Future<void> speakNow(String text, {double pitch = 1.0, double rate = 0.5, String language = 'English'}) =>
      speak(text, pitch: pitch, rate: rate, language: language);

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
