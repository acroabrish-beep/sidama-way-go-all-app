import 'package:flutter/foundation.dart';

class AppConfig {
  // Environment Mode
  static const bool isProduction = kReleaseMode;
  static const bool isDevelopment = !isProduction;

  // API Configuration
  static String get apiBaseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    
    // In production, require explicit API URL
    if (isProduction) {
      throw Exception('API_BASE_URL must be set in production builds via --dart-define');
    }
    
    // Development fallback
    return 'http://localhost:3000';
  }

  // Supabase Configuration
  static String get supabaseUrl {
    const url = String.fromEnvironment('SUPABASE_URL');
    if (url.isNotEmpty) return url;
    
    if (isProduction) {
      throw Exception('SUPABASE_URL must be set in production builds via --dart-define');
    }
    
    // Safe fallback for local development UI testing
    return 'https://placeholder.supabase.co';
  }

  static String get supabaseAnonKey {
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (key.isNotEmpty) return key;
    
    if (isProduction) {
      throw Exception('SUPABASE_ANON_KEY must be set in production builds via --dart-define');
    }
    
    // Safe fallback for local development UI testing
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.dummy';
  }

  // Firebase Configuration
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  // Google Maps Configuration
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );

  // AI Configuration
  static const String aiEndpoint = String.fromEnvironment(
    'AI_ENDPOINT',
    defaultValue: '/api/gemini',
  );

  // Payment Provider Configuration
  static const String telebirrApiKey = String.fromEnvironment(
    'TELEBIRR_API_KEY',
    defaultValue: '',
  );

  static const String chapaPublicKey = String.fromEnvironment(
    'CHAPA_PUBLIC_KEY',
    defaultValue: '',
  );

  static const String santimPayApiKey = String.fromEnvironment(
    'SANTIMPAY_API_KEY',
    defaultValue: '',
  );

  // Validation
  static bool get isValidConfig {
    try {
      return supabaseUrl.isNotEmpty &&
             supabaseAnonKey.isNotEmpty &&
             firebaseProjectId.isNotEmpty &&
             googleMapsApiKey.isNotEmpty &&
             !supabaseUrl.contains('placeholder');
    } catch (_) {
      return false;
    }
  }

  static void logConfig() {
    if (kDebugMode) {
      print('=== App Configuration ===');
      try {
        print('API Base URL: $apiBaseUrl');
        print('Supabase URL: ${supabaseUrl.isNotEmpty ? (supabaseUrl.contains('placeholder') ? "FALLBACK" : "SET") : "MISSING"}');
        print('Supabase Anon Key: ${supabaseAnonKey.isNotEmpty ? (supabaseAnonKey.contains('dummy') ? "FALLBACK" : "SET") : "MISSING"}');
      } catch (e) {
        print('Config Error: $e');
      }
      print('Firebase Project ID: ${firebaseProjectId.isNotEmpty ? "SET" : "MISSING"}');
      print('Google Maps Key: ${googleMapsApiKey.isNotEmpty ? "SET" : "MISSING"}');
      print('AI Endpoint: $aiEndpoint');
      print('Environment: ${isProduction ? "PRODUCTION" : "DEVELOPMENT"}');
      print('=========================');
    }
  }

  static String getFullApiEndpoint(String path) {
    return '$apiBaseUrl$path';
  }
}
