import 'package:flutter_tts/flutter_tts.dart';

class TTSHelper {
  static final TTSHelper _instance = TTSHelper._internal();
  static FlutterTts? _flutterTts;

  factory TTSHelper() => _instance;

  TTSHelper._internal();

  Future<FlutterTts> get flutterTts async {
    if (_flutterTts != null) return _flutterTts!;
    
    _flutterTts = FlutterTts();
    
    // 프랑스어 설정
    await _flutterTts!.setLanguage("fr-FR");
    await _flutterTts!.setSpeechRate(0.5); // 말하기 속도 (0.1 ~ 1.0)
    await _flutterTts!.setVolume(1.0); // 볼륨 (0.0 ~ 1.0)
    await _flutterTts!.setPitch(1.0); // 음조 (0.5 ~ 2.0)
    
    return _flutterTts!;
  }

  // 프랑스어 단어 발음
  Future<void> speakFrench(String text) async {
    try {
      final tts = await flutterTts;
      await tts.speak(text);
    } catch (e) {
      print('TTS 오류: $e');
    }
  }

  // TTS 중지
  Future<void> stop() async {
    try {
      final tts = await flutterTts;
      await tts.stop();
    } catch (e) {
      print('TTS 중지 오류: $e');
    }
  }

  // 사용 가능한 언어 확인
  Future<List<dynamic>> getAvailableLanguages() async {
    try {
      final tts = await flutterTts;
      return await tts.getLanguages;
    } catch (e) {
      print('언어 목록 가져오기 오류: $e');
      return [];
    }
  }
} 