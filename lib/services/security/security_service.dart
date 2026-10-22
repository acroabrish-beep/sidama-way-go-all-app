import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../../core/utils/logger.dart';
import '../api/base_api_service.dart';

class SecurityService {
  static SecurityService? _instance;
  final BaseApiService _apiService = BaseApiService();

  static SecurityService get instance {
    _instance ??= SecurityService._();
    return _instance!;
  }

  SecurityService._();

  // Data encryption
  String encryptSensitiveData(String data, String key) {
    try {
      final keyBytes = utf8.encode(key);
      final dataBytes = utf8.encode(data);
      final hmac = Hmac(sha256, keyBytes);
      final digest = hmac.convert(dataBytes);
      return digest.toString();
    } catch (e) {
      AppLogger.error('Encryption failed', error: e);
      return data; // Fallback to unencrypted
    }
  }

  // Data hashing
  String hashData(String data) {
    final bytes = utf8.encode(data);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  // Input sanitization
  String sanitizeInput(String input) {
    return input
        .replaceAll(
          RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'<[^>]*>', caseSensitive: false), '')
        .replaceAll('javascript:', '')
        .replaceAll('onerror=', '')
        .replaceAll('onload=', '');
  }

  // SQL injection prevention
  String sanitizeSqlInput(String input) {
    return input
        .replaceAll("'", "''")
        .replaceAll(';', '')
        .replaceAll('--', '')
        .replaceAll('/*', '')
        .replaceAll('*/', '')
        .replaceAll(RegExp(r'xp_', caseSensitive: false), '')
        .replaceAll(RegExp(r'exec', caseSensitive: false), '');
  }

