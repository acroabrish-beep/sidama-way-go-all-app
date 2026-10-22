import 'package:supabase_flutter/supabase_flutter.dart';
import '../../config/app_config.dart';

class SupabaseClient {
  static SupabaseClient? _instance;
  static late Supabase _supabase;

  static Future<void> initialize() async {
    if (_instance != null) return;

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
      debug: AppConfig.isDevelopment,
    );

    _supabase = Supabase.instance;
    _instance = SupabaseClient._();
  }

  SupabaseClient._();

  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception('SupabaseClient not initialized. Call initialize() first.');
    }
    return _instance!;
  }

  static Supabase get supabase => _supabase;

  // Database client
  static SupabaseQueryBuilder from(String table) => _supabase.client.from(table);

  // Realtime client
  static RealtimeChannel channel(String name) => _supabase.client.channel(name);

  // Auth client (for Supabase auth if needed)
  static GoTrueClient get auth => _supabase.client.auth;

  // Storage client
  static SupabaseStorageClient get storage => _supabase.client.storage;
}