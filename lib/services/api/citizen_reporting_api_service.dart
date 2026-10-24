import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/citizen_report_model.dart';
import 'base_api_service.dart';

class ReportsPage {
  const ReportsPage({required this.reports, required this.serverTime});

  final List<CitizenReport> reports;
  final DateTime serverTime;
}

class CitizenReportingApiService {
  static const _table = 'citizen_reports';
  static const _listLimit = 200;
  static const _timeout = Duration(seconds: 30);

  SupabaseClient get _client => Supabase.instance.client;

  String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw ApiException(
        'Sign in to continue.',
        statusCode: 401,
        code: 'not_authenticated',
      );
    }
    return uid;
  }

  CitizenReport _report(Map<String, dynamic> row) {
    final id = row['id']?.toString();
    if (id == null || id.isEmpty) {
      throw ApiException(
        'The saved report could not be read.',
        code: 'invalid_response',
      );
    }
    return CitizenReport.fromMap(row, id);
  }

  DateTime _nextWatermark(List<CitizenReport> reports, DateTime? previous) {
    if (reports.isEmpty) {
      return previous?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    var latest = reports.first.updatedAt.toUtc();
    for (final report in reports.skip(1)) {
      final updated = report.updatedAt.toUtc();
      if (updated.isAfter(latest)) latest = updated;
    }
    return latest;
  }

  ApiException _failure(PostgrestException error, String action) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'You do not have permission to $action.',
          code: error.code,
          originalError: error,
        );
      case '23503':
        return ApiException(
          'Your account is not ready yet. Sign in again and retry.',
          code: error.code,
          originalError: error,
        );
      case '23514':
        return ApiException(
          'Some report details are not valid.',
          code: error.code,
          originalError: error,
        );
      default:
        return ApiException(
          'Could not $action. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }

  Future<CitizenReport> createReport({
    required String category,
    String? description,
    String? photoUrl,
    required double latitude,
    required double longitude,
  }) async {
    final uid = _requireUid();
    final trimmedDescription = description?.trim();
    final trimmedPhotoUrl = photoUrl?.trim();

    if (trimmedPhotoUrl != null &&
        trimmedPhotoUrl.isNotEmpty &&
        (trimmedPhotoUrl.length > 2048 ||
            !trimmedPhotoUrl.startsWith('https://'))) {
      throw ApiException(
        'The photo URL is not valid.',
        code: 'invalid_photo_url',
      );
    }

    try {
      final row = await _client
          .from(_table)
          .insert({
            'reporter_firebase_uid': uid,
            'category': category,
            'latitude': latitude,
            'longitude': longitude,
            if (trimmedDescription != null && trimmedDescription.isNotEmpty)
              'description': trimmedDescription,
            if (trimmedPhotoUrl != null && trimmedPhotoUrl.isNotEmpty)
              'photo_url': trimmedPhotoUrl,
          })
          .select()
          .single()
          .timeout(_timeout);
      return _report(row);
    } on PostgrestException catch (error) {
      throw _failure(error, 'submit this report');
    } on TimeoutException {
      throw ApiException(
        'Submitting the report timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<ReportsPage> getMyReports({DateTime? updatedSince}) async {
    final uid = _requireUid();

    try {
      var query = _client
          .from(_table)
          .select()
          .eq('reporter_firebase_uid', uid);
      if (updatedSince != null) {
        query = query.gt('updated_at', updatedSince.toUtc().toIso8601String());
      }
      final rows = await query
          .order('created_at', ascending: false)
          .limit(_listLimit)
          .timeout(_timeout);
      final reports = rows.map(_report).toList(growable: false);

      // The database clock owns updated_at, so the newest value seen is a
      // safe watermark for the next incremental fetch.
      return ReportsPage(
        reports: reports,
        serverTime: _nextWatermark(reports, updatedSince),
      );
    } on PostgrestException catch (error) {
      throw _failure(error, 'load your reports');
    } on TimeoutException {
      throw ApiException(
        'Loading your reports timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<ReportsPage> getReportsForAdmin({
    String? status,
    DateTime? updatedSince,
  }) async {
    _requireUid();

    try {
      var query = _client.from(_table).select();
      if (status != null) {
        query = query.eq('status', status);
      }
      if (updatedSince != null) {
        query = query.gt('updated_at', updatedSince.toUtc().toIso8601String());
      }
      final rows = await query
          .order('created_at', ascending: false)
          .limit(_listLimit)
          .timeout(_timeout);
      final reports = rows.map(_report).toList(growable: false);

      return ReportsPage(
        reports: reports,
        serverTime: _nextWatermark(reports, updatedSince),
      );
    } on PostgrestException catch (error) {
      throw _failure(error, 'load reports');
    } on TimeoutException {
      throw ApiException(
        'Loading reports timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<CitizenReport> updateReport({
    required String reportId,
    String? status,
    String? finalCategory,
    String? finalUrgency,
  }) async {
    _requireUid();

    if (status == null && finalCategory == null && finalUrgency == null) {
      throw ApiException(
        'Choose a status or category to update.',
        code: 'invalid_request',
      );
    }

    final updates = <String, dynamic>{};
    if (status != null) {
      updates['status'] = status;
      final now = DateTime.now().toUtc().toIso8601String();
      if (status == 'in_progress') {
        updates['assigned_at'] = now;
      }
      if (status == 'resolved') {
        updates['resolved_at'] = now;
      }
    }
    if (finalCategory != null) {
      updates['final_category'] = finalCategory;
    }
    if (finalUrgency != null) {
      updates['final_urgency'] = finalUrgency;
    }

    try {
      final row = await _client
          .from(_table)
          .update(updates)
          .eq('id', reportId)
          .select()
          .maybeSingle()
          .timeout(_timeout);

      if (row == null) {
        throw ApiException(
          'Report not found or you do not have permission to update it.',
          statusCode: 404,
          code: 'not_found',
        );
      }
      return _report(row);
    } on PostgrestException catch (error) {
      throw _failure(error, 'update this report');
    } on TimeoutException {
      throw ApiException(
        'Updating the report timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }
}
