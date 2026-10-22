import 'dart:convert';
import 'base_api_service.dart';
import '../../core/utils/logger.dart';

class CitizenReportingApiService extends BaseApiService {
  /// Create a new citizen report
  Future<Map<String, dynamic>> createReport({
    required String firebaseUid,
    required String category,
    String? description,
    String? photoUrl,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final body = <String, dynamic>{
        'firebaseUid': firebaseUid,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
      };

      if (description != null && description.isNotEmpty) {
        body['description'] = description;
      }

      if (photoUrl != null && photoUrl.isNotEmpty) {
        body['photoUrl'] = photoUrl;
      }

      AppLogger.info('POST createReport request - Endpoint: /api/citizen-reporting');
      AppLogger.info('POST createReport body - firebaseUid: $firebaseUid, category: $category');

      final response = await post(
        '/api/citizen-reporting',
        body: body,
      );

      AppLogger.info('POST createReport response - HTTP Status: ${response.statusCode}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final report = data['report'] as Map<String, dynamic>;
        AppLogger.info('Report created successfully - ID: ${report['id']}');
        return report;
      } else {
        AppLogger.error('Create Report Error: ${response.statusCode}');
        throw Exception('Failed to create report: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Create report failed', error: e);
      rethrow;
    }
  }

  /// Get the current user's reports
  Future<List<Map<String, dynamic>>> getMyReports(String firebaseUid) async {
    try {
      AppLogger.info('GET myReports request - firebaseUid: $firebaseUid');

      final response = await get(
        '/api/citizen-reporting',
        queryParams: {'firebaseUid': firebaseUid},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reports = data['reports'] as List<dynamic>;
        AppLogger.info('Retrieved ${reports.length} reports for user');
        return reports.cast<Map<String, dynamic>>();
      } else {
        AppLogger.error('Get My Reports Error: ${response.statusCode}');
        throw Exception('Failed to get reports: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Get my reports failed', error: e);
      rethrow;
    }
  }
}
