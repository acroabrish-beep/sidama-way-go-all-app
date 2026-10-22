import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../models/ai_message.dart';
import '../utils/language_provider.dart';
import '../services/ai_service.dart';

class AiAssistantProvider with ChangeNotifier {
  final List<AiMessage> _messages = [];
  bool _isTyping = false;
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool _isListening = false;

  List<AiMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  bool get isListening => _isListening;

  AiAssistantProvider() {
    _initTts();
  }

  void _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
  }

  Future<void> startListening(AppLanguage lang) async {
    bool available = await _stt.initialize();
    if (available) {
      _isListening = true;
      notifyListeners();
      _stt.listen(
        onResult: (result) {
          if (result.finalResult) {
            sendMessage(result.recognizedWords, lang);
            stopListening();
          }
        },
      );
    }
  }

  void stopListening() {
    _stt.stop();
    _isListening = false;
    notifyListeners();
  }

  void sendMessage(String text, AppLanguage lang) {
    _messages.insert(0, AiMessage(text: text, sender: MessageSender.user, timestamp: DateTime.now()));
    notifyListeners();
    _getAiResponse(text, lang);
  }

  void _getAiResponse(String userText, AppLanguage lang) async {
    _isTyping = true;
    notifyListeners();

    final aiService = NextJSAIServiceImpl();
    final langCode = lang == AppLanguage.amharic ? 'am' : lang == AppLanguage.sidaamuAfoo ? 'sid' : 'en';

    final history = _messages
        .where((m) => m.sender == MessageSender.user || m.sender == MessageSender.ai)
        .take(10)
        .map((m) => {
              'role': m.sender == MessageSender.user ? 'user' : 'assistant',
              'content': m.text
            })
        .toList()
        .reversed
        .toList();

    // Remove current user message from history as it's passed separately in chat()
    if (history.isNotEmpty && history.last['content'] == userText) {
      history.removeLast();
    }

    try {
      final response = await aiService.chat(userText, langCode, history: history);
      _messages.insert(0, AiMessage(text: response, sender: MessageSender.ai, timestamp: DateTime.now()));
    } catch (e) {
      _messages.insert(0, AiMessage(text: "I encountered an error connecting to the city AI network.", sender: MessageSender.ai, timestamp: DateTime.now()));
    }

    _isTyping = false;
    notifyListeners();
    if (_messages.isNotEmpty && _messages.first.sender == MessageSender.ai) {
      _speak(_messages.first.text, lang);
    }
  }

  void _speak(String text, AppLanguage lang) async {
    if (lang == AppLanguage.amharic) {
      await _tts.setLanguage("am-ET");
    } else if (lang == AppLanguage.sidaamuAfoo) {
      // Sidaamu Afoo often maps to specialized or generic African/English accents if not native
      await _tts.setLanguage("en-ZA");
    } else {
      await _tts.setLanguage("en-US");
    }
    await _tts.speak(text);
  }
}
