import 'dart:convert';
import 'base_api_service.dart';
import '../../core/utils/logger.dart';

class AIApiService extends BaseApiService {
  static const String unavailableMessage = 'AI is temporarily unavailable.';
  static const Duration _timeout = Duration(seconds: 12);

  Future<String> sendMessage({
    required String message,
    List<Map<String, String>> history = const [],
    String language = 'en',
    Map<String, dynamic>? location,
    String? role,
    String? userId,
    String? sessionId,
  }) async {
    try {
      final response = await post(
        '/api/gemini',
        timeout: _timeout,
        body: {
          'message': message,
          'history': history,
          'language': language,
          'location': location,
          'role': role,
          'userId': userId,
          'sessionId': sessionId,
        },
      );

      if (response.statusCode == 200) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final text = data['response'];
        if (text is! String || text.trim().isEmpty) {
          throw ApiException(unavailableMessage, code: 'ai_unavailable');
        }
        return text;
      }
      throw ApiException(
        'Failed to get AI response (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    } on ApiException catch (e) {
      if (e.code == 'ai_unavailable' ||
          e.code == 'network_timeout' ||
          e.statusCode == 503) {
        AppLogger.error('AI request failed', error: e);
        throw ApiException(
          unavailableMessage,
          statusCode: e.statusCode,
          code: 'ai_unavailable',
          originalError: e,
        );
      }
      AppLogger.error('Send message failed', error: e);
      rethrow;
    } catch (e) {
      AppLogger.error('Send message failed', error: e);
      rethrow;
    }
  }
}