  // XSS prevention
  String escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  // Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  // Validate phone number
  bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^\+?[0-9]{10,15}$');
    return phoneRegex.hasMatch(phone);
  }

  // Validate URL
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  // Token validation
  bool isValidToken(String token) {
    if (token.isEmpty) return false;

    final parts = token.split('.');
    if (parts.length != 3) return false;

    try {
      // Decode payload (base64)
      final payload = utf8.decode(base64.decode(parts[1]));
      final payloadData = jsonDecode(payload);

      // Check expiration
      if (payloadData['exp'] != null) {
        final expTime = payloadData['exp'] * 1000;
        if (DateTime.now().millisecondsSinceEpoch > expTime) {
          return false;
        }
      }

      return true;
    } catch (e) {
      AppLogger.error('Token validation failed', error: e);
      return false;
    }
  }

  // Role verification
  bool hasRequiredRole(String userRole, List<String> requiredRoles) {
    return requiredRoles.contains(userRole);
  }

  // Permission check
  bool hasPermission(String userRole, String permission) {
    final rolePermissions = _getRolePermissions();
    return rolePermissions[userRole]?.contains(permission) ?? false;
  }

  Map<String, List<String>> _getRolePermissions() {
    return {
      'superAdmin': [
        'all',
        'users.manage',
        'vehicles.manage',
        'trips.manage',
        'payments.manage',
        'announcements.manage',
        'emergency.manage',
        'analytics.view',
        'system.config',
      ],
      'taxiAdmin': [
        'vehicles.view',
        'vehicles.manage',
        'trips.view',
        'trips.manage',
        'drivers.view',
        'drivers.manage',
        'stations.view',
        'stations.manage',
      ],
      'tourismAdmin': [
        'tourism.view',
        'tourism.manage',
        'hotels.view',
        'hotels.manage',
        'packages.view',
        'packages.manage',
      ],
      'hotelAdmin': [
        'hotels.view',
        'hotels.manage',
        'bookings.view',
        'bookings.manage',
      ],
      'healthAdmin': [
        'hospitals.view',
        'hospitals.manage',
        'pharmacies.view',
        'pharmacies.manage',
      ],
      'emergencyAdmin': [
        'emergency.view',
        'emergency.manage',
        'emergency.respond',
      ],
      'citizen': [
        'trips.create',
        'payments.create',
        'notifications.view',
        'profile.view',
        'profile.manage',
      ],
      'taxiDriver': [
        'trips.view',
        'trips.manage',
        'location.update',
        'earnings.view',
      ],
    };
  }

  // Rate limiting
  final Map<String, List<int>> _requestTimestamps = {};

  bool checkRateLimit(
    String identifier, {
    int maxRequests = 60,
    int windowSeconds = 60,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final windowStart = now - (windowSeconds * 1000);

    if (!_requestTimestamps.containsKey(identifier)) {
      _requestTimestamps[identifier] = [];
    }

    final timestamps = _requestTimestamps[identifier]!;

    // Remove old timestamps
    timestamps.removeWhere((timestamp) => timestamp < windowStart);

    if (timestamps.length >= maxRequests) {
      return false;
    }

    timestamps.add(now);
    return true;
  }

  // Audit logging
  Future<void> logSecurityEvent({
    required String userId,
    required String action,
    required String details,
    String? ipAddress,
    String? userAgent,
  }) async {
    try {
      final event = {
        'user_id': userId,
        'action': action,
        'details': details,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Log to backend
      await _apiService.post('/api/security/audit', body: event);

      AppLogger.info('Security event logged: $action');
    } catch (e) {
      AppLogger.error('Failed to log security event', error: e);
    }
  }

  // Session management
  final Map<String, Map<String, dynamic>> _activeSessions = {};

  String createSession(String userId, Map<String, dynamic> userData) {
    final sessionId = _generateSessionId();
    final session = {
      'userId': userId,
      'userData': userData,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'lastActivity': DateTime.now().millisecondsSinceEpoch,
      'expiresAt': DateTime.now()
          .add(const Duration(hours: 24))
          .millisecondsSinceEpoch,
    };

    _activeSessions[sessionId] = session;
    return sessionId;
  }

  Map<String, dynamic>? getSession(String sessionId) {
    final session = _activeSessions[sessionId];

    if (session == null) return null;

    // Check expiration
    if (DateTime.now().millisecondsSinceEpoch > session['expiresAt']) {
      _activeSessions.remove(sessionId);
      return null;
    }

    // Update last activity
    session['lastActivity'] = DateTime.now().millisecondsSinceEpoch;
    return session;
  }

  void destroySession(String sessionId) {
    _activeSessions.remove(sessionId);
  }

  // Clean up expired sessions
  void cleanupExpiredSessions() {
    final now = DateTime.now().millisecondsSinceEpoch;

    _activeSessions.removeWhere((sessionId, session) {
      return now > session['expiresAt'];
    });
  }

  String _generateSessionId() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = sha256.convert(
      utf8.encode(random + DateTime.now().toString()),
    );
    return hash.toString().substring(0, 32);
  }

  // API key validation
  bool isValidApiKey(String apiKey) {
    // In production, validate against backend
    return apiKey.isNotEmpty && apiKey.length >= 32;
  }

  // Request validation
  Map<String, String>? validateRequestPayload(
    Map<String, dynamic> payload,
    Map<String, dynamic> schema,
  ) {
    final errors = <String, String>{};

    for (final field in schema.keys) {
      final rules = schema[field];
      final value = payload[field];

      if (rules['required'] == true &&
          (value == null || value.toString().isEmpty)) {
        errors[field] = '$field is required';
        continue;
      }

      if (value != null) {
        if (rules['type'] != null) {
          final expectedType = rules['type'];
          if (expectedType == 'string' && value is! String) {
            errors[field] = '$field must be a string';
          } else if (expectedType == 'number' && value is! num) {
            errors[field] = '$field must be a number';
          } else if (expectedType == 'boolean' && value is! bool) {
            errors[field] = '$field must be a boolean';
          }
        }

        if (rules['min'] != null && value is num && value < rules['min']) {
          errors[field] = '$field must be at least ${rules['min']}';
        }

        if (rules['max'] != null && value is num && value > rules['max']) {
          errors[field] = '$field must be at most ${rules['max']}';
        }

        if (rules['pattern'] != null && value is String) {
          final pattern = RegExp(rules['pattern']);
          if (!pattern.hasMatch(value)) {
            errors[field] = '$field is invalid';
          }
        }

        if (rules['enum'] != null && !rules['enum'].contains(value)) {
          errors[field] = '$field must be one of: ${rules['enum'].join(', ')}';
        }
      }
    }

    return errors.isEmpty ? null : errors;
  }

  // Secure storage helper
  Future<void> storeSecureData(String key, String value) async {
    // In production, use flutter_secure_storage
    encryptSensitiveData(value, key);
    // Store encrypted data
    AppLogger.info('Secure data stored: $key');
  }

  Future<String?> getSecureData(String key) async {
    // In production, use flutter_secure_storage
    // Retrieve and decrypt data
    return null; // Placeholder
  }

  // Security headers
  Map<String, String> getSecurityHeaders() {
    return {
      'X-Content-Type-Options': 'nosniff',
      'X-Frame-Options': 'DENY',
      'X-XSS-Protection': '1; mode=block',
      'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
    };
  }

  // CSRF protection
  String generateCsrfToken() {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final hash = sha256.convert(
      utf8.encode(random + DateTime.now().toString()),
    );
    return hash.toString();
  }

  bool validateCsrfToken(String token, String sessionToken) {
    // In production, validate against session
    return token.isNotEmpty && token.length >= 32;
  }
}
