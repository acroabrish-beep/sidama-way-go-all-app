import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../config/app_config.dart';
import '../../core/utils/logger.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;
  final dynamic data;

  ApiException(
    this.message, {
    this.statusCode,
    this.originalError,
    this.data,
  });

  @override
  String toString() => message;
}

class BaseApiService {
  final String _baseUrl;
  final http.Client _client;

  BaseApiService({http.Client? client})
      : _baseUrl = AppConfig.apiBaseUrl,
        _client = client ?? http.Client();

  String get baseUrl => _baseUrl;

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint').replace(
        queryParameters: queryParams?.map(
          (key, value) => MapEntry(key, value.toString()),
        ),
      );

      AppLogger.info('GET Request: $uri');

      final response = await _withAuthRetry(
        (headers) => _client.get(uri, headers: headers),
        headers,
      ).timeout(const Duration(seconds: 30));

      _logResponse(response);
      _handleResponseError(response);
      return response;
    } on TimeoutException {
      throw ApiException('Request timeout. Please check your connection.');
    } on SocketException {
      throw ApiException('Cannot reach the server. Please check your internet or server status.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Failed to fetch')) {
        throw ApiException('Connection failed. This may be a CORS issue or the server is down.');
      }
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('GET Request failed: $endpoint', error: e);
      throw ApiException('An unexpected network error occurred.');
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      AppLogger.info('POST Request: $uri');

      final response = await _withAuthRetry(
        (headers) => _client.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
        headers,
      ).timeout(const Duration(seconds: 30));

      _logResponse(response);
      _handleResponseError(response);
      return response;
    } on TimeoutException {
      throw ApiException('Request timeout. Please try again.');
    } on SocketException {
      throw ApiException('Server unreachable. Please check if the backend is running.');
    } on http.ClientException catch (e) {
      if (e.message.contains('Failed to fetch')) {
        throw ApiException('Failed to connect to the backend. Ensure the server is running on port 3000 and CORS is enabled.');
      }
      throw ApiException('Network error: ${e.message}');
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('POST Request failed: $endpoint', error: e);
      throw ApiException('Failed to send data to the server.');
    }
  }

  Future<http.Response> patch(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      AppLogger.info('PATCH Request: $uri');

      final response = await _withAuthRetry(
        (headers) => _client.patch(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
        headers,
      ).timeout(const Duration(seconds: 30));

      _logResponse(response);
      _handleResponseError(response);
      return response;
    } on TimeoutException {
      throw ApiException('Request timeout.');
    } on SocketException {
      throw ApiException('Server unreachable.');
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('PATCH Request failed: $endpoint', error: e);
      throw ApiException('Failed to update data on the server.');
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl$endpoint');

      AppLogger.info('DELETE Request: $uri');

      final response = await _withAuthRetry(
        (headers) => _client.delete(uri, headers: headers),
        headers,
      ).timeout(const Duration(seconds: 30));

      _logResponse(response);
      _handleResponseError(response);
      return response;
    } on SocketException {
      throw ApiException('Server unreachable.');
    } catch (e) {
      if (e is ApiException) rethrow;
      AppLogger.error('DELETE Request failed: $endpoint', error: e);
      throw ApiException('Failed to delete data from the server.');
    }
  }

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? additionalHeaders, {
    bool forceRefresh = false,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Attach a Firebase ID token for authenticated requests. The SDK returns a
    // cached token until it is near expiry; forceRefresh is used after a 401.
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken(forceRefresh);
        if (idToken == null || idToken.isEmpty) {
          throw ApiException(
            'Authentication failed: no ID token available. Please sign in again.',
          );
        }
        headers['Authorization'] = 'Bearer $idToken';
      } on ApiException {
        rethrow;
      } catch (_) {
        // Never log the token or the raw Firebase error.
        throw ApiException(
          'Authentication failed while refreshing your session. Please sign in again.',
        );
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  Future<http.Response> _withAuthRetry(
    Future<http.Response> Function(Map<String, String> headers) send,
    Map<String, String>? additionalHeaders,
  ) async {
    var response = await send(await _buildHeaders(additionalHeaders));

    // A token can expire between acquisition and use. Refresh once and retry.
    if (response.statusCode == 401 &&
        FirebaseAuth.instance.currentUser != null) {
      response = await send(
        await _buildHeaders(additionalHeaders, forceRefresh: true),
      );
    }

    return response;
  }

  void _handleResponseError(http.Response response) {
    if (response.statusCode >= 400 && response.statusCode < 500) {
      try {
        final data = jsonDecode(response.body);
        throw ApiException(
          data['message'] ?? data['error'] ?? 'Invalid request',
          statusCode: response.statusCode,
          data: data,
        );
      } catch (e) {
        if (e is ApiException) rethrow;
        throw ApiException(
          'Client error (${response.statusCode})',
          statusCode: response.statusCode,
        );
      }
    } else if (response.statusCode >= 500) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['error'] is String) {
          throw ApiException(
            data['error'] as String,
            statusCode: response.statusCode,
            data: data,
          );
        }
      } catch (e) {
        if (e is ApiException) rethrow;
      }
      throw ApiException(
        'Server error. Our team has been notified.',
        statusCode: response.statusCode,
      );
    }
  }

  void _logResponse(http.Response response) {
    AppLogger.info('Response Status: ${response.statusCode}');
    if (response.statusCode >= 400) {
      AppLogger.error('Response Body: ${response.body}');
    }
  }

  void dispose() {
    _client.close();
  }
}
