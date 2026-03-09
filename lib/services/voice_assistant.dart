import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistant {
  VoiceAssistant._();
  static final VoiceAssistant instance = VoiceAssistant._();

  final FlutterTts _tts = FlutterTts();

  bool _ready = false;
  bool _speaking = false;
  String _currentLang = "en-US";

  Future<void> init({required String languageCode}) async {
    // Avoid repeating setup if same language
    if (_ready && _currentLang == languageCode) return;

    _currentLang = languageCode;

    await _tts.stop();

    try {
      await _tts.setLanguage(languageCode);
    } catch (_) {
      // fallback if language not available
      await _tts.setLanguage("en-US");
      _currentLang = "en-US";
    }

    // Clear voice speech settings
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    // Wait until speech finishes
    await _tts.awaitSpeakCompletion(true);

    // Android queue control
    try {
      await _tts.setQueueMode(0);
    } catch (_) {}

    // Track speaking state
    _tts.setStartHandler(() {
      _speaking = true;
    });

    _tts.setCompletionHandler(() {
      _speaking = false;
    });

    _tts.setCancelHandler(() {
      _speaking = false;
    });

    _ready = true;
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    if (!_ready) {
      await init(languageCode: _currentLang);
    }

    // Stop previous speech
    if (_speaking) {
      await _tts.stop();
    }

    await _tts.speak(text);
  }

  Future<void> stop() async {
    _speaking = false;
    await _tts.stop();
  }

  bool get isSpeaking => _speaking;

  String get currentLang => _currentLang;
}
