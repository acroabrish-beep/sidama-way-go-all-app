import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../models/citizen_report_model.dart';
import 'base_api_service.dart';

class ReportsPage {
  const ReportsPage({required this.reports, required this.serverTime});

  final List<CitizenReport> reports;
  final DateTime serverTime;
}

class CitizenReportingApiService extends BaseApiService {
  Map<String, dynamic> _json(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is Map<String, dynamic>) return decoded;
    throw ApiException('Unexpected server response');
  }

  CitizenReport _report(Map<String, dynamic> data) {
    final report = data['report'];
    if (report is! Map<String, dynamic>) {
      throw ApiException('The server did not return the saved report.');
    }
    return CitizenReport.fromMap(report, report['id'].toString());
  }

  ReportsPage _page(Map<String, dynamic> data) {
    final rawReports = data['reports'];
    final reports = rawReports is List
        ? rawReports
              .whereType<Map<String, dynamic>>()
              .map((item) => CitizenReport.fromMap(item, item['id'].toString()))
              .toList(growable: false)
        : const <CitizenReport>[];
    final serverTime = DateTime.tryParse(data['serverTime']?.toString() ?? '');
    return ReportsPage(
      reports: reports,
      serverTime: (serverTime ?? DateTime.now()).toUtc(),
    );
  }

  Future<CitizenReport> createReport({
    required String firebaseUid,
    required String category,
    String? description,
    String? photoUrl,
    required double latitude,
    required double longitude,
  }) async {
    final response = await post(
      '/api/citizen-reporting',
      body: {
        'firebaseUid': firebaseUid,
        'category': category,
        'latitude': latitude,
        'longitude': longitude,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (photoUrl != null && photoUrl.isNotEmpty) 'photoUrl': photoUrl,
      },
    );
    if (response.statusCode != 201) {
      throw ApiException(
        'Failed to create report: ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return _report(_json(response));
  }

  Future<ReportsPage> getMyReports({
    required String firebaseUid,
    DateTime? updatedSince,
  }) async {
    final response = await get(
      '/api/citizen-reporting',
      queryParams: {
        'firebaseUid': firebaseUid,
        'updatedSince': ?updatedSince?.toUtc().toIso8601String(),
      },
    );
    return _page(_json(response));
  }

  Future<ReportsPage> getReportsForAdmin({
    required String adminFirebaseUid,
    String? status,
    DateTime? updatedSince,
  }) async {
    final response = await get(
      '/api/citizen-reporting',
      queryParams: {
        'admin': 'true',
        'adminFirebaseUid': adminFirebaseUid,
        'status': ?status,
        'updatedSince': ?updatedSince?.toUtc().toIso8601String(),
      },
    );
    return _page(_json(response));
  }

  Future<CitizenReport> updateReport({
    required String reportId,
    String? status,
    String? finalCategory,
    String? finalUrgency,
  }) async {
    final response = await patch(
      '/api/citizen-reporting',
      body: {
        'reportId': reportId,
        'status': ?status,
        'finalCategory': ?finalCategory,
        'finalUrgency': ?finalUrgency,
      },
    );
    return _report(_json(response));
  }
}
