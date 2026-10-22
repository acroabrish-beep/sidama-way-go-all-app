import 'dart:convert';
import 'base_api_service.dart';
import '../../core/utils/logger.dart';

class AIApiService extends BaseApiService {
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
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final text = data['response'];
        if (text is! String || text.trim().isEmpty) {
          throw ApiException('The AI service returned an empty response.');
        }
        return text;
      }
      throw ApiException('Failed to get AI response (${response.statusCode}).');
    } catch (e) {
      AppLogger.error('Send message failed', error: e);
      rethrow;
    }
  }
}