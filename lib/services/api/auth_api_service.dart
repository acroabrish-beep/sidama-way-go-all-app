import 'dart:convert';
import 'base_api_service.dart';
import '../../core/utils/logger.dart';

class AuthApiService extends BaseApiService {
  // Sync Firebase user with Supabase (upsert - returns user profile)
  Future<Map<String, dynamic>> syncUser({
    required String firebaseUid,
    required String email,
    String? fullName,
    String? phone,
    String role = 'citizen',
    String language = 'en',
    String? userType,
    String? city,
  }) async {
    try {
      final body = <String, dynamic>{
        'firebaseUid': firebaseUid,
        'email': email,
        'role': role,
        'language': language,
      };
      
      if (fullName != null) body['fullName'] = fullName;
      if (phone != null) body['phone'] = phone;
      if (userType != null) body['userType'] = userType;
      if (city != null) body['city'] = city;

      AppLogger.info('POST sync request - Endpoint: /api/auth/sync');
      AppLogger.info('POST sync body - firebaseUid: $firebaseUid, email: $email, role: $role, userType: ${userType ?? role}');

      final response = await post(
        '/api/auth/sync',
        body: body,
      );

      AppLogger.info('POST sync response - HTTP Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final user = data['user'] as Map<String, dynamic>;
        AppLogger.info('Backend returned user profile - role: ${user['role']}, user_type: ${user['user_type']}');
        return user;
      } else if (response.statusCode == 503) {
        AppLogger.warning('Database schema misalignment detected. Run migration alignment.');
        throw Exception('Database schema misalignment');
      } else {
        AppLogger.error('Auth Sync Error: ${response.statusCode}');
        throw Exception('Failed to sync user with backend: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Sync user failed', error: e);
      rethrow;
    }
  }

  // Get user profile from Supabase
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid) async {
    try {
      AppLogger.info('GET user profile request - firebaseUid: $firebaseUid');
      
      final response = await get(
        '/api/auth/sync',
        queryParams: {'firebaseUid': firebaseUid},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user'] as Map<String, dynamic>;
      } else if (response.statusCode == 503) {
        AppLogger.warning('Database schema misalignment detected.');
        throw Exception('Database schema misalignment');
      } else {
        AppLogger.error('Get User Profile Error: ${response.statusCode}');
        throw Exception('Failed to get user profile: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Get user profile failed', error: e);
      rethrow;
    }
  }
}
