import '../core/utils/logger.dart';
import 'api/ai_api_service.dart';

abstract class AIService {
  Future<String> chat(String userMessage, String language, {List<Map<String, String>> history, Map<String, dynamic>? location, String? role, String? userId, String? sessionId});
}

class NextJSAIServiceImpl implements AIService {
  final AIApiService _apiService = AIApiService();
  String? _currentSessionId;

  NextJSAIServiceImpl();

  @override
  Future<String> chat(
    String userMessage,
    String language, {
    List<Map<String, String>> history = const [],
    Map<String, dynamic>? location,
    String? role,
    String? userId,
    String? sessionId,
  }) async {
    try {
      // Use provided session ID or generate one
      _currentSessionId = sessionId ?? _currentSessionId ?? 'session_${DateTime.now().millisecondsSinceEpoch}';
      
      AppLogger.info('Sending AI request to Next.js backend with session: $_currentSessionId');
      
      final response = await _apiService.sendMessage(
        message: userMessage,
        history: history,
        language: language,
        location: location,
        role: role,
        userId: userId,
        sessionId: _currentSessionId,
      );

      AppLogger.info('AI response received successfully');
      return response;
    } catch (e) {
      AppLogger.error('AI Service Exception', error: e);
      // Never fabricate an AI answer. The UI shows an honest error instead.
      rethrow;
    }
  }

  String get currentSessionId => _currentSessionId ?? '';
  
  void clearSession() {
    _currentSessionId = null;
  }
}
