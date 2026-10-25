import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/emergency_sos_models.dart';
import 'base_api_service.dart';

/// Phase 3 emergency incidents backed by public.emergency_incidents.
///
/// Citizens can insert and read their own requests. Emergency staff
/// (super_admin, city_admin, emergency_admin, dispatcher) can read every
/// incident and advance its status. The database trigger fills the legacy
/// reporter_id / incident_type / severity / location columns.
class EmergencyApiService {
  static const _table = 'emergency_incidents';
  static const _columns =
      'id, incident_code, requester_firebase_uid, emergency_type, priority, '
      'status, description, latitude, longitude, assignee_firebase_uid, '
      'created_at, updated_at, resolved_at';
  static const _timeout = Duration(seconds: 20);
  static const _updatableStatuses = {
    'acknowledged',
    'in_progress',
    'resolved',
    'closed',
  };

  SupabaseClient get _client => Supabase.instance.client;

  String _requireUid(String action) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw ApiException(
        'Sign in to $action.',
        statusCode: 401,
        code: 'not_authenticated',
      );
    }
    return uid;
  }

  Future<EmergencyIncidentModel> createRequest({
    required EmergencyRequestType type,
    required double latitude,
    required double longitude,
    String? description,
    String priority = 'critical',
  }) async {
    final uid = _requireUid('send an emergency request');
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ApiException(
        'The captured GPS location is not valid. Move to an open area and retry.',
        code: 'invalid_location',
      );
    }

    final trimmedDescription = description?.trim();
    try {
      final row = await _client
          .from(_table)
          .insert({
            'requester_firebase_uid': uid,
            'latitude': latitude,
            'longitude': longitude,
            'emergency_type': type.wireValue,
            'priority': priority,
            'status': 'reported',
            'description':
                trimmedDescription == null || trimmedDescription.isEmpty
                ? type.defaultDescription
                : trimmedDescription,
          })
          .select(_columns)
          .single()
          .timeout(_timeout);
      return _mapRow(row);
    } on PostgrestException catch (error) {
      throw _mapError(error, 'send the emergency request');
    } on TimeoutException {
      throw ApiException(
        'The emergency request timed out. Check your active requests before retrying.',
        code: 'network_timeout',
      );
    }
  }

  Future<EmergencyIncidentModel?> findActiveRequest() async {
    final uid = _requireUid('load your emergency request');
    try {
      final row = await _client
          .from(_table)
          .select(_columns)
          .eq('requester_firebase_uid', uid)
          .inFilter('status', EmergencyIncidentModel.activeStatuses)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(_timeout);
      return row == null ? null : _mapRow(row);
    } on PostgrestException catch (error) {
      throw _mapError(error, 'load your emergency request');
    } on TimeoutException {
      throw ApiException(
        'Loading your emergency request timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<EmergencyIncidentModel> getRequest(String incidentId) async {
    _requireUid('load the emergency request');
    final id = incidentId.trim();
    if (id.isEmpty) {
      throw ApiException(
        'Choose an emergency request to load.',
        code: 'invalid_request',
      );
    }
    try {
      final row = await _client
          .from(_table)
          .select(_columns)
          .eq('id', id)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) {
        throw ApiException(
          'This emergency request is no longer visible. Refresh the list.',
          statusCode: 404,
          code: 'not_found',
        );
      }
      return _mapRow(row);
    } on PostgrestException catch (error) {
      throw _mapError(error, 'load the emergency request');
    } on TimeoutException {
      throw ApiException(
        'Loading the emergency request timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<List<EmergencyIncidentModel>> listIncidents({int limit = 50}) async {
    _requireUid('load emergency incidents');
    try {
      final rows = await _client
          .from(_table)
          .select(_columns)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);
      return rows.map(_mapRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw _mapError(error, 'load emergency incidents');
    } on TimeoutException {
      throw ApiException(
        'Loading emergency incidents timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<List<EmergencyIncidentModel>> listActiveIncidents({
    int limit = 200,
  }) async {
    _requireUid('load active emergency incidents');
    try {
      final rows = await _client
          .from(_table)
          .select(_columns)
          .inFilter('status', EmergencyIncidentModel.activeStatuses)
          .order('created_at', ascending: false)
          .limit(limit)
          .timeout(_timeout);
      return rows.map(_mapRow).toList(growable: false);
    } on PostgrestException catch (error) {
      throw _mapError(error, 'load active emergency incidents');
    } on TimeoutException {
      throw ApiException(
        'Loading active emergency incidents timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  Future<EmergencyIncidentModel> updateStatus({
    required String incidentId,
    required String status,
    String? assigneeFirebaseUid,
  }) async {
    _requireUid('update the emergency incident');
    final id = incidentId.trim();
    final nextStatus = status.trim().toLowerCase();
    if (id.isEmpty) {
      throw ApiException(
        'Choose an emergency incident to update.',
        code: 'invalid_request',
      );
    }
    if (!_updatableStatuses.contains(nextStatus)) {
      throw ApiException(
        'That emergency status is not supported.',
        code: 'invalid_request',
      );
    }

    final patch = <String, dynamic>{
      'status': nextStatus,
      if (assigneeFirebaseUid != null && assigneeFirebaseUid.trim().isNotEmpty)
        'assignee_firebase_uid': assigneeFirebaseUid.trim(),
    };

    try {
      final row = await _client
          .from(_table)
          .update(patch)
          .eq('id', id)
          .select(_columns)
          .maybeSingle()
          .timeout(_timeout);
      if (row == null) {
        throw ApiException(
          'This incident was not found, or your account is not emergency staff.',
          statusCode: 403,
          code: 'not_permitted',
        );
      }
      return _mapRow(row);
    } on PostgrestException catch (error) {
      throw _mapError(error, 'update the emergency incident');
    } on TimeoutException {
      throw ApiException(
        'Updating the emergency incident timed out. Refresh before retrying.',
        code: 'network_timeout',
      );
    }
  }

  EmergencyIncidentModel _mapRow(Map<String, dynamic> row) {
    try {
      return EmergencyIncidentModel.fromRow(row);
    } on FormatException {
      throw ApiException(
        'The emergency record could not be read. Refresh the list.',
        code: 'invalid_response',
      );
    }
  }

  ApiException _mapError(PostgrestException error, String action) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'You do not have permission to $action.',
          statusCode: 403,
          code: error.code,
          originalError: error,
        );
      case '23503':
        return ApiException(
          'Your profile is not synced yet. Sign out and back in, then retry.',
          code: error.code,
          originalError: error,
        );
      case '23502':
        return ApiException(
          'A GPS location is required for an emergency request.',
          code: error.code,
          originalError: error,
        );
      case '22023':
        return ApiException(
          'The captured GPS location is not valid. Move to an open area and retry.',
          code: error.code,
          originalError: error,
        );
      case '23514':
        return ApiException(
          'That emergency status change is not allowed. Refresh the list.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST116':
        return ApiException(
          'The emergency record could not be read. Refresh the list.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST301':
      case 'PGRST302':
        return ApiException(
          'Your session has expired. Sign in again.',
          statusCode: 401,
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
}
