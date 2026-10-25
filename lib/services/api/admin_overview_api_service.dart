import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/admin_overview_models.dart';
import 'base_api_service.dart';

/// Reads the real Super Admin metrics from public.get_admin_overview().
///
/// The RPC is SECURITY DEFINER and rejects callers that are not an active
/// super_admin/admin, so no aggregate query is exposed to the client.
class AdminOverviewApiService {
  static const _rpc = 'get_admin_overview';

  SupabaseClient get _client => Supabase.instance.client;

  Future<AdminOverview> getOverview({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    try {
      final response = await _client.rpc(_rpc).timeout(timeout);
      final Map<String, dynamic> json;
      if (response is Map<String, dynamic>) {
        json = response;
      } else if (response is Map) {
        json = Map<String, dynamic>.from(response);
      } else {
        throw ApiException(
          'The server returned an unexpected overview response.',
          code: 'invalid_response',
        );
      }

      try {
        return AdminOverview.fromJson(json);
      } on FormatException catch (error) {
        throw ApiException(
          'The server returned an unexpected overview response.',
          code: 'invalid_response',
          originalError: error,
        );
      }
    } on PostgrestException catch (error) {
      throw _mapError(error);
    } on TimeoutException {
      throw ApiException(
        'Loading the admin overview timed out. Please try again.',
        code: 'network_timeout',
      );
    }
  }

  ApiException _mapError(PostgrestException error) {
    switch (error.code) {
      case '42501':
        return ApiException(
          'This account does not have super administrator access.',
          statusCode: 403,
          code: error.code,
          originalError: error,
        );
      case 'PGRST202':
        return ApiException(
          'The admin overview service is not available yet. Try again later.',
          code: error.code,
          originalError: error,
        );
      case 'PGRST301':
      case 'PGRST302':
        return ApiException(
          'Your session has expired. Sign in again to load city metrics.',
          statusCode: 401,
          code: error.code,
          originalError: error,
        );
      default:
        return ApiException(
          'Could not load the admin overview. Please try again.',
          code: error.code,
          originalError: error,
        );
    }
  }
}
